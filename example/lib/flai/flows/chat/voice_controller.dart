import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../providers/voice_provider.dart';

/// Orchestrates the push-to-talk voice pipeline for the chat experience.
///
/// Listens to [VoiceProvider.conversationEvents] for transcription results.
/// When the provider emits a [VoiceTranscript], the text is captured in
/// [lastTranscript] and [onTranscribed] fires so the composer can populate
/// the text field for user review.
///
/// This controller is provider-agnostic: it works with both on-device STT
/// providers (like CMMD's `speech_to_text`-based provider) and server-side
/// transcription providers.
///
/// ```dart
/// final controller = FlaiVoiceController(
///   provider: cmmdVoiceProvider,
///   onTranscribed: (text) => composerController.text = text,
/// );
///
/// await controller.startRecording();  // provider starts listening
/// await controller.stopRecording();   // provider stops → transcript fires
/// ```
class FlaiVoiceController extends ChangeNotifier {
  /// The voice provider that handles speech-to-text.
  final VoiceProvider provider;

  /// Called with the transcribed text after recording stops.
  final ValueChanged<String>? onTranscribed;

  /// Called when an error occurs during recording or transcription.
  final ValueChanged<String>? onError;

  /// Creates a [FlaiVoiceController].
  FlaiVoiceController({
    required this.provider,
    this.onTranscribed,
    this.onError,
  }) {
    _subscription = provider.conversationEvents.listen(_onVoiceEvent);
  }

  StreamSubscription<VoiceEvent>? _subscription;

  bool _isRecording = false;
  bool _isTranscribing = false;
  String? _lastTranscript;

  /// Whether the microphone is actively listening.
  bool get isRecording => _isRecording;

  /// Whether speech is being transcribed to text.
  bool get isTranscribing => _isTranscribing;

  /// The most recent transcription result.
  ///
  /// The home screen passes this to [FlaiComposerV2.voiceTranscript] so the
  /// text populates the input field for the user to review before sending.
  String? get lastTranscript => _lastTranscript;

  /// Whether any voice operation is in progress.
  bool get isBusy => _isRecording || _isTranscribing;

  /// Start listening for speech.
  ///
  /// Delegates to [VoiceProvider.startConversation] which triggers
  /// on-device or server-side speech recognition depending on the provider.
  Future<void> startRecording() async {
    if (_isRecording) return;

    _isRecording = true;
    notifyListeners();

    try {
      await provider.startConversation();
    } catch (e) {
      _isRecording = false;
      notifyListeners();
      onError?.call('Could not start voice recording');
    }
  }

  /// Stop listening and wait for the final transcript.
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    _isRecording = false;
    _isTranscribing = true;
    notifyListeners();

    try {
      await provider.stopConversation();
    } catch (e) {
      onError?.call('Could not stop voice recording');
    } finally {
      _isTranscribing = false;
      notifyListeners();
    }
  }

  /// Cancel an in-progress recording without transcribing.
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    _isRecording = false;
    notifyListeners();

    try {
      await provider.stopConversation();
    } catch (_) {
      // Ignore errors during cancel.
    }
  }

  void _onVoiceEvent(VoiceEvent event) {
    switch (event) {
      case VoiceTranscript(:final text):
        if (text.trim().isNotEmpty) {
          _lastTranscript = text.trim();
          _isTranscribing = false;
          notifyListeners();
          onTranscribed?.call(text.trim());
        }
      case VoiceError(:final message):
        _isRecording = false;
        _isTranscribing = false;
        notifyListeners();
        onError?.call(message);
      case VoiceConversationDone():
        _isRecording = false;
        _isTranscribing = false;
        notifyListeners();
      case VoiceAudio():
        // Audio playback is handled by the caller, not the controller.
        break;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
