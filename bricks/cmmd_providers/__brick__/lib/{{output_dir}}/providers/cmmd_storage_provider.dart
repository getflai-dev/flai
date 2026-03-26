import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/models/conversation.dart';
import '../core/models/message.dart';
import 'cmmd_config.dart';
import 'storage_provider.dart';

/// CMMD API implementation of [StorageProvider].
///
/// Persists conversations and messages on the CMMD server.
/// Messages are saved server-side during chat streaming, so
/// [saveMessage] is a no-op.
///
/// ```dart
/// final storage = CmmdStorageProvider(
///   config: CmmdConfig(),
///   accessTokenProvider: () => authProvider.accessToken!,
/// );
///
/// final conversations = await storage.loadConversations();
/// ```
class CmmdStorageProvider implements StorageProvider {
  /// Creates a [CmmdStorageProvider].
  ///
  /// [config] specifies the CMMD API base URL and organization.
  /// [accessTokenProvider] returns the current JWT access token.
  CmmdStorageProvider({
    required this.config,
    required this.accessTokenProvider,
  });

  /// The CMMD API configuration.
  final CmmdConfig config;

  /// Returns the current JWT access token for authenticated requests.
  final String Function() accessTokenProvider;

  // ---------------------------------------------------------------------------
  // Conversations
  // ---------------------------------------------------------------------------

  @override
  Future<List<Conversation>> loadConversations() async {
    final response = await _get('/api/ai/conversations');
    final json = jsonDecode(response.body);
    final list = json is List ? json : (json as Map<String, dynamic>)['conversations'] as List? ?? [];
    return list.map((e) => _parseConversation(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Conversation> saveConversation(Conversation conversation) async {
    final response = await _post(
      '/api/ai/conversations',
      body: {'title': conversation.title ?? conversation.displayTitle},
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseConversation(json);
  }

  @override
  Future<void> deleteConversation(String id) async {
    await _delete('/api/ai/conversations/$id');
  }

  // ---------------------------------------------------------------------------
  // Starring (pinning)
  // ---------------------------------------------------------------------------

  @override
  Future<void> starConversation(String id) async {
    await _patch(
      '/api/ai/conversations/$id/pin',
      body: {'pinned': true},
    );
  }

  @override
  Future<void> unstarConversation(String id) async {
    await _patch(
      '/api/ai/conversations/$id/pin',
      body: {'pinned': false},
    );
  }

  @override
  Future<List<Conversation>> loadStarredConversations() async {
    final response = await _get('/api/ai/conversations?pinned=true');
    final json = jsonDecode(response.body);
    final list = json is List ? json : (json as Map<String, dynamic>)['conversations'] as List? ?? [];
    return list.map((e) => _parseConversation(e as Map<String, dynamic>)).toList();
  }

  // ---------------------------------------------------------------------------
  // Messages
  // ---------------------------------------------------------------------------

  @override
  Future<List<Message>> loadMessages(String conversationId) async {
    final response = await _get('/api/ai/conversations/$conversationId');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final messages = json['messages'] as List<dynamic>? ?? [];
    return messages
        .map((e) => _parseMessage(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveMessage(String conversationId, Message message) async {
    // Messages are persisted server-side during the chat streaming flow.
    // This is intentionally a no-op for the CMMD backend.
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  @override
  Future<List<Conversation>> searchConversations(String query) async {
    final encoded = Uri.encodeQueryComponent(query);
    final response = await _get('/api/ai/conversations?search=$encoded');
    final json = jsonDecode(response.body);
    final list = json is List ? json : (json as Map<String, dynamic>)['conversations'] as List? ?? [];
    return list.map((e) => _parseConversation(e as Map<String, dynamic>)).toList();
  }

  // ---------------------------------------------------------------------------
  // Metadata
  // ---------------------------------------------------------------------------

  @override
  Future<void> renameConversation(String id, String newTitle) async {
    await _patch(
      '/api/ai/conversations/$id',
      body: {'title': newTitle},
    );
  }

  // ---------------------------------------------------------------------------
  // HTTP helpers
  // ---------------------------------------------------------------------------

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${accessTokenProvider()}',
        if (config.organizationId != null)
          'X-Organization-ID': config.organizationId!,
      };

  Future<http.Response> _get(String path) async {
    final response = await http.get(
      Uri.parse('${config.baseUrl}$path'),
      headers: _headers,
    );
    _checkResponse(response);
    return response;
  }

  Future<http.Response> _post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await http.post(
      Uri.parse('${config.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _checkResponse(response);
    return response;
  }

  Future<http.Response> _patch(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await http.patch(
      Uri.parse('${config.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _checkResponse(response);
    return response;
  }

  Future<http.Response> _delete(String path) async {
    final response = await http.delete(
      Uri.parse('${config.baseUrl}$path'),
      headers: _headers,
    );
    _checkResponse(response);
    return response;
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'CMMD API error ${response.statusCode}: ${response.body}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Parsing helpers
  // ---------------------------------------------------------------------------

  /// Parse a CMMD conversation JSON into a [Conversation].
  Conversation _parseConversation(Map<String, dynamic> json) {
    return Conversation(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] as String? ?? json['name'] as String?,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(
        json['updatedAt'] ?? json['updated_at'] ?? json['createdAt'] ?? json['created_at'],
      ),
      model: json['model'] as String?,
      metadata: {
        if (json['pinned'] == true) 'pinned': true,
      },
    );
  }

  /// Parse a CMMD message JSON into a [Message].
  Message _parseMessage(Map<String, dynamic> json) {
    final roleStr = (json['role'] as String? ?? json['sender'] as String? ?? 'assistant')
        .toLowerCase();
    final role = switch (roleStr) {
      'user' || 'human' => MessageRole.user,
      'system' => MessageRole.system,
      'tool' => MessageRole.tool,
      _ => MessageRole.assistant,
    };

    return Message(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      role: role,
      content: json['content'] as String? ?? json['text'] as String? ?? '',
      timestamp: _parseDateTime(json['createdAt'] ?? json['created_at'] ?? json['timestamp']),
      thinkingContent: json['thinking'] as String?,
      status: MessageStatus.complete,
    );
  }

  /// Parse a date value that may be a string, int, or null.
  DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}
