import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart' show FormFieldConfig;
import 'package:test/test.dart';

import 'mock_terminal.dart';

void main() {
  setUp(TerminalContext.reset);
  tearDown(TerminalContext.reset);

  group('high-level fallback EOF behavior', () {
    test('nullable text and form prompts return null on EOF', () {
      final textResult = terminice.fallback
          .withTerminal(MockTerminal())
          .text('Name', required: false);

      final formResult = terminice.fallback.withTerminal(MockTerminal()).form(
        'Profile',
        fields: [
          FormFieldConfig(label: 'Name', initialValue: 'Ada'),
        ],
      );

      expect(textResult, isNull);
      expect(formResult, isNull);
    });

    test('form fallback still uses initial values for empty lines', () {
      final terminal = MockTerminal();
      terminal.mockInput.queueLine('');

      final result = terminice.fallback.withTerminal(terminal).form(
        'Profile',
        fields: [
          FormFieldConfig(label: 'Name', initialValue: 'Ada'),
        ],
      );

      expect(result?.values, ['Ada']);
    });

    test('list selectors return empty lists on EOF', () {
      final searchResult = terminice.fallback
          .withTerminal(MockTerminal())
          .searchSelector(options: ['alpha', 'beta']);

      final checkboxResult =
          terminice.fallback.withTerminal(MockTerminal()).checkboxSelector(
        'Pick many',
        options: ['alpha', 'beta'],
        initialSelected: {1},
      );

      expect(searchResult, isEmpty);
      expect(checkboxResult, isEmpty);
    });

    test('selector fallback still uses defaults for empty lines', () {
      final terminal = MockTerminal();
      terminal.mockInput.queueLine('');

      final result = terminice.fallback.withTerminal(terminal).searchSelector(
        options: ['alpha', 'beta'],
      );

      expect(result, ['alpha']);
    });

    test('nullable single selector returns null on EOF', () {
      final result =
          terminice.fallback.withTerminal(MockTerminal()).commandPalette(
        'Commands',
        commands: [
          const CommandEntry(id: 'open', title: 'Open'),
        ],
      );

      expect(result, isNull);
    });
  });
}
