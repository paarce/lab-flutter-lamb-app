import 'package:flutter_test/flutter_test.dart';
import 'package:lamb/models/command.dart';
import 'package:lamb/utils/nlp_parser.dart';

void main() {
  group('NLPParser', () {
    group('requestHelp command', () {
      test('recognizes "solicitar ayuda"', () {
        final command = NLPParser.parse('solicitar ayuda');
        expect(command.type, CommandType.requestHelp);
        expect(command.originalText, 'solicitar ayuda');
      });

      test('recognizes "necesito ayuda"', () {
        final command = NLPParser.parse('necesito ayuda');
        expect(command.type, CommandType.requestHelp);
      });

      test('recognizes "ayúdame"', () {
        final command = NLPParser.parse('ayúdame');
        expect(command.type, CommandType.requestHelp);
      });

      test('is case insensitive', () {
        final command = NLPParser.parse('SOLICITAR AYUDA');
        expect(command.type, CommandType.requestHelp);
      });

      test('recognizes partial matches', () {
        final command = NLPParser.parse('por favor solicitar ayuda ahora');
        expect(command.type, CommandType.requestHelp);
      });
    });

    group('openWhatsApp command', () {
      test('recognizes "abrir whatsapp"', () {
        final command = NLPParser.parse('abrir whatsapp');
        expect(command.type, CommandType.openWhatsApp);
      });

      test('recognizes "abre whatsapp"', () {
        final command = NLPParser.parse('abre whatsapp');
        expect(command.type, CommandType.openWhatsApp);
      });

      test('recognizes just "whatsapp"', () {
        final command = NLPParser.parse('whatsapp');
        expect(command.type, CommandType.openWhatsApp);
      });

      test('is case insensitive', () {
        final command = NLPParser.parse('ABRIR WHATSAPP');
        expect(command.type, CommandType.openWhatsApp);
      });
    });

    group('toggleContrast command', () {
      test('recognizes "alto contraste"', () {
        final command = NLPParser.parse('alto contraste');
        expect(command.type, CommandType.toggleContrast);
      });

      test('recognizes "activar contraste"', () {
        final command = NLPParser.parse('activar contraste');
        expect(command.type, CommandType.toggleContrast);
      });

      test('recognizes just "contraste"', () {
        final command = NLPParser.parse('contraste');
        expect(command.type, CommandType.toggleContrast);
      });
    });

    group('cancel command', () {
      test('recognizes "cancelar"', () {
        final command = NLPParser.parse('cancelar');
        expect(command.type, CommandType.cancel);
      });

      test('recognizes "detener"', () {
        final command = NLPParser.parse('detener');
        expect(command.type, CommandType.cancel);
      });

      test('recognizes "para"', () {
        final command = NLPParser.parse('para');
        expect(command.type, CommandType.cancel);
      });

      test('has priority over other commands', () {
        final command = NLPParser.parse('cancelar ayuda');
        expect(command.type, CommandType.cancel);
      });
    });

    group('unknown command', () {
      test('returns unknown for unrecognized text', () {
        final command = NLPParser.parse('xyz random text');
        expect(command.type, CommandType.unknown);
        expect(command.originalText, 'xyz random text');
      });

      test('returns unknown for empty text', () {
        final command = NLPParser.parse('');
        expect(command.type, CommandType.unknown);
      });

      test('returns unknown for only whitespace', () {
        final command = NLPParser.parse('   ');
        expect(command.type, CommandType.unknown);
      });
    });

    group('edge cases', () {
      test('preserves original text casing', () {
        final command = NLPParser.parse('SOLICITAR AYUDA');
        expect(command.originalText, 'SOLICITAR AYUDA');
      });

      test('handles extra whitespace', () {
        final command = NLPParser.parse('  abrir whatsapp  ');
        expect(command.type, CommandType.openWhatsApp);
      });

      test('creates command with timestamp', () {
        final command = NLPParser.parse('ayuda');
        expect(command.timestamp, isNotNull);
        expect(command.timestamp.isBefore(DateTime.now().add(Duration(seconds: 1))), true);
      });
    });
  });
}
