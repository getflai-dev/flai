import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/models/chat_event.dart';
import '../core/models/chat_request.dart';
import '../core/models/message.dart';
import 'ai_provider.dart';
import 'cmmd_client_base.dart';
import 'cmmd_config.dart';

/// CMMD API implementation of [AiProvider].
///
/// Streams chat responses via SSE from the CMMD `/api/ai/chat` endpoint.
///
/// SSE wire format (each event has an `event:`, `id:`, and `data:` field):
/// ```
/// event: delta
/// id: 1
/// data: {"content":"Hello","conversationId":123}
///
/// event: done
/// id: 5
/// data: {"id":456,"conversationId":123,"chatId":123,...}
/// ```
///
/// Event types: `status`, `thinking_delta`, `delta`, `tool_call`,
/// `tool_result`, `tool_calls`, `citations`, `web_search_results`,
/// `done`, `error`.
class CmmdAiProvider implements AiProvider {
  CmmdAiProvider({
    required this.config,
    required this.accessTokenProvider,
    this.organizationIdProvider,
    this.csrfHeadersProvider,
  });

  final CmmdConfig config;
  final String Function() accessTokenProvider;
  final String? Function()? organizationIdProvider;
  final Map<String, String> Function()? csrfHeadersProvider;

  http.Client? _activeClient;

  /// The conversation/chat ID returned by the server.
  /// Available from the very first SSE event (every event carries it).
  String? lastChatId;

  // ── AiProvider capabilities ─────────────────────────────────────────

  @override
  bool get supportsToolUse => true;
  @override
  bool get supportsVision => true;
  @override
  bool get supportsStreaming => true;
  @override
  bool get supportsThinking => true;

  // ── streamChat ──────────────────────────────────────────────────────

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

      final response = await client
          .send(httpRequest)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        yield ChatError(
          CmmdApiException(
            statusCode: response.statusCode,
            message:
                CmmdClientBase.extractErrorMessage(errorBody) ??
                'Request failed (${response.statusCode})',
          ),
        );
        return;
      }

      // Check if the response is SSE or plain JSON.
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('text/event-stream')) {
        final jsonBody = await response.stream.bytesToString();
        yield* _parseNonStreamingResponse(jsonBody);
        return;
      }

      // Parse CMMD SSE stream.
      // Format: event: <name>\nid: <int>\ndata: <json>\n\n
      // Plus :heartbeat\n\n comments every 15s.
      final fullTextBuffer = StringBuffer();

      await for (final sseEvent in _parseSseStream(response.stream)) {
        final event = sseEvent.event;
        final data = sseEvent.data;

        // Every event carries conversationId — grab from the first one.
        final convId = data['conversationId'];
        if (convId != null && lastChatId == null) {
          lastChatId = convId.toString();
        }

        switch (event) {
          case 'status':
            // Phase transitions: thinking, generating, tool_executing.
            break;

          case 'thinking_delta':
            final content = data['content'] as String? ?? '';
            if (content.isNotEmpty) {
              yield ThinkingDelta(content);
            }

          case 'delta':
            final content = data['content'] as String? ?? '';
            if (content.isNotEmpty) {
              fullTextBuffer.write(content);
              yield TextDelta(content);
            }

          case 'tool_call':
            final id = data['toolUseId'] as String? ?? '';
            final name = data['toolName'] as String? ?? '';
            final args = data['args'];
            final argsStr = args is String ? args : jsonEncode(args ?? {});
            yield ToolCallStart(id: id, name: name);
            if (argsStr.isNotEmpty) {
              yield ToolCallDelta(id: id, argumentsDelta: argsStr);
            }

          case 'tool_result':
            final id = data['toolUseId'] as String? ?? '';
            yield ToolCallEnd(id: id);

          case 'tool_calls':
            // Summary event after all tools — informational.
            break;

          case 'citations':
            final citationsList = data['citations'] as List? ?? [];
            final citations = citationsList.map((c) {
              final map = c as Map<String, dynamic>;
              return Citation(
                title: map['title'] as String? ?? '',
                url: map['url'] as String?,
                snippet: map['cited_text'] as String?,
              );
            }).toList();
            if (citations.isNotEmpty) {
              yield CitationsReceived(citations);
            }

          case 'web_search_results':
            final results = data['results'] as List? ?? [];
            final citations = results.map((r) {
              final map = r as Map<String, dynamic>;
              return Citation(
                title: map['title'] as String? ?? '',
                url: map['url'] as String?,
              );
            }).toList();
            if (citations.isNotEmpty) {
              yield CitationsReceived(citations);
            }

          case 'worker_result':
            // Worker dispatch result — informational.
            break;

          case 'done':
            lastChatId = (data['chatId'] ?? data['conversationId'])?.toString();
            final text = fullTextBuffer.toString();
            if (text.isNotEmpty) {
              yield TextDone(text);
            }
            yield const ChatDone();
            return;

          case 'error':
            final errorMsg =
                data['message'] as String? ??
                data['error'] as String? ??
                'Unknown CMMD error';
            yield ChatError(CmmdApiException(message: errorMsg));
            return;
        }
      }

      // Stream ended without a done event.
      final text = fullTextBuffer.toString();
      if (text.isNotEmpty) {
        yield TextDone(text);
      }
      yield const ChatDone();
    } catch (e, st) {
      yield ChatError(e, st);
    } finally {
      _activeClient = null;
      client.close();
    }
  }

  // ── chat (non-streaming) ───────────────────────────────────────────

  @override
  Future<ChatResponse> chat(ChatRequest request) async {
    try {
      final body = _buildRequestBody(request);
      body['stream'] = false;

      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/ai/chat'),
        headers: {..._headers, 'Accept': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw CmmdApiException(
          statusCode: response.statusCode,
          message:
              CmmdClientBase.extractErrorMessage(response.body) ??
              response.body,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final content =
          json['response'] as String? ?? json['content'] as String? ?? '';

      return ChatResponse(
        message: Message(
          id:
              (json['messageId'] ?? json['chatId'])?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.assistant,
          content: content,
          timestamp: DateTime.now(),
          status: MessageStatus.complete,
        ),
      );
    } catch (e) {
      if (e is CmmdApiException) rethrow;
      throw CmmdApiException(message: CmmdClientBase.friendlyError(e));
    }
  }

  // ── cancel ─────────────────────────────────────────────────────────

  @override
  Future<void> cancel() async {
    _activeClient?.close();
    _activeClient = null;
  }

  // ── Private helpers ────────────────────────────────────────────────

  Map<String, dynamic> _buildRequestBody(ChatRequest request) {
    final lastUserMessage = request.messages.lastWhere(
      (m) => m.role == MessageRole.user,
      orElse: () => request.messages.last,
    );

    final body = <String, dynamic>{
      'message': lastUserMessage.content,
      'stream': true,
      if (request.model != null) 'model': request.model,
      'ghostMode': request.metadata?['ghostMode'] ?? false,
      if (request.metadata?['knowledgeScope'] != null)
        'knowledgeScope': request.metadata!['knowledgeScope'],
      if (request.metadata?['mode'] != null) 'mode': request.metadata!['mode'],
    };

    // CMMD accepts both chatId and conversationId.
    final chatId =
        request.metadata?['chatId'] ?? request.metadata?['conversationId'];
    if (chatId != null) {
      body['conversationId'] = chatId;
    }

    return body;
  }

  Map<String, String> get _headers {
    final orgId = organizationIdProvider?.call() ?? config.organizationId;
    return {
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      'User-Agent': 'FlAI/1.0 (cmmd_providers)',
      'Authorization': 'Bearer ${accessTokenProvider()}',
      'X-Auth-Type': 'jwt',
      'X-Organization-ID': ?orgId,
      ...?csrfHeadersProvider?.call(),
    };
  }

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

  /// Parses CMMD SSE format: `event: <name>\nid: <int>\ndata: <json>\n\n`
  ///
  /// Also handles `:heartbeat\n\n` comments (ignored).
  /// Timeout: 60s per chunk to detect server hangs.
  Stream<_SseEvent> _parseSseStream(Stream<List<int>> byteStream) async* {
    final buffer = StringBuffer();

    final chunks = byteStream
        .transform(utf8.decoder)
        .timeout(const Duration(seconds: 60));

    await for (final chunk in chunks) {
      buffer.write(chunk);
      final raw = buffer.toString();

      // SSE events are separated by double newlines.
      final blocks = raw.split('\n\n');

      // The last block may be incomplete — keep it in the buffer.
      buffer.clear();
      buffer.write(blocks.removeLast());

      for (final block in blocks) {
        if (block.trim().isEmpty) continue;

        String eventType = 'message';
        String dataStr = '';

        for (final line in block.split('\n')) {
          if (line.startsWith('event: ')) {
            eventType = line.substring(7).trim();
          } else if (line.startsWith('data: ')) {
            dataStr = line.substring(6);
          }
          // id: lines and :heartbeat comments are ignored.
        }

        if (dataStr.isEmpty) continue;

        try {
          final json = jsonDecode(dataStr) as Map<String, dynamic>;
          yield _SseEvent(event: eventType, data: json);
        } on FormatException {
          // Skip malformed JSON.
        }
      }
    }
  }
}

class _SseEvent {
  final String event;
  final Map<String, dynamic> data;
  const _SseEvent({required this.event, required this.data});
}
