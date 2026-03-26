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
/// Supports text streaming, thinking indicators, and tool use.
///
/// ```dart
/// final ai = CmmdAiProvider(
///   config: CmmdConfig(),
///   accessTokenProvider: () => authProvider.accessToken!,
/// );
///
/// await for (final event in ai.streamChat(request)) {
///   switch (event) {
///     case TextDelta(:final text): print(text);
///     case ChatDone(): print('Done!');
///     // ...
///   }
/// }
/// ```
class CmmdAiProvider implements AiProvider {
  /// Creates a [CmmdAiProvider].
  ///
  /// [config] specifies the CMMD API base URL and organization.
  /// [accessTokenProvider] returns the current JWT access token.
  CmmdAiProvider({
    required this.config,
    required this.accessTokenProvider,
  });

  /// The CMMD API configuration.
  final CmmdConfig config;

  /// Returns the current JWT access token for authenticated requests.
  final String Function() accessTokenProvider;

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
  bool get supportsThinking => true;

  // ---------------------------------------------------------------------------
  // streamChat
  // ---------------------------------------------------------------------------

  @override
  Stream<ChatEvent> streamChat(ChatRequest request) async* {
    final client = http.Client();
    _activeClient = client;

    try {
      final lastUserMessage = request.messages.lastWhere(
        (m) => m.role == MessageRole.user,
        orElse: () => request.messages.last,
      );

      final body = <String, dynamic>{
        'message': lastUserMessage.content,
        'model': request.model,
        'ghostMode': false,
      };

      // Include conversationId from metadata if available.
      final conversationId = request.metadata?['conversationId'];
      if (conversationId != null) {
        body['conversationId'] = conversationId;
      }

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
            message: errorBody,
          ),
        );
        return;
      }

      final fullTextBuffer = StringBuffer();
      var inThinking = false;

      await for (final data in _parseSseStream(response.stream)) {
        final type = data['type'] as String?;
        if (type == null) continue;

        switch (type) {
          case 'text_delta':
            final token =
                data['token'] as String? ?? data['content'] as String? ?? '';
            if (token.isNotEmpty) {
              fullTextBuffer.write(token);
              yield TextDelta(token);
            }

          case 'thinking':
            final content = data['content'] as String? ?? '';
            if (!inThinking) {
              yield const ThinkingStart();
              inThinking = true;
            }
            if (content.isNotEmpty) {
              yield ThinkingDelta(content);
            }

          case 'thinking_end':
            if (inThinking) {
              yield const ThinkingEnd();
              inThinking = false;
            }

          case 'tool_call_start':
            final id = data['id'] as String? ?? '';
            final name = data['name'] as String? ?? '';
            yield ToolCallStart(id: id, name: name);

          case 'tool_call_delta':
            final id = data['id'] as String? ?? '';
            final argsDelta = data['arguments'] as String? ?? '';
            yield ToolCallDelta(id: id, argumentsDelta: argsDelta);

          case 'tool_call_end':
            final id = data['id'] as String? ?? '';
            yield ToolCallEnd(id: id);

          case 'done':
            if (inThinking) {
              yield const ThinkingEnd();
              inThinking = false;
            }
            final text = fullTextBuffer.toString();
            if (text.isNotEmpty) {
              yield TextDone(text);
            }
            yield const ChatDone();

          case 'error':
            final errorMsg = data['error'] as String? ?? 'Unknown CMMD error';
            yield ChatError(CmmdApiException(message: errorMsg));
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
    // Collect the full stream into a single response.
    final events = <ChatEvent>[];
    await for (final event in streamChat(request)) {
      events.add(event);
    }

    final textParts = <String>[];
    String? thinkingContent;
    final toolCalls = <ToolCall>[];

    for (final event in events) {
      switch (event) {
        case TextDelta(:final text):
          textParts.add(text);
        case ThinkingDelta(:final text):
          thinkingContent = (thinkingContent ?? '') + text;
        case ToolCallStart(:final id, :final name):
          toolCalls.add(ToolCall(id: id, name: name, arguments: ''));
        case ToolCallDelta(:final id, :final argumentsDelta):
          final index = toolCalls.indexWhere((tc) => tc.id == id);
          if (index >= 0) {
            toolCalls[index] = toolCalls[index].copyWith(
              arguments: toolCalls[index].arguments + argumentsDelta,
            );
          }
        case ToolCallEnd(:final id):
          final index = toolCalls.indexWhere((tc) => tc.id == id);
          if (index >= 0) {
            toolCalls[index] = toolCalls[index].copyWith(isComplete: true);
          }
        case ChatError(:final error):
          throw error;
        default:
          break;
      }
    }

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: textParts.join(),
      timestamp: DateTime.now(),
      toolCalls: toolCalls.isNotEmpty ? toolCalls : null,
      thinkingContent: thinkingContent,
      status: MessageStatus.complete,
    );

    return ChatResponse(message: message);
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

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'Authorization': 'Bearer ${accessTokenProvider()}',
        if (config.organizationId != null)
          'X-Organization-ID': config.organizationId!,
      };

  /// Parses an SSE byte stream into decoded JSON objects.
  ///
  /// Each `data: ` line is extracted, blank lines and comment lines
  /// are skipped. Malformed JSON chunks are silently ignored.
  Stream<Map<String, dynamic>> _parseSseStream(
    Stream<List<int>> byteStream,
  ) async* {
    final lineBuffer = StringBuffer();

    await for (final bytes in byteStream) {
      lineBuffer.write(utf8.decode(bytes));
      final raw = lineBuffer.toString();
      final lines = raw.split('\n');

      // Keep the last (potentially incomplete) line in the buffer.
      lineBuffer.clear();
      lineBuffer.write(lines.removeLast());

      for (final line in lines) {
        final trimmed = line.trim();

        if (trimmed.isEmpty || trimmed.startsWith(':')) {
          continue;
        }

        if (trimmed == 'data: [DONE]') {
          return;
        }

        if (trimmed.startsWith('data: ')) {
          final jsonStr = trimmed.substring(6);
          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            yield json;
          } on FormatException {
            // Skip malformed JSON chunks.
          }
        }
      }
    }
  }
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
