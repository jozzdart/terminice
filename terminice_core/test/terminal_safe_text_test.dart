import 'package:terminice_core/terminice_core.dart';
import 'package:terminice_core/testing.dart' show TerminalOutputSnapshot;
import 'package:test/test.dart';

void main() {
  group('terminalSafeBlockText', () {
    test('visibly escapes CSI and OSC sequences without emitting controls', () {
      final result = terminalSafeBlockText(
        '\x1b[31mred\x1b[0m '
        '\x1b]0;title\x07 '
        '\x1b]8;;https://example.test\x1b\\link\x1b]8;;\x1b\\',
      );

      expect(
        result,
        equals(
          r'\x1b[31mred\x1b[0m '
          r'\x1b]0;title\x07 '
          r'\x1b]8;;https://example.test\x1b\link\x1b]8;;\x1b\',
        ),
      );
      expect(TerminalOutputSnapshot.hasTerminalControls(result), isFalse);
    });

    test('escapes C0, C1, carriage return, and delete', () {
      final result = terminalSafeBlockText(
        '\x00\x08\x0b\x0c\x1f\r\x7f\x80\x85\x9b',
      );

      expect(
        result,
        equals(r'\x00\x08\x0b\x0c\x1f\r\x7f\x80\x85\x9b'),
      );
      expect(TerminalOutputSnapshot.hasTerminalControls(result), isFalse);
    });

    test('preserves newlines and Unicode while visibly escaping tabs', () {
      const input = 'first\n\tשלום café 界';

      final result = terminalSafeBlockText(input);
      expect(result, 'first\n\\tשלום café 界');
      expect(result, isNot(contains('\t')));
    });
  });

  group('terminalSafeLineText', () {
    test('collapses whitespace, trims, and retains visible control escapes',
        () {
      final result = terminalSafeLineText(
        '  first\n\t second\r third \x1b[2J  ',
      );

      expect(result, equals(r'first second\r third \x1b[2J'));
      expect(TerminalOutputSnapshot.hasTerminalControls(result), isFalse);
      expect(result, isNot(contains('\t')));
    });
  });
}
