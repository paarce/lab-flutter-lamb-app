import 'tts_service.dart';
import 'implementations/flutter_tts_service.dart';
import '../../config/secrets.dart';

/// Factory para crear y gestionar instancia singleton de TTSService
///
/// Usa el patrón Singleton para garantizar una única instancia del servicio TTS.
/// Actualmente solo soporta flutter_tts (motor nativo).
class TTSFactory {
  static TTSService? _instance;

  /// Obtiene la instancia singleton del servicio TTS
  ///
  /// Retorna la instancia de FlutterTtsService (motor nativo).
  static TTSService getInstance() {
    _instance ??= _createService();
    return _instance!;
  }

  /// Crea una nueva instancia del servicio TTS
  static TTSService _createService() {
    // Actualmente solo flutter_tts está implementado
    return FlutterTtsService();
  }

  /// Reinicia la instancia singleton (útil para testing)
  /// 
  /// NOTA: Solo usar en contextos de testing o si necesitas cambiar de proveedor en runtime
  static void reset() {
    _instance = null;
  }
}
