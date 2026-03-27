import '../core/models/conversation.dart';
import '../core/models/message.dart';

/// Abstract interface for conversation persistence.
///
/// Implement this to store conversations in SQLite, Hive, or a remote API.
/// Use [InMemoryStorageProvider] during development.
abstract class StorageProvider {
  // Conversations
  Future<List<Conversation>> loadConversations();
  Future<Conversation> saveConversation(Conversation conversation);
  Future<void> deleteConversation(String id);

  // Starring
  Future<void> starConversation(String id);
  Future<void> unstarConversation(String id);
  Future<List<Conversation>> loadStarredConversations();

  // Messages
  Future<List<Message>> loadMessages(String conversationId);
  Future<void> saveMessage(String conversationId, Message message);

  // Search
  Future<List<Conversation>> searchConversations(String query);

  // Metadata
  Future<void> renameConversation(String id, String newTitle);
}

/// In-memory storage provider for development and testing.
///
/// Data is lost when the app restarts. Replace with a persistent
/// implementation for production.
class InMemoryStorageProvider implements StorageProvider {
  final Map<String, Conversation> _conversations = {};
  final Map<String, List<Message>> _messages = {};
  final Set<String> _starred = {};

  @override
  Future<List<Conversation>> loadConversations() async {
    final list = _conversations.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<Conversation> saveConversation(Conversation conversation) async {
    _conversations[conversation.id] = conversation;
    return conversation;
  }

  @override
  Future<void> deleteConversation(String id) async {
    _conversations.remove(id);
    _messages.remove(id);
    _starred.remove(id);
  }

  @override
  Future<void> starConversation(String id) async {
    _starred.add(id);
  }

  @override
  Future<void> unstarConversation(String id) async {
    _starred.remove(id);
  }

  @override
  Future<List<Conversation>> loadStarredConversations() async {
    return _conversations.values.where((c) => _starred.contains(c.id)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<Message>> loadMessages(String conversationId) async {
    return _messages[conversationId] ?? [];
  }

  @override
  Future<void> saveMessage(String conversationId, Message message) async {
    _messages.putIfAbsent(conversationId, () => []);
    final messages = _messages[conversationId]!;
    final index = messages.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      messages[index] = message;
    } else {
      messages.add(message);
    }
  }

  @override
  Future<List<Conversation>> searchConversations(String query) async {
    final lower = query.toLowerCase();
    return _conversations.values.where((c) {
      if (c.title?.toLowerCase().contains(lower) ?? false) return true;
      final msgs = _messages[c.id];
      if (msgs == null) return false;
      return msgs.any((m) => m.content.toLowerCase().contains(lower));
    }).toList();
  }

  @override
  Future<void> renameConversation(String id, String newTitle) async {
    final conv = _conversations[id];
    if (conv != null) {
      _conversations[id] = conv.copyWith(title: newTitle);
    }
  }
}
