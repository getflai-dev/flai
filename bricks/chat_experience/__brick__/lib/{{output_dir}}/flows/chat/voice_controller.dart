import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../providers/voice_provider.dart';

/// Orchestrates the full push-to-talk voice pipeline:
/// microphone capture → audio bytes → transcription → message send.
///
/// Wraps the `record` package for microphone access and delegates
/// transcription to the configured [VoiceProvider]. When recording stops,
/// the transcribed text is delivered via [onTranscribed].
///
/// ```dart
/// final controller = FlaiVoiceController(
///   provider: cmmdVoiceProvider,
///   onTranscribed: (text) => sendMessage(text),
/// );
///
/// await controller.startRecording();  // mic starts
/// await controller.stopRecording();   // mic stops → transcribes → fires onTranscribed
/// ```
class FlaiVoiceController extends ChangeNotifier {
  /// The voice provider that handles server-side transcription.
  final VoiceProvider provider;

  /// Called with the transcribed text after recording stops successfully.
  ///
  /// Typically wired to send the text as a chat message.
  final ValueChanged<String>? onTranscribed;

  /// Called when an error occurs during recording or transcription.
  final ValueChanged<String>? onError;

  /// Creates a [FlaiVoiceController].
  FlaiVoiceController({
    required this.provider,
    this.onTranscribed,
    this.onError,
  });

  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isTranscribing = false;
  String? _lastTranscript;

  /// Whether the microphone is actively recording.
  bool get isRecording => _isRecording;

  /// Whether recorded audio is being transcribed to text.
  bool get isTranscribing => _isTranscribing;

  /// The most recent transcription result.
  ///
  /// Changes each time a recording is successfully transcribed. The home
  /// screen passes this to [FlaiComposerV2.voiceTranscript] so the text
  /// populates the input field for the user to review before sending.
  String? get lastTranscript => _lastTranscript;

  /// Whether any voice operation is in progress (recording or transcribing).
  bool get isBusy => _isRecording || _isTranscribing;

  /// Start recording audio from the device microphone.
  ///
  /// Checks for microphone permission first. If denied, fires [onError].
  /// Records in WAV format for maximum transcription compatibility.
  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      onError?.call('Microphone permission denied');
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/flai_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav),
      path: path,
    );

    _isRecording = true;
    notifyListeners();
  }

  /// Stop recording and transcribe the audio.
  ///
  /// After recording stops, reads the audio file, sends it to the
  /// [VoiceProvider] for transcription, and fires [onTranscribed] with
  /// the resulting text. The audio file is deleted after transcription.
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    final path = await _recorder.stop();
    _isRecording = false;
    notifyListeners();

    if (path == null) return;

    _isTranscribing = true;
    notifyListeners();

    try {
      final file = File(path);
      final bytes = await file.readAsBytes();

      final text = await provider.transcribe(bytes);

      // Clean up the temp file.
      if (await file.exists()) {
        await file.delete();
      }

      if (text.trim().isNotEmpty) {
        _lastTranscript = text.trim();
        onTranscribed?.call(text.trim());
      }
    } catch (e) {
      onError?.call('Could not transcribe audio');
    } finally {
      _isTranscribing = false;
      notifyListeners();
    }
  }

  /// Cancel an in-progress recording without transcribing.
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    final path = await _recorder.stop();
    _isRecording = false;
    notifyListeners();

    // Clean up the temp file.
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}
