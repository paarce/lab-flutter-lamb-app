import 'tts_service.dart';
import 'implementations/flutter_tts_service.dart';
import 'implementations/google_cloud_tts_service.dart';
import 'implementations/azure_tts_service.dart';
import '../../config/secrets.dart';

/// Factory para crear y gestionar instancia singleton de TTSService
/// 
/// Usa el patrón Singleton para garantizar una única instancia del servicio TTS.
/// El proveedor se selecciona desde [Secrets.ttsProvider].
class TTSFactory {
  static TTSService? _instance;

  /// Obtiene la instancia singleton del servicio TTS
  /// 
  /// Si no existe, la crea según el proveedor configurado en [Secrets.ttsProvider].
  /// En caso de proveedor desconocido, usa flutter_tts como fallback.
  static TTSService getInstance() {
    _instance ??= _createService();
    return _instance!;
  }

  /// Crea una nueva instancia del servicio TTS según el proveedor configurado
  static TTSService _createService() {
    final provider = Secrets.ttsProvider;

    switch (provider) {
      case 'flutter_tts':
        return FlutterTtsService();
      case 'google_cloud':
        return GoogleCloudTtsService(apiKey: '');
      case 'azure':
        return AzureTtsService(apiKey: '', region: '');
      default:
        // Fallback a flutter_tts si el proveedor no es reconocido
        return FlutterTtsService();
    }
  }

  /// Reinicia la instancia singleton (útil para testing)
  /// 
  /// NOTA: Solo usar en contextos de testing o si necesitas cambiar de proveedor en runtime
  static void reset() {
    _instance = null;
  }
}
