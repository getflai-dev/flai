import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

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
    this.onError,
  });

  /// Called when an error occurs (API failures, timeouts, etc.).
  /// Use this to show a snackbar or toast.
  final void Function(String message)? onError;

  // ── State ───────────────────────────────────────────────────────────

  List<ConversationItem> _conversations = [];
  List<ConversationItem> get conversations => _conversations;

  List<ConversationItem> _starred = [];
  List<ConversationItem> get starred => _starred;

  String? _activeConversationId;
  String? get activeConversationId => _activeConversationId;

  List<Message> _messages = [];
  List<Message> get messages => _messages;

  bool _isLoadingConversations = false;
  bool get isLoadingConversations => _isLoadingConversations;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  String _streamingText = '';
  String _streamingThinking = '';
  final Map<String, ToolCall> _pendingToolCalls = {};
  List<Citation> _pendingCitations = [];

  /// Server-assigned chat ID, captured from the AI provider after streaming.
  String? _serverChatId;

  UserProfile? _cachedProfile;
  AuthUser? _lastUser;

  UserProfile? get userProfile {
    final user = auth.currentUser;
    if (user == null) return null;
    if (identical(user, _lastUser) && _cachedProfile != null) {
      return _cachedProfile;
    }
    _lastUser = user;
    final name = user.displayName ?? user.email;
    final initials = name.isNotEmpty
        ? name
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';
    _cachedProfile = UserProfile(
      name: name,
      email: user.email,
      avatarUrl: user.photoUrl,
      initials: initials,
      workspaceLabel: user.metadata?['defaultOrganizationId']?.toString(),
    );
    return _cachedProfile;
  }

  // ── Init / Dispose ─────────────────────────────────────────────────

  Future<void> loadConversations() async {
    _isLoadingConversations = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        storage.loadConversations(),
        storage.loadStarredConversations(),
      ]);
      _conversations = results[0].map(_toItem).toList();
      _starred = results[1].map((c) => _toItem(c, isStarred: true)).toList();
    } catch (e) {
      onError?.call('Failed to load conversations');
      debugPrint('Failed to load conversations: $e');
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    ai?.cancel();
    super.dispose();
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
    try {
      if (item.isStarred) {
        await storage.unstarConversation(item.id);
      } else {
        await storage.starConversation(item.id);
      }
      await loadConversations();
    } catch (e) {
      onError?.call('Failed to update star');
      debugPrint('Failed to star conversation: $e');
    }
  }

  Future<void> renameConversation(
    ConversationItem item,
    String newTitle,
  ) async {
    try {
      await storage.renameConversation(item.id, newTitle);
      await loadConversations();
    } catch (e) {
      onError?.call('Failed to rename conversation');
      debugPrint('Failed to rename conversation: $e');
    }
  }

  Future<void> deleteConversation(ConversationItem item) async {
    try {
      await storage.deleteConversation(item.id);
      if (_activeConversationId == item.id) {
        newChat();
      }
      await loadConversations();
    } catch (e) {
      onError?.call('Failed to delete conversation');
      debugPrint('Failed to delete conversation: $e');
      await loadConversations(); // reload to restore UI state
    }
  }

  Future<void> shareConversation(ConversationItem item) async {
    try {
      final messages = await storage.loadMessages(item.id);
      final buffer = StringBuffer()
        ..writeln(item.title)
        ..writeln();
      for (final msg in messages) {
        final role = msg.role == MessageRole.user ? 'You' : 'Assistant';
        buffer.writeln('$role: ${msg.content}');
        buffer.writeln();
      }
      await SharePlus.instance.share(ShareParams(text: buffer.toString()));
    } catch (e) {
      onError?.call('Failed to share conversation');
      debugPrint('Failed to share conversation: $e');
    }
  }

  // ── Send Message ────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || ai == null || _isStreaming) return;

    final isNewConversation = _activeConversationId == null;
    final localConvId = 'local-${DateTime.now().millisecondsSinceEpoch}';

    // For new conversations, set a local ID immediately so the UI switches
    // from the empty state to the chat content view.
    if (isNewConversation) {
      _activeConversationId = localConvId;
      await storage.saveConversation(
        Conversation(
          id: localConvId,
          title: text.length > 40 ? '${text.substring(0, 40)}...' : text,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    // Add user message.
    final userMsg = Message(
      id: '${DateTime.now().millisecondsSinceEpoch}-user',
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );
    _messages = [..._messages, userMsg];
    await storage.saveMessage(_activeConversationId!, userMsg);

    // Add streaming placeholder.
    _isStreaming = true;
    _streamingText = '';
    _streamingThinking = '';
    _pendingToolCalls.clear();
    _pendingCitations = [];

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
      final metadata = <String, dynamic>{};
      // For follow-up messages, use the server-assigned chatId from the
      // AI provider (set from the first SSE event's conversationId field).
      // Don't send our local ID — the server won't recognize it.
      final serverChatId = _serverChatId;
      if (!isNewConversation && serverChatId != null) {
        metadata['conversationId'] = serverChatId;
      }

      final request = ChatRequest(
        messages: _messages
            .where((m) => m.status != MessageStatus.streaming)
            .toList(),
        metadata: metadata,
      );

      await for (final event in ai!.streamChat(request)) {
        switch (event) {
          case TextDelta(:final text):
            _streamingText += text;
            _updateStreamingMessage(assistantId);
          case ThinkingStart():
            // Thinking phase started.
            break;
          case ThinkingDelta(:final text):
            _streamingThinking += text;
            _updateStreamingMessage(assistantId);
          case ThinkingEnd():
            break;
          case TextDone() || ChatDone():
            // Skip if already finalized by a ChatError.
            if (_messages.isNotEmpty &&
                _messages.last.id == assistantId &&
                _messages.last.status == MessageStatus.streaming) {
              if (_streamingText.isEmpty) {
                _finalizeWithError(assistantId, 'No response received');
              } else {
                _finalizeMessage(assistantId);
              }
            }
          case ChatError(:final error):
            _finalizeWithError(assistantId, error.toString());
          case ToolCallStart(:final id, :final name):
            _pendingToolCalls[id] = ToolCall(id: id, name: name, arguments: '');
            _updateStreamingMessage(assistantId);
          case ToolCallDelta(:final id, :final argumentsDelta):
            final existing = _pendingToolCalls[id];
            if (existing != null) {
              _pendingToolCalls[id] = existing.copyWith(
                arguments: existing.arguments + argumentsDelta,
              );
            }
          case ToolCallEnd(:final id):
            final existing = _pendingToolCalls[id];
            if (existing != null) {
              _pendingToolCalls[id] = existing.copyWith(isComplete: true);
              _updateStreamingMessage(assistantId);
            }
          case CitationsReceived(:final citations):
            _pendingCitations.addAll(citations);
            _updateStreamingMessage(assistantId);
          default:
            break;
        }
      }
    } catch (e) {
      _finalizeWithError(assistantId, e.toString());
    }

    _isStreaming = false;

    // Capture server-assigned chatId from the AI provider if available.
    // CmmdAiProvider exposes lastChatId; other providers may not.
    try {
      final chatId = (ai as dynamic).lastChatId as String?;
      if (chatId != null) {
        _serverChatId = chatId;
        _activeConversationId = chatId;
      }
    } catch (_) {
      // AI provider doesn't expose lastChatId — use storage fallback.
    }

    // For new conversations without a server chatId, reload from storage.
    if (isNewConversation && _serverChatId == null) {
      await loadConversations();
      if (_conversations.isNotEmpty) {
        _activeConversationId = _conversations.first.id;
      }
    }

    await loadConversations();

    // If the API returned no conversations (server may need time to index),
    // retry once after a short delay.
    if (_conversations.isEmpty && _serverChatId != null) {
      await Future<void>.delayed(const Duration(seconds: 2));
      await loadConversations();
    }

    notifyListeners();
  }

  // ── Private Helpers ─────────────────────────────────────────────────

  void _updateStreamingMessage(String id) {
    // The streaming message is always last — O(1) instead of indexWhere scan.
    if (_messages.isEmpty) return;
    final last = _messages.last;
    if (last.id != id) return;

    _messages = [
      ..._messages.sublist(0, _messages.length - 1),
      last.copyWith(
        content: _streamingText,
        thinkingContent: _streamingThinking.isNotEmpty
            ? _streamingThinking
            : null,
        toolCalls: _pendingToolCalls.isNotEmpty
            ? _pendingToolCalls.values.toList()
            : null,
        citations: _pendingCitations.isNotEmpty
            ? _pendingCitations.toList()
            : null,
      ),
    ];
    notifyListeners();
  }

  void _finalizeMessage(String id) {
    if (_messages.isEmpty) return;
    final last = _messages.last;
    if (last.id != id) return;

    final msg = last.copyWith(
      content: _streamingText,
      thinkingContent: _streamingThinking.isNotEmpty
          ? _streamingThinking
          : null,
      toolCalls: _pendingToolCalls.isNotEmpty
          ? _pendingToolCalls.values.toList()
          : null,
      citations: _pendingCitations.isNotEmpty
          ? _pendingCitations.toList()
          : null,
      status: MessageStatus.complete,
    );
    _messages = [..._messages.sublist(0, _messages.length - 1), msg];

    final convId = _activeConversationId;
    if (convId != null) {
      storage.saveMessage(convId, msg);
    }
    notifyListeners();
  }

  void _finalizeWithError(String id, String error) {
    if (_messages.isEmpty) return;
    final last = _messages.last;
    if (last.id != id) return;

    final errorText = _streamingText.isNotEmpty ? _streamingText : error;

    _messages = [
      ..._messages.sublist(0, _messages.length - 1),
      last.copyWith(content: errorText, status: MessageStatus.error),
    ];
    onError?.call(error);
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
