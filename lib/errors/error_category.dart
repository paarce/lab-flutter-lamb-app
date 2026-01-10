/// Categorías de errores en orden de criticidad
///
/// Orden refleja prioridad de manejo:
/// 1. Platform Channel → Afecta características nativas críticas
/// 2. Firebase → Sincronización de datos
/// 3. ElevenLabs → Comunicación de audio
/// 4. WebRTC → Control remoto
/// 5. Network → Conectividad general
enum ErrorCategory {
  platformChannel, // Kotlin/Android errors
  firebase, // Firestore/Authentication
  elevenLabs, // STT/TTS API
  webRTC, // Remote control
  network, // Internet connectivity
  unknown, // No clasificado
}

extension ErrorCategoryX on ErrorCategory {
  /// Nombre legible para logging
  String get displayName {
    switch (this) {
      case ErrorCategory.platformChannel:
        return 'Error del Sistema';
      case ErrorCategory.firebase:
        return 'Error de Sincronización';
      case ErrorCategory.elevenLabs:
        return 'Error de Audio';
      case ErrorCategory.webRTC:
        return 'Error de Conexión Remota';
      case ErrorCategory.network:
        return 'Error de Conexión';
      case ErrorCategory.unknown:
        return 'Error Desconocido';
    }
  }

  /// ¿Es crítico? (detiene la app o flujo importante)
  bool get isCritical {
    return this == ErrorCategory.platformChannel ||
        this == ErrorCategory.firebase;
  }
}
