import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/secrets.dart';

/// Service for Speech-to-Text (STT) using ElevenLabs Scribe v2 API
///
/// Características:
/// - Ultra-baja latencia (150ms) para comandos de voz en tiempo real
/// - Soporte para 90+ idiomas incluido español
/// - Precisión excelente para usuario adulto mayor
/// - WebSocket para streaming realtime
///
/// NOTA: Para Text-to-Speech (TTS), usa TTSFactory en lugar de este servicio.
/// Esto mantiene separadas las responsabilidades: ElevenLabs para STT, flutter_tts para TTS.
class ElevenLabsService {
  static const String _baseUrl = 'wss://api.elevenlabs.io/v1/speech-to-text';

  WebSocketChannel? _channel;
  bool _isListening = false;
  late StreamSubscription? _subscription;

  /// Inicia grabación y reconocimiento de voz en tiempo real
  ///
  /// Retorna un Stream que emite fragmentos de texto conforme se reconoce
  /// Debe ser escuchado continuamente hasta que se llame [stopListening]
  Stream<String> startListening() async* {
    if (_isListening) {
      developer.log(
        'Ya hay un reconocimiento activo',
        name: 'ElevenLabsService',
      );
      return;
    }

    try {
      _isListening = true;

      developer.log(
        'Iniciando reconocimiento de voz con ElevenLabs Scribe',
        name: 'ElevenLabsService',
      );

      // Conectar a WebSocket de ElevenLabs
      _channel = WebSocketChannel.connect(
        Uri.parse('$_baseUrl/realtime?api_key=${Secrets.elevenLabsApiKey}'),
      );

      // Escuchar mensajes del servidor
      yield* _channel!.stream.map<String>((dynamic message) {
        try {
          final data = json.decode(message as String);

          // ElevenLabs Scribe envía fragmentos bajo "transcript" o "text"
          final transcript = data['transcript'] ?? data['text'] ?? '';

          if (transcript.isNotEmpty) {
            developer.log(
              'STT reconocido: $transcript',
              name: 'ElevenLabsService',
            );
          }

          return transcript;
        } catch (e) {
          developer.log(
            'Error parseando respuesta STT',
            name: 'ElevenLabsService',
            error: e,
          );
          return '';
        }
      });
    } catch (e, stackTrace) {
      _isListening = false;

      developer.log(
        'Error iniciando reconocimiento de voz',
        name: 'ElevenLabsService',
        error: e,
        stackTrace: stackTrace,
      );

      yield ''; // Emitir vacío para señalar error
    }
  }

  /// Detiene el reconocimiento de voz activo
  Future<void> stopListening() async {
    try {
      _isListening = false;
      await _subscription?.cancel();
      await _channel?.sink.close();

      developer.log(
        'Reconocimiento de voz detenido',
        name: 'ElevenLabsService',
      );
    } catch (e) {
      developer.log(
        'Error deteniendo reconocimiento',
        name: 'ElevenLabsService',
        error: e,
      );
    }
  }

  /// Limpia recursos
  Future<void> dispose() async {
    await stopListening();

    developer.log(
      'ElevenLabsService dispuesto',
      name: 'ElevenLabsService',
    );
  }
}
