/// Tipos de comandos de voz soportados
enum CommandType {
  /// "solicitar ayuda" → Muestra tutorial/lista de comandos
  requestHelp,

  /// "compartir pantalla" → Abre control remoto (compartir pantalla)
  shareScreen,

  /// "abrir WhatsApp" → Abre WhatsApp
  openWhatsApp,

  /// "alto contraste" → Cambia tema
  toggleContrast,

  /// "subir volumen" → Incrementa volumen TTS
  adjustVolumeUp,

  /// "bajar volumen" → Decrementa volumen TTS
  adjustVolumeDown,

  /// "volumen al máximo" → Establece volumen TTS a 100%
  setVolumeMax,

  /// "volumen al mínimo" / "silencio" → Establece volumen TTS a 0%
  setVolumeMin,

  /// "volumen al X%" → Establece volumen TTS a porcentaje específico
  setVolumePercentage,

  /// "tutorial" → Reproduce guía de uso de la app
  playTutorial,

  /// "comandos disponibles" → Lista comandos por TTS
  listCommands,

  /// "cancelar" → Detiene listening
  cancel,

  // Sistema (3 comandos nuevos)

  /// "qué hora es" → Obtiene hora actual
  getTime,

  /// "qué día es hoy" → Obtiene fecha actual
  getDate,

  /// "cuánta batería tengo" → Obtiene nivel de batería
  getBatteryLevel,

  // Social (2 comandos limitados)

  /// "gracias" → Respuesta a agradecimiento
  thankYou,

  /// "adiós" → Respuesta a despedida
  goodbye,

  // Rechazo de conversaciones

  /// Saludo sin objetivo claro
  conversationRejected,

  /// No reconocido
  unknown,
}

/// Comando de voz reconocido con metadata
class VoiceCommand {
  /// Tipo de comando identificado
  final CommandType type;

  /// Texto original reconocido por STT
  final String originalText;

  /// Momento en que se reconoció el comando
  final DateTime timestamp;

  /// Parámetros opcionales del comando (para comandos con argumentos)
  final Map<String, dynamic>? parameters;

  const VoiceCommand({
    required this.type,
    required this.originalText,
    required this.timestamp,
    this.parameters,
  });

  /// Crea un comando con timestamp actual
  factory VoiceCommand.now({
    required CommandType type,
    required String originalText,
    Map<String, dynamic>? parameters,
  }) {
    return VoiceCommand(
      type: type,
      originalText: originalText,
      timestamp: DateTime.now(),
      parameters: parameters,
    );
  }

  @override
  String toString() {
    return 'VoiceCommand(type: $type, text: "$originalText", timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VoiceCommand &&
        other.type == type &&
        other.originalText == originalText;
  }

  @override
  int get hashCode => type.hashCode ^ originalText.hashCode;
}
