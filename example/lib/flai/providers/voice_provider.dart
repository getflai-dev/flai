import 'dart:typed_data';

/// Events emitted during voice conversation mode.
sealed class VoiceEvent {
  const VoiceEvent();
}

/// User speech was transcribed to text.
class VoiceTranscript extends VoiceEvent {
  const VoiceTranscript(this.text);
  final String text;
}

/// AI response audio is available for playback.
class VoiceAudio extends VoiceEvent {
  const VoiceAudio(this.audio);
  final Uint8List audio;
}

/// Voice conversation ended.
class VoiceConversationDone extends VoiceEvent {
  const VoiceConversationDone();
}

/// Voice error occurred.
class VoiceError extends VoiceEvent {
  const VoiceError(this.message);
  final String message;
}

/// Abstract interface for voice input/output.
///
/// Implement this to add speech-to-text and text-to-speech capabilities.
/// Both push-to-talk and continuous conversation modes use this interface.
abstract class VoiceProvider {
  /// Transcribe recorded audio to text (push-to-talk mode).
  Future<String> transcribe(Uint8List audio);

  /// Synthesize text to audio bytes for playback.
  Future<Uint8List> synthesize(String text);

  /// Start continuous voice conversation mode.
  Future<void> startConversation();

  /// Stop continuous voice conversation mode.
  Future<void> stopConversation();

  /// Stream of events during conversation mode.
  Stream<VoiceEvent> get conversationEvents;

  /// Whether the provider is currently listening for speech.
  bool get isListening;

  /// Whether the provider is currently playing audio.
  bool get isSpeaking;
}
