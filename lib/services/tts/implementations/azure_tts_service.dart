import 'package:flutter/foundation.dart';
import '../tts_service.dart';

/// Implementación de TTSService usando Azure Cognitive Services Text-to-Speech
/// 
/// ESTADO: Skeleton (no implementado aún)
/// 
/// Características planeadas:
/// - Voces naturales con soporte SSML
/// - Estilos expresivos (alegre, triste, etc)
/// - Múltiples idiomas
/// - Requiere API key y conexión a internet
/// 
/// Costo: Similar a Google Cloud TTS (~$15-20 por 1M caracteres)
class AzureTtsService extends TTSService {
  final String apiKey;
  final String region;

  /// Constructor por defecto
  AzureTtsService({
    this.apiKey = '',
    this.region = '',
  });

  @override
  Future<void> speak(
    String text, {
    VoidCallback? onStart,
    VoidCallback? onComplete,
    Function(String)? onError,
  }) async {
    // TODO: Implementar integración con Azure Cognitive Services TTS API
    throw UnimplementedError(
      'AzureTtsService aún no está implementado. '
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
