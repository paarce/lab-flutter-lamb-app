import 'package:flutter/foundation.dart';

/// Interfaz abstracta para servicios de Text-to-Speech (TTS)
///
/// Define el contrato que todos los proveedores de TTS deben cumplir.
/// Soporta múltiples implementaciones: flutter_tts, Google Cloud, Azure, etc.
abstract class TTSService {
  /// Reproduce el texto en voz alta
  ///
  /// Parámetros:
  /// - [text]: Texto a reproducir
  /// - [onStart]: Callback cuando empieza la reproducción
  /// - [onComplete]: Callback cuando termina la reproducción
  /// - [onError]: Callback en caso de error, recibe mensaje de error
  Future<void> speak(
    String text, {
    VoidCallback? onStart,
    VoidCallback? onComplete,
    Function(String)? onError,
  });

  /// Detiene la reproducción actual
  Future<void> stop();

  /// Pausa la reproducción actual
  Future<void> pause();

  /// Reanuda la reproducción pausada
  Future<void> resume();

  /// Obtiene el volumen actual (0.0 - 1.0)
  double get volume;

  /// Establece el volumen (0.0 - 1.0)
  Future<void> setVolume(double volume);

  /// Incrementa el volumen
  ///
  /// [step] Cantidad a incrementar (default: 0.1 = 10%)
  Future<void> increaseVolume({double step = 0.1});

  /// Decrementa el volumen
  ///
  /// [step] Cantidad a decrementar (default: 0.1 = 10%)
  Future<void> decreaseVolume({double step = 0.1});

  /// Indica si el TTS está actualmente hablando
  ///
  /// Útil para:
  /// - Ignorar toques accidentales mientras se reproduce audio
  /// - Coordinar acciones que dependen de que termine el TTS
  bool get isSpeaking;
}
