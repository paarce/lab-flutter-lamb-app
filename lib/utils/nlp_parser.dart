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
    'alto',
    'cancela',
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

    // Prioridad 2: Comandos específicos
    if (_matchesAny(normalized, _helpKeywords)) {
      return VoiceCommand.now(
        type: CommandType.requestHelp,
        originalText: recognizedText,
      );
    }

    if (_matchesAny(normalized, _whatsappKeywords)) {
      return VoiceCommand.now(
        type: CommandType.openWhatsApp,
        originalText: recognizedText,
      );
    }

    if (_matchesAny(normalized, _contrastKeywords)) {
      return VoiceCommand.now(
        type: CommandType.toggleContrast,
        originalText: recognizedText,
      );
    }

    // Prioridad 3: Comando no reconocido
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
}
