import 'dart:convert';

/// Tipo de imagen detectado por la IA de visión
enum ImageKind {
  /// Captura de pantalla de un chat (WhatsApp, SMS, Telegram...)
  chatScreenshot,

  /// Resultados de análisis clínicos / exámenes de laboratorio
  medicalResults,

  /// Documento con texto (informe médico, carta, receta, factura...)
  document,

  /// Fotografía (personas, paisajes, objetos...)
  photo,

  /// Cualquier otra cosa (captura de otra app, dibujo, meme...)
  other,
}

extension ImageKindX on ImageKind {
  /// Etiqueta corta en español para mostrar en pantalla
  String get label {
    switch (this) {
      case ImageKind.chatScreenshot:
        return 'Captura de chat';
      case ImageKind.medicalResults:
        return 'Resultados médicos';
      case ImageKind.document:
        return 'Documento';
      case ImageKind.photo:
        return 'Fotografía';
      case ImageKind.other:
        return 'Imagen';
    }
  }

  /// Valor usado en el JSON que devuelve la IA
  String get wireName {
    switch (this) {
      case ImageKind.chatScreenshot:
        return 'chat';
      case ImageKind.medicalResults:
        return 'medical_results';
      case ImageKind.document:
        return 'document';
      case ImageKind.photo:
        return 'photo';
      case ImageKind.other:
        return 'other';
    }
  }

  static ImageKind fromWireName(String? value) {
    final normalized = value?.trim().toLowerCase();
    return ImageKind.values.firstWhere(
      (kind) => kind.wireName == normalized,
      orElse: () => ImageKind.other,
    );
  }
}

/// Resultado de interpretar una imagen con IA
///
/// [spokenText] es el texto listo para leer con TTS: lenguaje simple,
/// sin markdown ni emojis.
class ImageDescription {
  final ImageKind kind;
  final String spokenText;

  const ImageDescription({
    required this.kind,
    required this.spokenText,
  });

  /// Construye la descripción a partir de la respuesta cruda del modelo.
  ///
  /// El prompt pide JSON `{"kind": "...", "text": "..."}`, pero los modelos
  /// a veces lo envuelven en ```json``` o añaden texto alrededor. Si no hay
  /// JSON válido se usa la respuesta completa como texto (nunca se pierde
  /// la lectura por un problema de formato).
  ///
  /// Retorna `null` si la respuesta no contiene texto utilizable.
  static ImageDescription? fromModelResponse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start != -1 && end > start) {
      try {
        final decoded = jsonDecode(trimmed.substring(start, end + 1));
        if (decoded is Map<String, dynamic>) {
          // JSON válido: nunca leer el JSON crudo en voz alta
          final text = _cleanForSpeech(decoded['text']?.toString() ?? '');
          if (text.isEmpty) return null;
          return ImageDescription(
            kind: ImageKindX.fromWireName(decoded['kind']?.toString()),
            spokenText: text,
          );
        }
      } on FormatException {
        // Continuar con fallback de texto plano
      }
    }

    final text = _cleanForSpeech(trimmed);
    if (text.isEmpty) return null;
    return ImageDescription(kind: ImageKind.other, spokenText: text);
  }

  /// Elimina marcas de markdown que el TTS leería en voz alta
  static String _cleanForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'```[a-zA-Z]*'), '')
        .replaceAll(RegExp(r'[*_#`]'), '')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  @override
  String toString() => 'ImageDescription(kind: $kind, text: "$spokenText")';
}
