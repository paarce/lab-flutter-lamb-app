import 'package:flutter/foundation.dart';
import '../tts_service.dart';

/// Implementación de TTSService usando Google Cloud Text-to-Speech API
/// 
/// ESTADO: Skeleton (no implementado aún)
/// 
/// Características planeadas:
/// - Voces naturales de alta calidad
/// - Soporte para múltiples idiomas
/// - Opciones avanzadas (SSML, gender, edad)
/// - Requiere API key y conexión a internet
/// 
/// Costo: ~$16 por 1 millón de caracteres
class GoogleCloudTtsService extends TTSService {
  final String apiKey;

  /// Constructor por defecto
  GoogleCloudTtsService({
    this.apiKey = '',
  });

  @override
  Future<void> speak(
    String text, {
    VoidCallback? onStart,
    VoidCallback? onComplete,
    Function(String)? onError,
  }) async {
    // TODO: Implementar integración con Google Cloud TTS API
    throw UnimplementedError(
      'GoogleCloudTtsService aún no está implementado. '
      'Usa flutter_tts como fallback.',
    );
  }

  @override
  Future<void> stop() async {
    // TODO: Implementar
  }

  @override
  Future<void> pause() async {
    // TODO: Implementar
  }

  @override
  Future<void> resume() async {
    // TODO: Implementar
  }
}
