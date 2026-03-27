import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/models/chat_event.dart';
import '../core/models/chat_request.dart';
import '../core/models/conversation.dart';
import '../core/models/message.dart';
import '../flows/sidebar/sidebar_config.dart';
import '../providers/ai_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/storage_provider.dart';

/// Manages home screen state: conversations, active chat, and streaming.
///
/// Bridges [StorageProvider], [AiProvider], and [AuthProvider] into a single
/// [ChangeNotifier] that the wired home page listens to.
class HomeController extends ChangeNotifier {
  final StorageProvider storage;
  final AiProvider? ai;
  final AuthProvider auth;

  HomeController({
    required this.storage,
    required this.ai,
    required this.auth,
  });

  // ── State ───────────────────────────────────────────────────────────

  List<ConversationItem> _conversations = [];
  List<ConversationItem> get conversations => _conversations;

  List<ConversationItem> _starred = [];
  List<ConversationItem> get starred => _starred;

  String? _activeConversationId;
  String? get activeConversationId => _activeConversationId;

  List<Message> _messages = [];
  List<Message> get messages => _messages;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  String _streamingText = '';
  String _streamingThinking = '';

  UserProfile? get userProfile {
    final user = auth.currentUser;
    if (user == null) return null;
    final name = user.displayName ?? user.email;
    final initials = name.isNotEmpty
        ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';
    return UserProfile(
      name: name,
      email: user.email,
      avatarUrl: user.photoUrl,
      initials: initials,
      workspaceLabel: user.metadata?['defaultOrganizationId']?.toString(),
    );
  }

  // ── Init ────────────────────────────────────────────────────────────

  Future<void> loadConversations() async {
    try {
      final convos = await storage.loadConversations();
      _conversations = convos.map(_toItem).toList();

      final starredConvos = await storage.loadStarredConversations();
      _starred = starredConvos.map((c) => _toItem(c, isStarred: true)).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load conversations: $e');
    }
  }

  // ── Conversation Actions ────────────────────────────────────────────

  Future<void> selectConversation(ConversationItem item) async {
    _activeConversationId = item.id;
    _messages = await storage.loadMessages(item.id);
    notifyListeners();
  }

  void newChat() {
    _activeConversationId = null;
    _messages = [];
    _streamingText = '';
    _streamingThinking = '';
    notifyListeners();
  }

  Future<void> starConversation(ConversationItem item) async {
    if (item.isStarred) {
      await storage.unstarConversation(item.id);
    } else {
      await storage.starConversation(item.id);
    }
    await loadConversations();
  }

  Future<void> renameConversation(ConversationItem item, String newTitle) async {
    await storage.renameConversation(item.id, newTitle);
    await loadConversations();
  }

  Future<void> deleteConversation(ConversationItem item) async {
    await storage.deleteConversation(item.id);
    if (_activeConversationId == item.id) {
      newChat();
    }
    await loadConversations();
  }

  // ── Send Message ────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || ai == null) return;

    // Create or reuse conversation.
    final conversationId = _activeConversationId ?? DateTime.now().millisecondsSinceEpoch.toString();
    if (_activeConversationId == null) {
      _activeConversationId = conversationId;
      final conv = Conversation(
        id: conversationId,
        title: text.length > 40 ? '${text.substring(0, 40)}...' : text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await storage.saveConversation(conv);
    }

    // Add user message.
    final userMsg = Message(
      id: '${DateTime.now().millisecondsSinceEpoch}-user',
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );
    _messages = [..._messages, userMsg];
    await storage.saveMessage(conversationId, userMsg);
    notifyListeners();

    // Stream AI response.
    _isStreaming = true;
    _streamingText = '';
    _streamingThinking = '';

    final assistantId = '${DateTime.now().millisecondsSinceEpoch}-assistant';
    _messages = [
      ..._messages,
      Message(
        id: assistantId,
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        status: MessageStatus.streaming,
      ),
    ];
    notifyListeners();

    try {
      final request = ChatRequest(
        messages: _messages.where((m) => m.status != MessageStatus.streaming).toList(),
        metadata: {'conversationId': conversationId},
      );

      await for (final event in ai!.streamChat(request)) {
        switch (event) {
          case TextDelta(:final text):
            _streamingText += text;
            _updateStreamingMessage(assistantId);
          case ThinkingDelta(:final text):
            _streamingThinking += text;
            _updateStreamingMessage(assistantId);
          case TextDone() || ChatDone():
            _finalizeMessage(assistantId, conversationId);
          case ChatError(:final error):
            _finalizeWithError(assistantId, error.toString());
          default:
            break;
        }
      }
    } catch (e) {
      _finalizeWithError(assistantId, e.toString());
    }

    _isStreaming = false;
    await loadConversations();
    notifyListeners();
  }

  // ── Private Helpers ─────────────────────────────────────────────────

  void _updateStreamingMessage(String id) {
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx < 0) return;

    _messages = [
      ..._messages.sublist(0, idx),
      _messages[idx].copyWith(
        content: _streamingText,
        thinkingContent: _streamingThinking.isNotEmpty ? _streamingThinking : null,
      ),
      ..._messages.sublist(idx + 1),
    ];
    notifyListeners();
  }

  void _finalizeMessage(String id, String conversationId) {
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx < 0) return;

    final msg = _messages[idx].copyWith(
      content: _streamingText,
      thinkingContent: _streamingThinking.isNotEmpty ? _streamingThinking : null,
      status: MessageStatus.complete,
    );
    _messages = [
      ..._messages.sublist(0, idx),
      msg,
      ..._messages.sublist(idx + 1),
    ];
    storage.saveMessage(conversationId, msg);
    notifyListeners();
  }

  void _finalizeWithError(String id, String error) {
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx < 0) return;

    _messages = [
      ..._messages.sublist(0, idx),
      _messages[idx].copyWith(
        content: _streamingText.isNotEmpty ? _streamingText : 'Error: $error',
        status: MessageStatus.error,
      ),
      ..._messages.sublist(idx + 1),
    ];
    notifyListeners();
  }

  ConversationItem _toItem(Conversation c, {bool isStarred = false}) {
    return ConversationItem(
      id: c.id,
      title: c.displayTitle,
      preview: c.lastMessage?.content ?? '',
      timestamp: c.updatedAt,
      isStarred: isStarred,
    );
  }
}
