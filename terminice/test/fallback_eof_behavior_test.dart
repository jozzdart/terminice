import 'package:terminice/terminice.dart';
import 'package:terminice/src/config_editor/focused_select.dart';
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

    for (final inputCase in <({String name, bool blank})>[
      (name: 'blank input', blank: true),
      (name: 'EOF', blank: false),
    ]) {
      test('selectors do not fabricate focused selections on ${inputCase.name}',
          () {
        MockTerminal terminal() {
          final terminal = MockTerminal();
          if (inputCase.blank) terminal.mockInput.queueLine('');
          return terminal;
        }

        final cases = <({String name, Object? actual, Object? expected})>[
          (
            name: 'searchSelector',
            actual: terminice.fallback
                .withTerminal(terminal())
                .searchSelector(options: const ['alpha', 'beta']),
            expected: <String>[],
          ),
          (
            name: 'gridSelector',
            actual: terminice.fallback
                .withTerminal(terminal())
                .gridSelector(options: const ['alpha', 'beta']),
            expected: <String>[],
          ),
          (
            name: 'checkboxSelector',
            actual: terminice.fallback
                .withTerminal(terminal())
                .checkboxSelector('Checkbox', options: const ['alpha', 'beta']),
            expected: <String>[],
          ),
          (
            name: 'choiceSelector',
            actual: terminice.fallback.withTerminal(terminal()).choiceSelector(
              'Choice',
              items: const [ChoiceItem('alpha'), ChoiceItem('beta')],
            ),
            expected: <String>[],
          ),
          (
            name: 'tagSelector',
            actual: terminice.fallback
                .withTerminal(terminal())
                .tagSelector(tags: const ['alpha', 'beta']),
            expected: <String>[],
          ),
          (
            name: 'toggleGroup',
            actual: terminice.fallback.withTerminal(terminal()).toggleGroup(
              'Toggle',
              items: const [ToggleItem('alpha'), ToggleItem('beta')],
            ),
            expected: <String, bool>{'alpha': false, 'beta': false},
          ),
          (
            name: 'commandPalette',
            actual: terminice.fallback.withTerminal(terminal()).commandPalette(
              'Commands',
              commands: const [
                CommandEntry(id: 'open', title: 'Open'),
              ],
            ),
            expected: null,
          ),
        ];

        for (final selectorCase in cases) {
          expect(
            selectorCase.actual,
            selectorCase.expected,
            reason: selectorCase.name,
          );
        }
      });
    }

    test('blank input preserves explicit selector initial state', () {
      MockTerminal terminal() => MockTerminal()..mockInput.queueLine('');

      expect(
        terminice.fallback.withTerminal(terminal()).gridSelector(
          options: const ['zero', 'one', 'two'],
          initialSelection: const {2, -1, 1, 99},
        ),
        ['one'],
      );
      expect(
        terminice.fallback.withTerminal(terminal()).gridSelector(
              options: const ['zero', 'one', 'two'],
              multiSelect: true,
              initialSelection: const {2, -1, 1, 99},
            ),
        ['one', 'two'],
      );
      expect(
        terminice.fallback.withTerminal(terminal()).checkboxSelector(
          'Checkbox',
          options: const ['zero', 'one', 'two'],
          initialSelected: const {2, -1, 1, 99},
        ),
        ['one', 'two'],
      );
      expect(
        terminice.fallback.withTerminal(terminal()).toggleGroup(
          'Toggle',
          items: const [
            ToggleItem('off'),
            ToggleItem('on', initialOn: true),
          ],
        ),
        {'off': false, 'on': true},
      );
      expect(
        focusedSelect(
          terminice: terminice.fallback.withTerminal(terminal()),
          options: const ['zero', 'one', 'two'],
          title: 'Focused',
          initialIndex: 2,
        ),
        'two',
      );
    });

    test('EOF cancels selectors even when they have initial state', () {
      expect(
        terminice.fallback.withTerminal(MockTerminal()).gridSelector(
          options: const ['zero', 'one'],
          initialSelection: const {1},
        ),
        isEmpty,
      );
      expect(
        terminice.fallback.withTerminal(MockTerminal()).checkboxSelector(
          'Checkbox',
          options: const ['zero', 'one'],
          initialSelected: const {1},
        ),
        isEmpty,
      );
      expect(
        focusedSelect(
          terminice: terminice.fallback.withTerminal(MockTerminal()),
          options: const ['zero', 'one'],
          title: 'Focused',
          initialIndex: 1,
        ),
        isNull,
      );
      expect(
        terminice.fallback.withTerminal(MockTerminal()).toggleGroup(
          'Toggle',
          items: const [ToggleItem('on', initialOn: true)],
        ),
        {'on': true},
      );
    });
  });
}
