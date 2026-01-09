import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

import '../config/secrets.dart';

/// Service for Text-to-Speech using ElevenLabs API
///
/// Features:
/// - High-quality TTS with natural Spanish voices
/// - Message queue to avoid interruptions
/// - Fallback to Android TTS if API fails (TODO: implement fallback)
class ElevenLabsService {
  static const String _baseUrl = 'https://api.elevenlabs.io';

  /// Audio player for TTS playback
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Queue of pending TTS messages
  final List<String> _messageQueue = [];

  /// Whether a message is currently being spoken
  bool _isSpeaking = false;

  /// Whether the service is initialized
  bool _isInitialized = false;

  /// Initializes the TTS service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log(
        'Initializing ElevenLabs TTS service',
        name: 'ElevenLabsService',
      );

      // Setup audio player
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);

      // Listen for completion events
      _audioPlayer.onPlayerComplete.listen((_) {
        _onSpeakComplete();
      });

      _isInitialized = true;

      developer.log(
        'ElevenLabs TTS service initialized',
        name: 'ElevenLabsService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to initialize ElevenLabs service',
        name: 'ElevenLabsService',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - service can still work without initialization
    }
  }

  /// Speaks the given text using ElevenLabs TTS
  ///
  /// Adds message to queue if already speaking
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    developer.log(
      'Speak request: $text',
      name: 'ElevenLabsService',
    );

    // Add to queue
    _messageQueue.add(text);

    // Process queue if not already speaking
    if (!_isSpeaking) {
      await _processQueue();
    }
  }

  /// Processes the message queue
  Future<void> _processQueue() async {
    while (_messageQueue.isNotEmpty) {
      _isSpeaking = true;

      final message = _messageQueue.removeAt(0);

      try {
        await _speakText(message);
      } catch (e) {
        developer.log(
          'Failed to speak text: $message',
          name: 'ElevenLabsService',
          error: e,
        );
        // Continue with next message
      }

      // Wait a bit between messages
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _isSpeaking = false;
  }

  /// Speaks a single text message using ElevenLabs API
  Future<void> _speakText(String text) async {
    try {
      developer.log(
        'Synthesizing speech for: $text',
        name: 'ElevenLabsService',
      );

      // Call ElevenLabs TTS API
      final audioBytes = await _synthesizeSpeech(text);

      if (audioBytes == null) {
        developer.log(
          'Failed to synthesize speech',
          name: 'ElevenLabsService',
        );
        return;
      }

      // Save audio to temporary file
      final tempFile = await _saveTempAudio(audioBytes);

      // Play audio
      await _audioPlayer.play(DeviceFileSource(tempFile.path));

      // Wait for playback to complete
      await _waitForPlayback();

      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (e) {
        // Ignore cleanup errors
      }

      developer.log(
        'Speech synthesis completed',
        name: 'ElevenLabsService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to speak text',
        name: 'ElevenLabsService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Calls ElevenLabs API to synthesize speech
  Future<List<int>?> _synthesizeSpeech(String text) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/v1/text-to-speech/${Secrets.elevenLabsVoiceId}',
      );

      developer.log(
        'Calling ElevenLabs API',
        name: 'ElevenLabsService',
      );

      final response = await http.post(
        url,
        headers: {
          'Accept': 'audio/mpeg',
          'Content-Type': 'application/json',
          'xi-api-key': Secrets.elevenLabsApiKey,
        },
        body: json.encode({
          'text': text,
          'model_id': 'eleven_multilingual_v2',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
            'style': 0.0,
            'use_speaker_boost': true,
          },
        }),
      );

      if (response.statusCode == 200) {
        developer.log(
          'Speech synthesized successfully',
          name: 'ElevenLabsService',
        );
        return response.bodyBytes;
      } else {
        developer.log(
          'ElevenLabs API error: ${response.statusCode} - ${response.body}',
          name: 'ElevenLabsService',
        );
        return null;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to call ElevenLabs API',
        name: 'ElevenLabsService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Saves audio bytes to a temporary file
  Future<File> _saveTempAudio(List<int> audioBytes) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File(
      '${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
    );

    await tempFile.writeAsBytes(audioBytes);

    return tempFile;
  }

  /// Waits for audio playback to complete
  Future<void> _waitForPlayback() async {
    final completer = Completer<void>();

    StreamSubscription? subscription;
    subscription = _audioPlayer.onPlayerComplete.listen((_) {
      subscription?.cancel();
      completer.complete();
    });

    // Timeout after 30 seconds
    await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        subscription?.cancel();
        _audioPlayer.stop();
      },
    );
  }

  /// Called when speech playback completes
  void _onSpeakComplete() {
    developer.log(
      'Speech playback completed',
      name: 'ElevenLabsService',
    );
  }

  /// Stops current speech
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _messageQueue.clear();
      _isSpeaking = false;

      developer.log(
        'Speech stopped',
        name: 'ElevenLabsService',
      );
    } catch (e) {
      developer.log(
        'Failed to stop speech',
        name: 'ElevenLabsService',
        error: e,
      );
    }
  }

  /// Disposes the service
  Future<void> dispose() async {
    try {
      await stop();
      await _audioPlayer.dispose();

      developer.log(
        'ElevenLabsService disposed',
        name: 'ElevenLabsService',
      );
    } catch (e) {
      developer.log(
        'Error disposing ElevenLabsService',
        name: 'ElevenLabsService',
        error: e,
      );
    }
  }
}
