import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/models/conversation.dart';
import '../core/models/message.dart';
import 'cmmd_config.dart';
import 'storage_provider.dart';

/// CMMD API implementation of [StorageProvider].
///
/// Conversations are listed and retrieved from the CMMD server.
/// Messages are auto-saved server-side during the chat streaming flow,
/// so [saveMessage] and [saveConversation] are no-ops.
///
/// Search is performed client-side — the CMMD API does not expose
/// a search endpoint.
///
/// ```dart
/// final storage = CmmdStorageProvider(
///   config: CmmdConfig(),
///   accessTokenProvider: () => authProvider.accessToken!,
///   organizationIdProvider: () => authProvider.organizationId,
/// );
/// ```
class CmmdStorageProvider implements StorageProvider {
  /// Creates a [CmmdStorageProvider].
  CmmdStorageProvider({
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

  // Cache of conversations for client-side search.
  List<Conversation>? _cachedConversations;

  // ---------------------------------------------------------------------------
  // Conversations
  // ---------------------------------------------------------------------------

  @override
  Future<List<Conversation>> loadConversations() async {
    final response = await _get('/api/ai/conversations');
    final json = jsonDecode(response.body);

    // API returns a plain array.
    final list = json is List
        ? json
        : (json as Map<String, dynamic>)['data'] as List? ??
            (json)['conversations'] as List? ??
            [];

    final conversations = list
        .map((e) => _parseConversation(e as Map<String, dynamic>))
        .toList();

    _cachedConversations = conversations;
    return conversations;
  }

  @override
  Future<Conversation> saveConversation(Conversation conversation) async {
    // Conversations are created server-side when the first message is sent
    // via the chat endpoint. This is a no-op.
    return conversation;
  }

  @override
  Future<void> deleteConversation(String id) async {
    await _delete('/api/ai/conversations/$id');
    _cachedConversations?.removeWhere((c) => c.id == id);
  }

  // ---------------------------------------------------------------------------
  // Starring (pinning) — not exposed in API contract; local-only stubs
  // ---------------------------------------------------------------------------

  final Set<String> _localStarred = {};

  @override
  Future<void> starConversation(String id) async {
    _localStarred.add(id);
  }

  @override
  Future<void> unstarConversation(String id) async {
    _localStarred.remove(id);
  }

  @override
  Future<List<Conversation>> loadStarredConversations() async {
    if (_localStarred.isEmpty) return [];
    final all = _cachedConversations ?? await loadConversations();
    return all.where((c) => _localStarred.contains(c.id)).toList();
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
  }

  // ---------------------------------------------------------------------------
  // Search (client-side)
  // ---------------------------------------------------------------------------

  @override
  Future<List<Conversation>> searchConversations(String query) async {
    final all = _cachedConversations ?? await loadConversations();
    final lower = query.toLowerCase();
    return all
        .where((c) => c.title?.toLowerCase().contains(lower) ?? false)
        .toList();
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

  Map<String, String> get _headers {
    final orgId = organizationIdProvider?.call() ?? config.organizationId;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${accessTokenProvider()}',
      'X-Auth-Type': 'jwt',
      if (orgId != null) 'X-Organization-ID': orgId,
    };
  }

  Future<http.Response> _get(String path) async {
    final response = await http.get(
      Uri.parse('${config.baseUrl}$path'),
      headers: _headers,
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
  // Parsing
  // ---------------------------------------------------------------------------

  Conversation _parseConversation(Map<String, dynamic> json) {
    return Conversation(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] as String?,
      createdAt: _parseDateTime(json['createdAt'] ?? json['updatedAt']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['createdAt']),
      model: json['model'] as String?,
      metadata: {
        if (json['lastMessage'] != null) 'lastMessage': json['lastMessage'],
        if (json['messageCount'] != null)
          'messageCount': json['messageCount'],
      },
    );
  }

  Message _parseMessage(Map<String, dynamic> json) {
    final roleStr =
        (json['role'] as String? ?? 'assistant').toLowerCase();
    final role = switch (roleStr) {
      'user' || 'human' => MessageRole.user,
      'system' => MessageRole.system,
      'tool' => MessageRole.tool,
      _ => MessageRole.assistant,
    };

    return Message(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      role: role,
      content: json['content'] as String? ?? '',
      timestamp: _parseDateTime(json['createdAt'] ?? json['timestamp']),
      thinkingContent: json['thinking'] as String?,
      status: MessageStatus.complete,
    );
  }

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
