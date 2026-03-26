import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'cmmd_config.dart';
import 'voice_provider.dart';

/// CMMD API implementation of [VoiceProvider].
///
/// Provides speech-to-text via `/api/ai/voice/transcribe` and
/// text-to-speech via `/api/ai/tts`. CMMD does not support
/// streaming TTS or continuous voice conversation mode.
///
/// ```dart
/// final voice = CmmdVoiceProvider(
///   config: CmmdConfig(),
///   accessTokenProvider: () => authProvider.accessToken!,
/// );
///
/// final text = await voice.transcribe(audioBytes);
/// final audio = await voice.synthesize('Hello, world!');
/// ```
class CmmdVoiceProvider implements VoiceProvider {
  /// Creates a [CmmdVoiceProvider].
  ///
  /// [config] specifies the CMMD API base URL and organization.
  /// [accessTokenProvider] returns the current JWT access token.
  CmmdVoiceProvider({
    required this.config,
    required this.accessTokenProvider,
  });

  /// The CMMD API configuration.
  final CmmdConfig config;

  /// Returns the current JWT access token for authenticated requests.
  final String Function() accessTokenProvider;

  final StreamController<VoiceEvent> _eventController =
      StreamController<VoiceEvent>.broadcast();

  bool _isListening = false;
  bool _isSpeaking = false;

  // ---------------------------------------------------------------------------
  // VoiceProvider capabilities
  // ---------------------------------------------------------------------------

  @override
  bool get isListening => _isListening;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Stream<VoiceEvent> get conversationEvents => _eventController.stream;

  // ---------------------------------------------------------------------------
  // Transcription (speech-to-text)
  // ---------------------------------------------------------------------------

  @override
  Future<String> transcribe(Uint8List audio) async {
    try {
      _isListening = true;

      final uri = Uri.parse('${config.baseUrl}/api/ai/voice/transcribe');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer ${accessTokenProvider()}',
        if (config.organizationId != null)
          'X-Organization-ID': config.organizationId!,
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audio,
          filename: 'recording.wav',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception(
          'Transcription failed (${response.statusCode}): ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final text = json['text'] as String? ?? json['transcript'] as String? ?? '';

      _eventController.add(VoiceTranscript(text));
      return text;
    } finally {
      _isListening = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Synthesis (text-to-speech)
  // ---------------------------------------------------------------------------

  @override
  Future<Uint8List> synthesize(String text) async {
    try {
      _isSpeaking = true;

      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/ai/tts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/octet-stream',
          'Authorization': 'Bearer ${accessTokenProvider()}',
          if (config.organizationId != null)
            'X-Organization-ID': config.organizationId!,
        },
        body: jsonEncode({
          'text': text,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'TTS synthesis failed (${response.statusCode}): ${response.body}',
        );
      }

      final audioBytes = Uint8List.fromList(response.bodyBytes);
      _eventController.add(VoiceAudio(audioBytes));
      return audioBytes;
    } finally {
      _isSpeaking = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Conversation mode (not supported by CMMD)
  // ---------------------------------------------------------------------------

  @override
  Future<void> startConversation() async {
    // CMMD does not support real-time continuous voice conversation mode.
    // Use transcribe() + synthesize() for push-to-talk workflows instead.
    _eventController.add(
      const VoiceError('Continuous voice conversation is not supported by CMMD. '
          'Use push-to-talk mode instead.'),
    );
  }

  @override
  Future<void> stopConversation() async {
    _isListening = false;
    _isSpeaking = false;
    _eventController.add(const VoiceConversationDone());
  }
}
