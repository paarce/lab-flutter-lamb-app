import '../errors/app_error.dart';
import '../errors/error_category.dart';
import '../errors/error_codes.dart';

/// Mensajes accesibles para usuarios (español, simple, para TTS)
///
/// Diseñado para personas 60+ con baja visión:
/// - Frases cortas (máx 20 palabras)
/// - Lenguaje simple y directo
/// - Sin jerga técnica
/// - Instrucciones claras de acción
class ErrorMessages {
  static String getUserMessage(AppError error) {
    // Primero, si ya tiene mensaje personalizado, úsalo
    if (error.userMessage.isNotEmpty) {
      return error.userMessage;
    }

    // Si no, genera basado en categoría y código
    switch (error.category) {
      case ErrorCategory.platformChannel:
        return _platformChannelMessage(error.code);
      case ErrorCategory.firebase:
        return _firebaseMessage(error.code);
      case ErrorCategory.elevenLabs:
        return _elevenLabsMessage(error.code);
      case ErrorCategory.webRTC:
        return _webRTCMessage(error.code);
      case ErrorCategory.llm:
        return _llmMessage(error.code);
      case ErrorCategory.network:
        return _networkMessage(error.code);
      case ErrorCategory.unknown:
        return 'Ha ocurrido un problema. Intenta de nuevo o cierra la app.';
    }
  }

  static String _platformChannelMessage(String code) {
    switch (code) {
      case ErrorCodes.pcPermissionDenied:
        return 'Se necesitan permisos. Ve a Configuración y activa Accesibilidad.';
      case ErrorCodes.pcAccessibilityServiceInactive:
        return 'El servicio de Accesibilidad no está activado. '
            'Necesitas activarlo en Configuración para continuar.';
      case ErrorCodes.pcNativeException:
        return 'Error del sistema. Cierra y abre la app de nuevo.';
      case ErrorCodes.pcMethodNotImplemented:
        return 'Esta función no está disponible en tu dispositivo.';
      default:
        return 'Error del sistema. Intenta de nuevo.';
    }
  }

  static String _firebaseMessage(String code) {
    switch (code) {
      case ErrorCodes.fbNetworkError:
        return 'Sin conexión a internet. Verifica tu WiFi o datos móviles.';
      case ErrorCodes.fbAuthExpired:
        return 'Tu sesión expiró. Cierra y abre la app para conectarte de nuevo.';
      case ErrorCodes.fbFirestoreFailed:
        return 'No pudimos conectar con el servidor. Intenta de nuevo en unos momentos.';
      case ErrorCodes.fbNotConnected:
        return 'La app no está conectada. Verifica internet.';
      default:
        return 'Error al sincronizar datos. Intenta de nuevo.';
    }
  }

  static String _elevenLabsMessage(String code) {
    switch (code) {
      case ErrorCodes.elApiKeyInvalid:
        return 'Error de configuración de audio. Contacta con soporte.';
      case ErrorCodes.elRateLimitExceeded:
        return 'Estamos procesando demasiadas solicitudes. '
            'Espera un momento e intenta de nuevo.';
      case ErrorCodes.elInvalidAudio:
        return 'No entendí lo que dijiste. Intenta de nuevo con más claridad.';
      case ErrorCodes.elVoiceNotFound:
        return 'No encontramos la voz configurada. Ve a Configuración.';
      case ErrorCodes.elNetworkFailed:
        return 'No pudimos conectar con el servicio de audio. Intenta de nuevo.';
      default:
        return 'Error de audio. Intenta de nuevo.';
    }
  }

  static String _webRTCMessage(String code) {
    switch (code) {
      case ErrorCodes.wrtcConnectionFailed:
        return 'No pudimos conectar con el otro dispositivo. '
            'Verifica que está cerca y ambos tienen internet.';
      case ErrorCodes.wrtcPeerNotFound:
        return 'El otro dispositivo no está disponible. Intenta de nuevo.';
      case ErrorCodes.wrtcIceTimeout:
        return 'La conexión tardó demasiado. Intenta de nuevo.';
      case ErrorCodes.wrtcMediaPermissionDenied:
        return 'Se necesitan permisos de cámara o micrófono. '
            'Ve a Configuración y actívalos.';
      default:
        return 'Error en la conexión remota. Intenta de nuevo.';
    }
  }

  static String _networkMessage(String code) {
    switch (code) {
      case ErrorCodes.netNoInternet:
        return 'No tienes conexión a internet. Verifica WiFi o datos móviles.';
      case ErrorCodes.netTimeout:
        return 'La conexión es lenta. Intenta de nuevo en unos momentos.';
      case ErrorCodes.netConnectionUnstable:
        return 'Tu conexión es inestable. Intenta de nuevo cuando mejore.';
      default:
        return 'Error de conexión. Intenta de nuevo.';
    }
  }

  static String _llmMessage(String code) {
    switch (code) {
      case ErrorCodes.llmApiKeyInvalid:
        return 'Error de configuración del asistente. Contacta con soporte.';
      case ErrorCodes.llmRateLimitExceeded:
        return 'El asistente está ocupado. Intenta con un comando más simple.';
      case ErrorCodes.llmTimeout:
        return 'El asistente tardó demasiado. Intenta de nuevo.';
      case ErrorCodes.llmParseError:
        return 'No entendí el comando. Intenta de nuevo con otras palabras.';
      default:
        return 'Error del asistente de voz. Intenta de nuevo.';
    }
  }

  /// Botón "Reintentar" - texto accesible
  static const String retryButtonText = 'Reintentar';

  /// Botón "Cerrar" - texto accesible
  static const String closeButtonText = 'Cerrar';

  /// Título del diálogo - accesible y simple
  static const String dialogTitle = 'Ha ocurrido un problema';
}
