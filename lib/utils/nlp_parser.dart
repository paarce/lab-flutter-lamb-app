import 'package:lamb/models/command.dart';

/// Parser simple de lenguaje natural basado en keywords
///
/// Reconoce comandos de voz usando coincidencia de palabras clave.
/// Prioridad: cancel > comandos específicos > unknown
class NLPParser {
  // Keywords para cada tipo de comando
  static const _helpKeywords = [
    'ayuda',
    'solicitar ayuda',
    'necesito ayuda',
    'ayúdame',
    'auxilio',
  ];

  static const _whatsappKeywords = [
    'whatsapp',
    'abrir whatsapp',
    'abre whatsapp',
    'abrime whatsapp',
    'whats',
  ];

  static const _contrastKeywords = [
    'contraste',
    'alto contraste',
    'activar contraste',
    'cambiar contraste',
  ];

  static const _cancelKeywords = [
    'cancelar',
    'detener',
    'para',
    'parar',
    'cancela',
  ];

  static const _volumeUpKeywords = [
    'subir volumen',
    'sube volumen',
    'aumentar volumen',
    'aumenta volumen',
    'aumentar el volumen',
    'aumenta el volumen',
    'más volumen',
    'volumen arriba',
    'subir el volumen',
    'sube el volumen',
    'sube más el volumen',
    'subir más el volumen',
  ];

  static const _volumeDownKeywords = [
    'bajar volumen',
    'baja volumen',
    'disminuir volumen',
    'disminuye volumen',
    'disminuir el volumen',
    'disminuye el volumen',
    'menos volumen',
    'volumen abajo',
    'bajar el volumen',
    'baja el volumen',
    'baja más el volumen',
    'bajar más el volumen',
  ];

  static const _volumeMaxKeywords = [
    'volumen al máximo',
    'volumen máximo',
    'pon el volumen al máximo',
    'pon volumen al máximo',
    'sube el volumen al máximo',
    'volumen alto',
    'máximo volumen',
    'volumen completo',
  ];

  static const _volumeMinKeywords = [
    'volumen al mínimo',
    'volumen mínimo',
    'pon el volumen al mínimo',
    'pon volumen al mínimo',
    'silencio',
    'silenciar',
    'pon en silencio',
    'volumen cero',
    'sin volumen',
    'quitar volumen',
  ];

  /// Parsea texto reconocido por STT y retorna el comando identificado
  ///
  /// [recognizedText] Texto transcrito por el servicio de STT
  ///
  /// Retorna [VoiceCommand] con tipo identificado y texto original
  static VoiceCommand parse(String recognizedText) {
    final normalized = recognizedText.toLowerCase().trim();

    // Prioridad 1: Comando cancelar (puede interrumpir otros comandos)
    if (_matchesAny(normalized, _cancelKeywords)) {
      return VoiceCommand.now(
        type: CommandType.cancel,
        originalText: recognizedText,
      );
    }

    // Prioridad 2: Contraste
    if (_matchesAny(normalized, _contrastKeywords)) {
      return VoiceCommand.now(
        type: CommandType.toggleContrast,
        originalText: recognizedText,
      );
    }

    // Prioridad 3: Volumen (NUEVO)
    // Sub-prioridad 3a: Comandos absolutos (máximo/mínimo antes que incrementales)
    if (_matchesAny(normalized, _volumeMaxKeywords)) {
      return VoiceCommand.now(
        type: CommandType.setVolumeMax,
        originalText: recognizedText,
      );
    }
    if (_matchesAny(normalized, _volumeMinKeywords)) {
      return VoiceCommand.now(
        type: CommandType.setVolumeMin,
        originalText: recognizedText,
      );
    }

    // Sub-prioridad 3b: Porcentaje específico (antes que incrementales)
    final percentageMatch = _parseVolumePercentage(normalized);
    if (percentageMatch != null) {
      return VoiceCommand.now(
        type: CommandType.setVolumePercentage,
        originalText: recognizedText,
        parameters: {'percentage': percentageMatch},
      );
    }

    // Sub-prioridad 3c: Comandos incrementales
    if (_matchesAny(normalized, _volumeUpKeywords)) {
      return VoiceCommand.now(
        type: CommandType.adjustVolumeUp,
        originalText: recognizedText,
      );
    }
    if (_matchesAny(normalized, _volumeDownKeywords)) {
      return VoiceCommand.now(
        type: CommandType.adjustVolumeDown,
        originalText: recognizedText,
      );
    }

    // Prioridad 4: Ayuda
    if (_matchesAny(normalized, _helpKeywords)) {
      return VoiceCommand.now(
        type: CommandType.requestHelp,
        originalText: recognizedText,
      );
    }

    // Prioridad 5: WhatsApp
    if (_matchesAny(normalized, _whatsappKeywords)) {
      return VoiceCommand.now(
        type: CommandType.openWhatsApp,
        originalText: recognizedText,
      );
    }

    // Prioridad 6: Comando no reconocido
    return VoiceCommand.now(
      type: CommandType.unknown,
      originalText: recognizedText,
    );
  }

  /// Verifica si el texto contiene alguna de las keywords
  ///
  /// Usa coincidencia parcial (contains) para flexibilidad
  static bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Intenta extraer un porcentaje específico del texto
  ///
  /// Patrones soportados:
  /// - "volumen al 50"
  /// - "pon el volumen al 50"
  /// - "volumen 50 por ciento"
  /// - "volumen en 30"
  /// - "pon volumen 70"
  ///
  /// Returns el porcentaje (0-100) si se encuentra, null si no
  static int? _parseVolumePercentage(String text) {
    // Patrones de regex para detectar porcentajes
    final patterns = [
      // "volumen al 50", "volumen en 50"
      RegExp(r'volumen\s+(?:al|en)\s+(\d+)'),

      // "pon el volumen al 50", "pon volumen en 30"
      RegExp(r'pon\s+(?:el\s+)?volumen\s+(?:al|en)\s+(\d+)'),

      // "volumen 50", "volumen 30 por ciento"
      RegExp(r'volumen\s+(\d+)\s*(?:por\s*ciento)?'),

      // "50 por ciento", "30 porciento"
      RegExp(r'(\d+)\s*por\s*ciento'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final value = int.tryParse(match.group(1)!);

        // Validar rango 0-100
        if (value != null && value >= 0 && value <= 100) {
          return value;
        }
      }
    }

    return null;
  }
}
