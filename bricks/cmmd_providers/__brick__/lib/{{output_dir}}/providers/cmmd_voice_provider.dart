import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'cmmd_config.dart';
import 'voice_provider.dart';

/// CMMD implementation of [VoiceProvider].
///
/// **STT (speech-to-text):** Uses the `speech_to_text` Flutter package for
/// on-device recognition — no server API call. This provides faster results
/// and works offline.
///
/// **TTS (text-to-speech):** Uses `POST /api/ai/tts` to synthesize speech
/// via the CMMD backend (returns audio/mpeg binary).
///
/// ```dart
/// final voice = CmmdVoiceProvider(
///   config: CmmdConfig(),
///   accessTokenProvider: () => authProvider.accessToken!,
/// );
///
/// // On-device transcription
/// await voice.startListening();
/// // ... user speaks ...
/// final text = voice.lastTranscript;
///
/// // Server TTS
/// final audio = await voice.synthesize('Hello, world!');
/// ```
class CmmdVoiceProvider implements VoiceProvider {
  /// Creates a [CmmdVoiceProvider].
  CmmdVoiceProvider({
    required this.config,
    required this.accessTokenProvider,
    this.organizationIdProvider,
    this.csrfHeadersProvider,
    this.localeId = 'en_US',
  });

  /// The CMMD API configuration.
  final CmmdConfig config;

  /// Returns the current JWT access token for authenticated requests.
  final String Function() accessTokenProvider;

  /// Returns the current organization ID, if available.
  final String? Function()? organizationIdProvider;

  /// Returns CSRF headers from the auth provider, if available.
  final Map<String, String> Function()? csrfHeadersProvider;

  /// Locale for on-device speech recognition (e.g., 'en_US', 'es_ES').
  final String localeId;

  final SpeechToText _speechToText = SpeechToText();
  final StreamController<VoiceEvent> _eventController =
      StreamController<VoiceEvent>.broadcast();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  String _lastTranscript = '';

  /// The most recent transcript from on-device recognition.
  String get lastTranscript => _lastTranscript;

  // ---------------------------------------------------------------------------
  // VoiceProvider interface
  // ---------------------------------------------------------------------------

  @override
  bool get isListening => _isListening;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Stream<VoiceEvent> get conversationEvents => _eventController.stream;

  // ---------------------------------------------------------------------------
  // Transcription (on-device speech_to_text)
  // ---------------------------------------------------------------------------

  @override
  Future<String> transcribe(Uint8List audio) async {
    // CMMD uses on-device STT, not server-side transcription.
    // The audio bytes are ignored — use startListening() / stopListening()
    // for real-time on-device recognition.
    //
    // This method is kept for VoiceProvider interface compatibility.
    // If called directly, return the last transcript.
    return _lastTranscript;
  }

  /// Initialize the speech recognition engine.
  ///
  /// Must be called once before [startListening]. Returns `true` if
  /// speech recognition is available on this device.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _isInitialized = await _speechToText.initialize(
      onStatus: _onStatus,
      onError: (error) {
        _eventController.add(VoiceError(error.errorMsg));
        _isListening = false;
      },
    );

    return _isInitialized;
  }

  /// Start listening for speech using on-device recognition.
  ///
  /// Call [initialize] first. Emits [VoiceTranscript] events as the user
  /// speaks. Call [stopListening] to stop and get the final transcript.
  Future<void> startListening() async {
    if (!_isInitialized) {
      final available = await initialize();
      if (!available) {
        _eventController.add(
          const VoiceError('Speech recognition not available on this device.'),
        );
        return;
      }
    }

    _lastTranscript = '';
    _isListening = true;

    await _speechToText.listen(
      onResult: _onResult,
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  /// Stop listening and return the final transcript.
  Future<String> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    return _lastTranscript;
  }

  void _onResult(SpeechRecognitionResult result) {
    _lastTranscript = result.recognizedWords;
    _eventController.add(VoiceTranscript(_lastTranscript));

    if (result.finalResult) {
      _isListening = false;
    }
  }

  void _onStatus(String status) {
    if (status == 'notListening' || status == 'done') {
      _isListening = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Synthesis (server-side TTS)
  // ---------------------------------------------------------------------------

  @override
  Future<Uint8List> synthesize(String text, {String? voice}) async {
    try {
      _isSpeaking = true;

      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/ai/tts'),
        headers: _headers,
        body: jsonEncode({
          'text': text,
          'voice': ?voice,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'TTS synthesis failed (${response.statusCode}): ${response.body}',
        );
      }

      // Response is audio/mpeg binary.
      final audioBytes = Uint8List.fromList(response.bodyBytes);
      _eventController.add(VoiceAudio(audioBytes));
      return audioBytes;
    } finally {
      _isSpeaking = false;
    }
  }

  /// Fetch available TTS voices from the server.
  Future<List<({String id, String name, String? previewUrl})>>
      getVoices() async {
    final response = await http.get(
      Uri.parse('${config.baseUrl}/api/ai/tts/voices'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      return [];
    }

    final json = jsonDecode(response.body) as List<dynamic>;
    return json.map((v) {
      final map = v as Map<String, dynamic>;
      return (
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        previewUrl: map['preview_url'] as String?,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Conversation mode
  // ---------------------------------------------------------------------------

  @override
  Future<void> startConversation() async {
    // In push-to-talk mode, startConversation maps to startListening.
    await startListening();
  }

  @override
  Future<void> stopConversation() async {
    if (_isListening) {
      final transcript = await stopListening();
      // Emit the final transcript so the voice controller picks it up.
      if (transcript.trim().isNotEmpty) {
        _eventController.add(VoiceTranscript(transcript.trim()));
      }
    }
    _isSpeaking = false;
    _eventController.add(const VoiceConversationDone());
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Map<String, String> get _headers {
    final orgId = organizationIdProvider?.call() ?? config.organizationId;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/octet-stream',
      'User-Agent': 'FlAI/1.0 (cmmd_providers)',
      'Authorization': 'Bearer ${accessTokenProvider()}',
      'X-Auth-Type': 'jwt',
      'X-Organization-ID': ?orgId,
      ...?csrfHeadersProvider?.call(),
    };
  }
}
