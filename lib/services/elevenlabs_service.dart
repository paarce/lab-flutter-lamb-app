import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:mic_stream/mic_stream.dart';
import 'package:web_socket_channel/io.dart';
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
  StreamSubscription? _subscription;

  // Stream de audio del micrófono
  Stream<Uint8List>? _micStream;
  StreamSubscription<Uint8List>? _audioSubscription;

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

      developer.log('Starting ElevenLabs Scribe connection', name: 'ElevenLabsService');

      // Conectar a WebSocket de ElevenLabs con autenticación correcta
      // Según docs: https://elevenlabs.io/docs/api-reference/speech-to-text/v-1-speech-to-text-realtime
      // Autenticación: Header 'xi-api-key' (NO query param)
      final wsUrl = Uri.parse('$_baseUrl/realtime?language_code=es');

      // Usar IOWebSocketChannel para agregar header de autenticación
      final socket = await WebSocket.connect(
        wsUrl.toString(),
        headers: {
          'xi-api-key': Secrets.elevenLabsApiKey,
        },
      );

      _channel = IOWebSocketChannel(socket);

      developer.log('WebSocket connected', name: 'ElevenLabsService');

      // Listener de errores del WebSocket
      socket.done.then((_) {
        developer.log('WebSocket closed by server', name: 'ElevenLabsService');
      }).catchError((error) {
        developer.log(
          'WebSocket error',
          name: 'ElevenLabsService',
          error: error,
        );
      });

      try {
        _micStream = await MicStream.microphone(
          sampleRate: 16000, // ElevenLabs requiere 16kHz
          channelConfig: ChannelConfig.CHANNEL_IN_MONO,
          audioFormat: AudioFormat.ENCODING_PCM_16BIT,
        );

        developer.log('Microphone started', name: 'ElevenLabsService');

        // Enviar chunks de audio al WebSocket
        _audioSubscription = _micStream!.listen(
          (Uint8List audioChunk) {
            if (_channel != null) {
              // Convertir a little-endian (requerido por ElevenLabs)
              // PCM 16-bit: cada 2 bytes = 1 sample
              final convertedAudio = _convertToLittleEndian(audioChunk);

              // ElevenLabs requiere JSON con audio en Base64
              try {
                final audioBase64 = base64Encode(convertedAudio);
                final messageMap = {
                  'message_type': 'input_audio_chunk',
                  'audio_base_64': audioBase64,
                  'commit': false,
                  'sample_rate': 16000,
                };

                final message = json.encode(messageMap);

                // ENVIAR al WebSocket
                _channel!.sink.add(message);
              } catch (sendError) {
                developer.log(
                  'Error sending audio chunk',
                  name: 'ElevenLabsService',
                  error: sendError,
                );
              }
            }
          },
          onError: (error) {
            developer.log(
              'Audio stream error',
              name: 'ElevenLabsService',
              error: error,
            );
          },
          onDone: () {
            developer.log('Audio stream ended', name: 'ElevenLabsService');
          },
        );
      } catch (micError) {
        developer.log(
          'Failed to start microphone',
          name: 'ElevenLabsService',
          error: micError,
        );
        throw Exception('No se pudo iniciar el micrófono: $micError');
      }

      // Escuchar mensajes del servidor (transcripciones)
      yield* _channel!.stream.map<String>((dynamic message) {
        try {
          final data = json.decode(message as String);

          // Verificar si hay errores
          if (data['error'] != null) {
            developer.log(
              'ElevenLabs error: ${data['error']}',
              name: 'ElevenLabsService',
            );
          }

          // ElevenLabs Scribe envía fragmentos bajo "transcript" o "text"
          final transcript = data['transcript'] ?? data['text'] ?? '';

          if (transcript.isNotEmpty) {
            developer.log('Transcription: "$transcript"', name: 'ElevenLabsService');
          }

          return transcript;
        } catch (e) {
          developer.log(
            'Error parsing message',
            name: 'ElevenLabsService',
            error: e,
          );
          return '';
        }
      });
    } catch (e, stackTrace) {
      _isListening = false;

      developer.log(
        'Failed to start voice recognition',
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

      // Detener stream de audio del micrófono
      await _audioSubscription?.cancel();
      _audioSubscription = null;
      _micStream = null;

      developer.log('Microphone stopped', name: 'ElevenLabsService');

      // Enviar mensaje de commit para obtener transcripción final
      if (_channel != null) {
        try {
          final commitMessageMap = {
            'message_type': 'input_audio_chunk',
            'audio_base_64': '',
            'commit': true,
            'sample_rate': 16000,
          };

          final commitMessage = json.encode(commitMessageMap);

          _channel!.sink.add(commitMessage);

          developer.log('Commit sent, waiting for final transcription', name: 'ElevenLabsService');

          // ⚠️ NO CERRAR EL WEBSOCKET AQUÍ
          // El stream sigue escuchando y recibirá la transcripción
          // Se cerrará automáticamente cuando el provider cancele la suscripción
        } catch (commitError) {
          developer.log(
            'Error sending commit',
            name: 'ElevenLabsService',
            error: commitError,
          );
        }
      }
    } catch (e) {
      developer.log(
        'Error stopping listening',
        name: 'ElevenLabsService',
        error: e,
      );
    }
  }

  /// Verifica si el audio contiene actividad (no es silencio)
  ///
  /// Calcula el nivel promedio de amplitud del chunk.
  /// PCM 16-bit: valores entre -32768 y 32767
  /// Silencio absoluto: todos los bytes son 0
  bool _hasAudioActivity(Uint8List audioChunk) {
    if (audioChunk.isEmpty) return false;

    // Calcular valor absoluto promedio de los bytes
    int sum = 0;
    for (final byte in audioChunk) {
      sum += byte.abs();
    }

    final average = sum / audioChunk.length;

    // Si el promedio es muy bajo, es probablemente silencio
    // Umbral arbitrario: 10 (en escala de 0-255)
    return average > 10;
  }

  /// Prepara bytes de audio para ElevenLabs
  ///
  /// ElevenLabs requiere PCM 16-bit en little-endian (formato nativo de Android).
  /// Esta función asegura que el tamaño sea par (múltiplo de 2 bytes).
  ///
  /// Para PCM 16-bit: cada 2 bytes forman un sample
  Uint8List _convertToLittleEndian(Uint8List input) {
    // Si el tamaño es impar, truncar al byte par más cercano
    // PCM 16-bit requiere múltiplos de 2 bytes
    final length = (input.length ~/ 2) * 2;

    if (length == input.length) {
      // Ya es par, usar directamente
      return input;
    } else {
      // Truncar último byte impar
      return Uint8List.sublistView(input, 0, length);
    }

    // NOTA: Android AudioRecord normalmente ya entrega en little-endian
    // Si aún hay errores de decodificación, descomentar el código below para invertir bytes:

    // final output = Uint8List(length);
    // for (int i = 0; i < length; i += 2) {
    //   output[i] = input[i + 1];     // Intercambiar byte order
    //   output[i + 1] = input[i];
    // }
    // return output;
  }

  /// Limpia recursos
  Future<void> dispose() async {
    developer.log('Disposing resources', name: 'ElevenLabsService');

    // Detener audio
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    _micStream = null;

    // Cerrar WebSocket
    await _channel?.sink.close();
    _channel = null;

    _isListening = false;

    developer.log('Resources disposed', name: 'ElevenLabsService');
  }
}
