/// Configuración global para servicios de TTS
/// 
/// Define parámetros genéricos que aplican a todos los proveedores de TTS.
/// Parámetros específicos del proveedor se configuran internamente en cada implementación.
class TTSConfig {
  /// Idioma para la síntesis de voz (formato: es-ES, en-US, etc)
  static const String language = 'es-ES';

  /// Tono de voz (rango típico: 0.5 - 2.0, donde 1.0 es normal)
  static const double pitch = 1.0;

  /// Velocidad de reproducción (rango típico: 0.5 - 2.0, donde 1.0 es normal)
  static const double speed = 1.0;

  /// Volumen de reproducción (rango: 0.0 - 1.0, donde 1.0 es máximo)
  static const double volume = 1.0;
}
