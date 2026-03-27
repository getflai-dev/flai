import 'message.dart';

sealed class ChatEvent {
  const ChatEvent();
}

class TextDelta extends ChatEvent {
  final String text;
  const TextDelta(this.text);
}

class TextDone extends ChatEvent {
  final String fullText;
  const TextDone(this.fullText);
}

class ToolCallStart extends ChatEvent {
  final String id;
  final String name;
  const ToolCallStart({required this.id, required this.name});
}

class ToolCallDelta extends ChatEvent {
  final String id;
  final String argumentsDelta;
  const ToolCallDelta({required this.id, required this.argumentsDelta});
}

class ToolCallEnd extends ChatEvent {
  final String id;
  const ToolCallEnd({required this.id});
}

class ThinkingStart extends ChatEvent {
  const ThinkingStart();
}

class ThinkingDelta extends ChatEvent {
  final String text;
  const ThinkingDelta(this.text);
}

class ThinkingEnd extends ChatEvent {
  const ThinkingEnd();
}

class UsageUpdate extends ChatEvent {
  final int inputTokens;
  final int outputTokens;
  final int? cacheReadTokens;
  final int? cacheCreationTokens;
  const UsageUpdate({
    required this.inputTokens,
    required this.outputTokens,
    this.cacheReadTokens,
    this.cacheCreationTokens,
  });
}

class ChatDone extends ChatEvent {
  const ChatDone();
}

class ChatError extends ChatEvent {
  final Object error;
  final StackTrace? stackTrace;
  const ChatError(this.error, [this.stackTrace]);
}

class CitationsReceived extends ChatEvent {
  final List<Citation> citations;
  const CitationsReceived(this.citations);
}
