import 'package:flutter_test/flutter_test.dart';
import 'package:lamb/models/image_description.dart';

void main() {
  group('ImageDescription.fromModelResponse', () {
    test('parses clean JSON', () {
      final result = ImageDescription.fromModelResponse(
        '{"kind": "chat", "text": "Es una captura de un chat de WhatsApp."}',
      );

      expect(result!.kind, ImageKind.chatScreenshot);
      expect(result.spokenText, 'Es una captura de un chat de WhatsApp.');
    });

    test('parses JSON wrapped in markdown fences and extra text', () {
      final result = ImageDescription.fromModelResponse(
        'Aquí tienes:\n```json\n'
        '{"kind": "medical_results", "text": "Son los resultados de un análisis de sangre."}\n'
        '```',
      );

      expect(result!.kind, ImageKind.medicalResults);
      expect(result.spokenText, 'Son los resultados de un análisis de sangre.');
    });

    test('maps every wire name to its kind', () {
      for (final kind in ImageKind.values) {
        final result = ImageDescription.fromModelResponse(
          '{"kind": "${kind.wireName}", "text": "x"}',
        );
        expect(result!.kind, kind);
      }
    });

    test('unknown kind falls back to other', () {
      final result = ImageDescription.fromModelResponse(
        '{"kind": "meme", "text": "Un dibujo de un gato."}',
      );
      expect(result!.kind, ImageKind.other);
    });

    test('plain text response is used as-is (never loses the reading)', () {
      final result = ImageDescription.fromModelResponse(
        'Es una foto de una persona en un paisaje de montaña.',
      );

      expect(result!.kind, ImageKind.other);
      expect(
        result.spokenText,
        'Es una foto de una persona en un paisaje de montaña.',
      );
    });

    test('invalid JSON falls back to plain text', () {
      final result = ImageDescription.fromModelResponse('{"kind": "photo", text');
      expect(result, isNotNull);
      expect(result!.kind, ImageKind.other);
    });

    test('strips markdown symbols that TTS would read aloud', () {
      final result = ImageDescription.fromModelResponse(
        '{"kind": "document", "text": "**Diagnóstico:** _reposo_ # tres días"}',
      );
      expect(result!.spokenText, 'Diagnóstico: reposo tres días');
    });

    test('returns null for empty responses', () {
      expect(ImageDescription.fromModelResponse(''), isNull);
      expect(ImageDescription.fromModelResponse('   '), isNull);
      expect(
        ImageDescription.fromModelResponse('{"kind": "photo", "text": ""}'),
        isNull, // nunca leer el JSON crudo en voz alta
      );
    });
  });

  group('ImageKind', () {
    test('has a Spanish label for every kind', () {
      for (final kind in ImageKind.values) {
        expect(kind.label, isNotEmpty);
      }
      expect(ImageKind.chatScreenshot.label, 'Captura de chat');
    });
  });
}
