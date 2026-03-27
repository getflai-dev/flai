import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/models/chat_event.dart';
import '../core/models/chat_request.dart';
import '../core/models/message.dart';
import 'ai_provider.dart';
import 'cmmd_config.dart';

/// CMMD API implementation of [AiProvider].
///
/// Streams chat responses via SSE from the CMMD `/api/ai/chat` endpoint.
/// Uses CMMD's custom event format (`event: message`, `event: done`,
/// `event: error`) — not OpenAI-compatible.
///
/// Also supports non-streaming mode which returns a complete response
/// in a single JSON payload.
///
/// ```dart
/// final ai = CmmdAiProvider(
///   config: CmmdConfig(),
///   accessTokenProvider: () => authProvider.accessToken!,
///   organizationIdProvider: () => authProvider.organizationId,
/// );
/// ```
class CmmdAiProvider implements AiProvider {
  /// Creates a [CmmdAiProvider].
  CmmdAiProvider({
    required this.config,
    required this.accessTokenProvider,
    this.organizationIdProvider,
  });

  /// The CMMD API configuration.
  final CmmdConfig config;

  /// Returns the current JWT access token for authenticated requests.
  final String Function() accessTokenProvider;

  /// Returns the current organization ID, if available.
  final String? Function()? organizationIdProvider;

  http.Client? _activeClient;

  // ---------------------------------------------------------------------------
  // AiProvider capabilities
  // ---------------------------------------------------------------------------

  @override
  bool get supportsToolUse => true;

  @override
  bool get supportsVision => true;

  @override
  bool get supportsStreaming => true;

  @override
  bool get supportsThinking => false;

  // ---------------------------------------------------------------------------
  // streamChat
  // ---------------------------------------------------------------------------

  @override
  Stream<ChatEvent> streamChat(ChatRequest request) async* {
    final client = http.Client();
    _activeClient = client;

    try {
      final body = _buildRequestBody(request);

      final httpRequest = http.Request(
        'POST',
        Uri.parse('${config.baseUrl}/api/ai/chat'),
      );
      httpRequest.headers.addAll(_headers);
      httpRequest.body = jsonEncode(body);

      final response = await client.send(httpRequest);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        yield ChatError(
          CmmdApiException(
            statusCode: response.statusCode,
            message: _extractErrorMessage(errorBody) ?? errorBody,
          ),
        );
        return;
      }

      // Check if the response is SSE or plain JSON.
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('text/event-stream')) {
        // Non-streaming response — parse as JSON.
        final jsonBody = await response.stream.bytesToString();
        yield* _parseNonStreamingResponse(jsonBody);
        return;
      }

      // Parse SSE stream with CMMD's custom event format.
      final fullTextBuffer = StringBuffer();

      await for (final event in _parseSseStream(response.stream)) {
        final eventType = event.eventType;
        final data = event.data;

        switch (eventType) {
          case 'message':
            final type = data['type'] as String?;
            switch (type) {
              case 'text':
                final content = data['content'] as String? ?? '';
                if (content.isNotEmpty) {
                  fullTextBuffer.write(content);
                  yield TextDelta(content);
                }

              case 'tool_call':
                final name = data['name'] as String? ?? '';
                final args = data['arguments'];
                final argsStr =
                    args is String ? args : jsonEncode(args ?? {});
                final id = data['id'] as String? ?? name;
                yield ToolCallStart(id: id, name: name);
                if (argsStr.isNotEmpty) {
                  yield ToolCallDelta(id: id, argumentsDelta: argsStr);
                }
                yield ToolCallEnd(id: id);

              case 'tool_result':
                // Tool results are informational — not emitted as ChatEvents.
                // The AI text response follows separately.
                break;

              case 'action':
                // Actions (create_task, etc.) — store in metadata.
                // Not directly mapped to ChatEvent yet.
                break;

              case 'sources':
                // Sources are available via the done event metadata.
                break;

              case 'confidence':
                // Confidence score — informational.
                break;
            }

          case 'done':
            // conversationId and messageId available in data if needed.
            final text = fullTextBuffer.toString();
            if (text.isNotEmpty) {
              yield TextDone(text);
            }
            yield const ChatDone();

          case 'error':
            final errorMsg =
                data['error'] as String? ?? 'Unknown CMMD error';
            final code = data['code'] as int?;
            yield ChatError(
              CmmdApiException(statusCode: code, message: errorMsg),
            );
        }
      }
    } catch (e, st) {
      yield ChatError(e, st);
    } finally {
      _activeClient = null;
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // chat (non-streaming)
  // ---------------------------------------------------------------------------

  @override
  Future<ChatResponse> chat(ChatRequest request) async {
    try {
      final body = _buildRequestBody(request);

      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/ai/chat'),
        headers: {
          ..._headers,
          // Request JSON instead of SSE for non-streaming.
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw CmmdApiException(
          statusCode: response.statusCode,
          message: _extractErrorMessage(response.body) ?? response.body,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final content =
          json['response'] as String? ?? json['content'] as String? ?? '';

      final message = Message(
        id: (json['messageId'] as String?) ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: content,
        timestamp: DateTime.now(),
        status: MessageStatus.complete,
      );

      return ChatResponse(message: message);
    } catch (e) {
      if (e is CmmdApiException) rethrow;
      throw CmmdApiException(message: _friendlyError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // cancel
  // ---------------------------------------------------------------------------

  @override
  Future<void> cancel() async {
    _activeClient?.close();
    _activeClient = null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _buildRequestBody(ChatRequest request) {
    final lastUserMessage = request.messages.lastWhere(
      (m) => m.role == MessageRole.user,
      orElse: () => request.messages.last,
    );

    final body = <String, dynamic>{
      'message': lastUserMessage.content,
      if (request.model != null) 'model': request.model,
      'ghostMode': request.metadata?['ghostMode'] ?? false,
      if (request.metadata?['scope'] != null) 'scope': request.metadata!['scope'],
    };

    final conversationId = request.metadata?['conversationId'];
    if (conversationId != null) {
      body['conversationId'] = conversationId;
    }

    return body;
  }

  Map<String, String> get _headers {
    final orgId = organizationIdProvider?.call() ?? config.organizationId;
    return {
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      'Authorization': 'Bearer ${accessTokenProvider()}',
      'X-Auth-Type': 'jwt',
      if (orgId != null) 'X-Organization-ID': orgId,
    };
  }

  /// Parse non-streaming JSON response into ChatEvents.
  Stream<ChatEvent> _parseNonStreamingResponse(String body) async* {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final content =
          json['response'] as String? ?? json['content'] as String? ?? '';

      if (content.isNotEmpty) {
        yield TextDelta(content);
        yield TextDone(content);
      }

      yield const ChatDone();
    } catch (e, st) {
      yield ChatError(e, st);
    }
  }

  /// Parses CMMD's custom SSE format.
  ///
  /// CMMD uses named events: `event: message`, `event: done`, `event: error`.
  /// Each event has a `data: {...}` line with JSON payload.
  Stream<_SseEvent> _parseSseStream(
    Stream<List<int>> byteStream,
  ) async* {
    final lineBuffer = StringBuffer();
    String? currentEventType;

    await for (final bytes in byteStream) {
      lineBuffer.write(utf8.decode(bytes));
      final raw = lineBuffer.toString();
      final lines = raw.split('\n');

      // Keep the last (potentially incomplete) line in the buffer.
      lineBuffer.clear();
      lineBuffer.write(lines.removeLast());

      for (final line in lines) {
        final trimmed = line.trim();

        if (trimmed.isEmpty) {
          // Empty line = end of event block. Reset event type.
          currentEventType = null;
          continue;
        }

        if (trimmed.startsWith(':')) {
          continue; // SSE comment
        }

        if (trimmed.startsWith('event: ')) {
          currentEventType = trimmed.substring(7).trim();
          continue;
        }

        if (trimmed == 'data: [DONE]') {
          return;
        }

        if (trimmed.startsWith('data: ')) {
          final jsonStr = trimmed.substring(6);
          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            yield _SseEvent(
              eventType: currentEventType ?? 'message',
              data: json,
            );
          } on FormatException {
            // Skip malformed JSON chunks.
          }
        }
      }
    }
  }

  String? _extractErrorMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['error'] as String? ?? json['message'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _friendlyError(Object e) {
    final text = e.toString();
    if (text.contains('SocketException') ||
        text.contains('Connection refused')) {
      return 'Could not connect to server. Check your internet connection.';
    }
    if (text.contains('timed out') || text.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

/// Internal SSE event with named event type.
class _SseEvent {
  final String eventType;
  final Map<String, dynamic> data;

  const _SseEvent({required this.eventType, required this.data});
}

/// Exception thrown when the CMMD API returns an error.
class CmmdApiException implements Exception {
  /// The HTTP status code, if available.
  final int? statusCode;

  /// The error message from the API.
  final String message;

  /// Creates a [CmmdApiException].
  const CmmdApiException({this.statusCode, required this.message});

  @override
  String toString() {
    if (statusCode != null) {
      return 'CmmdApiException($statusCode): $message';
    }
    return 'CmmdApiException: $message';
  }
}
