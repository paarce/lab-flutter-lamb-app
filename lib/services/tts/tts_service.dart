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
}
