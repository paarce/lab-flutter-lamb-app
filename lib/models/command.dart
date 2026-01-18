/// Tipos de comandos de voz soportados
enum CommandType {
  /// "solicitar ayuda" → Genera código sesión remota
  requestHelp,

  /// "abrir WhatsApp" → Abre WhatsApp
  openWhatsApp,

  /// "alto contraste" → Cambia tema
  toggleContrast,

  /// "cancelar" → Detiene listening
  cancel,

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
