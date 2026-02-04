import 'package:flutter/foundation.dart';
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

  static const _shareScreenKeywords = [
    'compartir pantalla',
    'comparte pantalla',
    'compartir mi pantalla',
    'share screen',
    'enseñar pantalla',
    'enseña pantalla',
    'mostrar pantalla',
    'muestra pantalla',
    'control remoto',
    'acceso remoto',
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

  static const _tutorialKeywords = [
    'tutorial',
    'guía',
    'instrucciones',
    'cómo usar',
    'cómo funciona',
    'explícame',
    'enséñame',
  ];

  static const _listCommandsKeywords = [
    'qué puedo decir',
    'comandos disponibles',
    'qué comandos hay',
    'lista de comandos',
    'qué puedo hacer',
    'comandos',
  ];

  // Lista completa de comandos
  static const _listAllCommandsKeywords = [
    'todos los comandos',
    'lista completa',
    'todos',
  ];

  // Categorías de comandos (prefijo "comandos de" para evitar conflictos)
  static const _categoryAssistanceKeywords = [
    'comandos de asistencia',
    'comandos asistencia',
  ];

  static const _categoryWhatsappKeywords = [
    'comandos de whatsapp',
    'comandos whatsapp',
  ];

  static const _categoryVolumeKeywords = [
    'comandos de volumen',
    'comandos volumen',
  ];

  static const _categoryInfoKeywords = [
    'comandos de información',
    'comandos información',
    'comandos de info',
    'comandos info',
  ];

  static const _categorySettingsKeywords = [
    'comandos de ajustes',
    'comandos ajustes',
    'comandos de configuración',
    'comandos configuración',
  ];

  // Sistema (NUEVO)
  static const _timeKeywords = [
    'qué hora es',
    'qué hora',
    'hora',
    'dime la hora',
  ];

  static const _dateKeywords = [
    'qué día es hoy',
    'qué día es',
    'fecha',
    'día de hoy',
    'fecha de hoy',
  ];

  static const _batteryKeywords = [
    'cuánta batería',
    'nivel de batería',
    'batería',
    'pila',
    'cuánta pila',
  ];

  // Social (LIMITADO - NUEVO)
  static const _thankYouKeywords = [
    'gracias',
    'muchas gracias',
    'te agradezco',
  ];

  static const _goodbyeKeywords = [
    'adiós',
    'chau',
    'chao',
    'hasta luego',
    'nos vemos',
  ];

  // Saludos sin objetivo (detectar para rechazar)
  static const _greetingKeywords = [
    'hola',
    'buenos días',
    'buenas tardes',
    'buenas noches',
    'buen día',
  ];

  /// Parsea texto reconocido por STT y retorna el comando identificado
  ///
  /// [recognizedText] Texto transcrito por el servicio de STT
  ///
  /// Retorna [VoiceCommand] con tipo identificado y texto original
  static VoiceCommand parse(String recognizedText) {
    final normalized = recognizedText.toLowerCase().trim();

    // DEBUG: Mostrar texto normalizado
    debugPrint('🔎 [NLPParser] Parsing: "$normalized"');

    // Prioridad 1: Comando cancelar (puede interrumpir otros comandos)
    if (_matchesAny(normalized, _cancelKeywords)) {
      return VoiceCommand.now(
        type: CommandType.cancel,
        originalText: recognizedText,
      );
    }

    // Prioridad 2: Comandos de Sistema (NUEVO)
    if (_matchesAny(normalized, _timeKeywords)) {
      return VoiceCommand.now(
        type: CommandType.getTime,
        originalText: recognizedText,
      );
    }
    if (_matchesAny(normalized, _dateKeywords)) {
      return VoiceCommand.now(
        type: CommandType.getDate,
        originalText: recognizedText,
      );
    }
    if (_matchesAny(normalized, _batteryKeywords)) {
      return VoiceCommand.now(
        type: CommandType.getBatteryLevel,
        originalText: recognizedText,
      );
    }

    // Prioridad 3: Respuestas Sociales (LIMITADO - NUEVO)
    if (_matchesAny(normalized, _thankYouKeywords)) {
      return VoiceCommand.now(
        type: CommandType.thankYou,
        originalText: recognizedText,
      );
    }
    if (_matchesAny(normalized, _goodbyeKeywords)) {
      return VoiceCommand.now(
        type: CommandType.goodbye,
        originalText: recognizedText,
      );
    }

    // Prioridad 4: Contraste
    if (_matchesAny(normalized, _contrastKeywords)) {
      return VoiceCommand.now(
        type: CommandType.toggleContrast,
        originalText: recognizedText,
      );
    }

    // Prioridad 5: Volumen
    // Sub-prioridad 5a: Comandos absolutos (máximo/mínimo antes que incrementales)
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

    // Sub-prioridad 5b: Porcentaje específico (antes que incrementales)
    final percentageMatch = _parseVolumePercentage(normalized);
    if (percentageMatch != null) {
      return VoiceCommand.now(
        type: CommandType.setVolumePercentage,
        originalText: recognizedText,
        parameters: {'percentage': percentageMatch},
      );
    }

    // Sub-prioridad 5c: Comandos incrementales
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

    // Prioridad 6: Tutorial
    if (_matchesAny(normalized, _tutorialKeywords)) {
      return VoiceCommand.now(
        type: CommandType.playTutorial,
        originalText: recognizedText,
      );
    }

    // Prioridad 7: Listar comandos por categoría (antes de listCommands genérico)
    // 7a: Todos los comandos (lista completa)
    if (_matchesAny(normalized, _listAllCommandsKeywords)) {
      return VoiceCommand.now(
        type: CommandType.listAllCommands,
        originalText: recognizedText,
      );
    }

    // 7b: Categorías específicas (antes de "comandos" genérico)
    if (_matchesAny(normalized, _categoryAssistanceKeywords)) {
      return VoiceCommand.now(
        type: CommandType.listCategoryAssistance,
        originalText: recognizedText,
      );
    }
    if (_matchesAny(normalized, _categoryWhatsappKeywords)) {
      return VoiceCommand.now(
        type: CommandType.listCategoryWhatsapp,
        originalText: recognizedText,
      );
    }
    if (_matchesAny(normalized, _categoryVolumeKeywords)) {
      return VoiceCommand.now(
        type: CommandType.listCategoryVolume,
        originalText: recognizedText,
      );
    }
    if (_matchesAny(normalized, _categoryInfoKeywords)) {
      return VoiceCommand.now(
        type: CommandType.listCategoryInfo,
        originalText: recognizedText,
      );
    }
    if (_matchesAny(normalized, _categorySettingsKeywords)) {
      return VoiceCommand.now(
        type: CommandType.listCategorySettings,
        originalText: recognizedText,
      );
    }

    // 7c: Intro de categorías (genérico)
    if (_matchesAny(normalized, _listCommandsKeywords)) {
      return VoiceCommand.now(
        type: CommandType.listCommands,
        originalText: recognizedText,
      );
    }

    // Prioridad 8: Compartir pantalla (antes de ayuda genérica)
    if (_matchesAny(normalized, _shareScreenKeywords)) {
      return VoiceCommand.now(
        type: CommandType.shareScreen,
        originalText: recognizedText,
      );
    }

    // Prioridad 9: Ayuda
    if (_matchesAny(normalized, _helpKeywords)) {
      return VoiceCommand.now(
        type: CommandType.requestHelp,
        originalText: recognizedText,
      );
    }

    // Prioridad 10: WhatsApp
    if (_matchesAny(normalized, _whatsappKeywords)) {
      return VoiceCommand.now(
        type: CommandType.openWhatsApp,
        originalText: recognizedText,
      );
    }

    // Prioridad 11: Saludos sin objetivo (rechazar conversaciones)
    if (_matchesAny(normalized, _greetingKeywords)) {
      // DEBUG: Mostrar que se detectó saludo
      debugPrint('👋 [NLPParser] GREETING DETECTED: "$normalized" → conversationRejected');
      return VoiceCommand.now(
        type: CommandType.conversationRejected,
        originalText: recognizedText,
      );
    }

    // Prioridad 12: Comando no reconocido
    // DEBUG: Mostrar que no se reconoció nada
    debugPrint('❓ [NLPParser] NO MATCH: "$normalized" → unknown');
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
