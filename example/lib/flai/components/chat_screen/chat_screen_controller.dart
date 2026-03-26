import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/models/chat_event.dart';
import '../../core/models/chat_request.dart';
import '../../core/models/message.dart';
import '../../providers/ai_provider.dart';

/// Controller for managing chat state, message history, and AI provider
/// interaction.
///
/// Connects a [FlaiChatScreen] to an [AiProvider], handling message sending,
/// streaming responses, tool calls, and error recovery.
class ChatScreenController extends ChangeNotifier {
  final AiProvider _provider;
  final List<Message> _messages = [];
  final String? _systemPrompt;

  StreamSubscription<ChatEvent>? _streamSubscription;
  bool _isStreaming = false;
  String _streamingText = '';
  String _thinkingText = '';
  bool _isThinking = false;
  final List<ToolCall> _activeToolCalls = [];

  ChatScreenController({
    required AiProvider provider,
    String? systemPrompt,
    List<Message>? initialMessages,
  }) : _provider = provider,
       _systemPrompt = systemPrompt {
    if (initialMessages != null) {
      _messages.addAll(initialMessages);
    }
  }

  /// Current messages in the conversation.
  List<Message> get messages => List.unmodifiable(_messages);

  /// Whether the AI is currently generating a response.
  bool get isStreaming => _isStreaming;

  /// Current streaming text (incomplete response).
  String get streamingText => _streamingText;

  /// Whether the AI is currently in a thinking phase.
  bool get isThinking => _isThinking;

  /// The AI provider powering this chat.
  AiProvider get provider => _provider;

  /// Send a user message and stream the AI response.
  Future<void> sendMessage(
    String content, {
    List<Attachment>? attachments,
  }) async {
    if (content.trim().isEmpty) return;
    if (_isStreaming) return;

    final userMessage = Message(
      id: _generateId(),
      role: MessageRole.user,
      content: content.trim(),
      timestamp: DateTime.now(),
      attachments: attachments,
    );

    _messages.add(userMessage);
    notifyListeners();

    await _streamResponse();
  }

  /// Retry the last failed message.
  Future<void> retry() async {
    if (_isStreaming) return;
    if (_messages.isEmpty) return;

    final lastMessage = _messages.last;
    if (lastMessage.role == MessageRole.assistant &&
        lastMessage.status == MessageStatus.error) {
      _messages.removeLast();
      notifyListeners();
      await _streamResponse();
    }
  }

  /// Cancel the current streaming response.
  Future<void> cancel() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    await _provider.cancel();

    if (_streamingText.isNotEmpty) {
      _messages.add(
        Message(
          id: _generateId(),
          role: MessageRole.assistant,
          content: _streamingText,
          timestamp: DateTime.now(),
          thinkingContent: _thinkingText.isNotEmpty ? _thinkingText : null,
          toolCalls: _activeToolCalls.isNotEmpty
              ? List.of(_activeToolCalls)
              : null,
          status: MessageStatus.complete,
        ),
      );
    }

    _resetStreamingState();
    notifyListeners();
  }

  /// Clear all messages.
  void clearMessages() {
    _messages.clear();
    _resetStreamingState();
    notifyListeners();
  }

  /// Add a message programmatically (e.g., system messages, tool results).
  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  Future<void> _streamResponse() async {
    _isStreaming = true;
    _streamingText = '';
    _thinkingText = '';
    _isThinking = false;
    _activeToolCalls.clear();
    notifyListeners();

    final systemPrompt = _systemPrompt;
    final requestMessages = <Message>[
      if (systemPrompt != null)
        Message(
          id: 'system',
          role: MessageRole.system,
          content: systemPrompt,
          timestamp: DateTime.now(),
        ),
      ..._messages,
    ];

    final request = ChatRequest(messages: requestMessages);

    try {
      final stream = _provider.streamChat(request);
      _streamSubscription = stream.listen(
        _handleEvent,
        onError: _handleError,
        onDone: _handleDone,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleEvent(ChatEvent event) {
    switch (event) {
      case TextDelta(:final text):
        _streamingText += text;
        notifyListeners();

      case TextDone(:final fullText):
        _streamingText = fullText;
        notifyListeners();

      case ThinkingStart():
        _isThinking = true;
        notifyListeners();

      case ThinkingDelta(:final text):
        _thinkingText += text;
        notifyListeners();

      case ThinkingEnd():
        _isThinking = false;
        notifyListeners();

      case ToolCallStart(:final id, :final name):
        _activeToolCalls.add(ToolCall(id: id, name: name, arguments: ''));
        notifyListeners();

      case ToolCallDelta(:final id, :final argumentsDelta):
        final index = _activeToolCalls.indexWhere((tc) => tc.id == id);
        if (index >= 0) {
          final tc = _activeToolCalls[index];
          _activeToolCalls[index] = tc.copyWith(
            arguments: tc.arguments + argumentsDelta,
          );
          notifyListeners();
        }

      case ToolCallEnd(:final id):
        final index = _activeToolCalls.indexWhere((tc) => tc.id == id);
        if (index >= 0) {
          _activeToolCalls[index] = _activeToolCalls[index].copyWith(
            isComplete: true,
          );
          notifyListeners();
        }

      case UsageUpdate():
        // Usage tracking can be handled by listeners
        break;

      case ChatDone():
        _handleDone();

      case ChatError(:final error):
        _handleError(error);
    }
  }

  void _handleDone() {
    final assistantMessage = Message(
      id: _generateId(),
      role: MessageRole.assistant,
      content: _streamingText,
      timestamp: DateTime.now(),
      thinkingContent: _thinkingText.isNotEmpty ? _thinkingText : null,
      toolCalls: _activeToolCalls.isNotEmpty ? List.of(_activeToolCalls) : null,
      status: MessageStatus.complete,
    );

    _messages.add(assistantMessage);
    _resetStreamingState();
    notifyListeners();
  }

  void _handleError(Object error) {
    final errorMessage = Message(
      id: _generateId(),
      role: MessageRole.assistant,
      content: _streamingText.isNotEmpty
          ? _streamingText
          : 'An error occurred. Please try again.',
      timestamp: DateTime.now(),
      status: MessageStatus.error,
    );

    _messages.add(errorMessage);
    _resetStreamingState();
    notifyListeners();
  }

  void _resetStreamingState() {
    _isStreaming = false;
    _streamingText = '';
    _thinkingText = '';
    _isThinking = false;
    _activeToolCalls.clear();
    _streamSubscription = null;
  }

  String _generateId() =>
      '${DateTime.now().millisecondsSinceEpoch}_${_messages.length}';

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
