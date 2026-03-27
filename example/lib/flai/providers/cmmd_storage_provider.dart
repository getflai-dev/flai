import 'dart:convert';

import '../core/models/conversation.dart';
import '../core/models/message.dart';
import 'cmmd_client_base.dart';
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
class CmmdStorageProvider with CmmdClientBase implements StorageProvider {
  CmmdStorageProvider({
    required this.config,
    required this.accessTokenProvider,
    this.organizationIdProvider,
    this.csrfHeadersProvider,
  });

  @override
  final CmmdConfig config;

  @override
  final String Function() accessTokenProvider;

  @override
  final String? Function()? organizationIdProvider;

  @override
  final Map<String, String> Function()? csrfHeadersProvider;

  List<Conversation>? _cachedConversations;

  // ── Conversations ──────────────────────────────────────────────────

  @override
  Future<List<Conversation>> loadConversations() async {
    final response = await cmmdGet('/api/ai/conversations');
    final json = jsonDecode(response.body);

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
    return conversation;
  }

  @override
  Future<void> deleteConversation(String id) async {
    await cmmdDelete('/api/ai/conversations/$id');
    _cachedConversations?.removeWhere((c) => c.id == id);
  }

  // ── Starring ───────────────────────────────────────────────────────

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

  // ── Messages ───────────────────────────────────────────────────────

  @override
  Future<List<Message>> loadMessages(String conversationId) async {
    final response = await cmmdGet('/api/ai/conversations/$conversationId');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final messages = json['messages'] as List<dynamic>? ?? [];
    return messages
        .map((e) => _parseMessage(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveMessage(String conversationId, Message message) async {}

  // ── Search (client-side) ───────────────────────────────────────────

  @override
  Future<List<Conversation>> searchConversations(String query) async {
    final all = _cachedConversations ?? await loadConversations();
    final lower = query.toLowerCase();
    return all
        .where((c) => c.title?.toLowerCase().contains(lower) ?? false)
        .toList();
  }

  // ── Metadata ───────────────────────────────────────────────────────

  @override
  Future<void> renameConversation(String id, String newTitle) async {
    await cmmdPatch(
      '/api/ai/conversations/$id',
      body: {'title': newTitle},
    );
  }

  // ── Parsing ────────────────────────────────────────────────────────

  Conversation _parseConversation(Map<String, dynamic> json) {
    return Conversation(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] as String?,
      createdAt: CmmdClientBase.parseDateTime(json['createdAt'] ?? json['updatedAt']),
      updatedAt: CmmdClientBase.parseDateTime(json['updatedAt'] ?? json['createdAt']),
      model: json['model'] as String?,
      metadata: {
        if (json['lastMessage'] != null) 'lastMessage': json['lastMessage'],
        if (json['messageCount'] != null) 'messageCount': json['messageCount'],
      },
    );
  }

  Message _parseMessage(Map<String, dynamic> json) {
    final roleStr = (json['role'] as String? ?? 'assistant').toLowerCase();
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
      timestamp: CmmdClientBase.parseDateTime(json['createdAt'] ?? json['timestamp']),
      thinkingContent: json['thinking'] as String?,
      status: MessageStatus.complete,
    );
  }
}
