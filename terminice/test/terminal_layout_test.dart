import 'package:terminice/terminice.dart';
import 'package:terminice/src/core/layout_text.dart';
import 'package:terminice_core/terminice_core.dart'
    show KeyEventType, stripAnsi;
import 'package:test/test.dart';

import 'mock_terminal.dart';

void main() {
  setUp(TerminalContext.reset);
  tearDown(TerminalContext.reset);

  group('terminal-cell-aware umbrella layouts', () {
    test('legacy narrow truncation preserves ASCII output at widths 0-4', () {
      expect(truncateWithDots('abcdef', 0), '');
      expect(truncateWithDots('abcdef', 1), 'a');
      expect(truncateWithDots('abcdef', 2), 'ab');
      expect(truncateWithDots('abcdef', 3), 'abc');
      expect(truncateWithDots('abcdef', 4), 'a...');
      expect(() => truncateWithDots('abcdef', -1), throwsRangeError);
    });

    test('legacy narrow truncation keeps graphemes whole and closes ANSI', () {
      expect(truncateWithDots('界x', 1), '');
      expect(truncateWithDots('界x', 2), '界');
      expect(truncateWithDots('👩🏽‍💻x', 1), '');
      expect(truncateWithDots('👩🏽‍💻x', 2), '👩🏽‍💻');
      expect(truncateWithDots('e\u0301x', 1), 'e\u0301');
      expect(
        truncateWithDots('\x1B[31mabcdef', 2),
        '\x1B[31mab\x1B[0m',
      );
    });

    test('choice cards pad CJK and ANSI-styled labels by terminal cells', () {
      final mock = MockTerminal();
      mock.mockInput.queueKey(KeyEventType.esc);

      Terminice(terminal: mock).choiceSelector(
        'Choose',
        items: const [
          ChoiceItem('\x1B[31m界\x1B[0m'),
          ChoiceItem('plain'),
        ],
        columns: 2,
        cardWidth: 16,
      );

      final output = stripAnsi(mock.mockOutput.allOutput);
      expect(output, contains('界${' ' * 14}'));
      expect(output, isNot(contains('界${' ' * 15}')));
    });

    test('tag and toggle columns account for wide labels', () {
      final tagMock = MockTerminal();
      tagMock.mockInput.queueKey(KeyEventType.esc);
      Terminice(terminal: tagMock).tagSelector(
        tags: const ['界', 'plain'],
        useTerminalWidth: false,
        minColumnWidth: 8,
        maxColumnWidth: 8,
      );

      expect(stripAnsi(tagMock.mockOutput.allOutput), contains('[ 界 ]  '));

      TerminalContext.reset();
      final toggleMock = MockTerminal();
      toggleMock.mockInput.queueKey(KeyEventType.esc);
      Terminice(terminal: toggleMock).toggleGroup(
        'Toggles',
        items: const [ToggleItem('界'), ToggleItem('plain')],
      );

      expect(
          stripAnsi(toggleMock.mockOutput.allOutput), contains('界${' ' * 6}'));
    });

    test('config value previews do not split grapheme clusters', () {
      final decomposed = StringConfigurable(
        key: 'decomposed',
        label: 'Decomposed',
        value: '${'a' * 29}e\u0301tail\nsecond',
        multiline: true,
      );
      final emoji = StringConfigurable(
        key: 'emoji',
        label: 'Emoji',
        value: '${'a' * 39}👩🏽‍💻tail',
      );
      final flag = StringConfigurable(
        key: 'flag',
        label: 'Flag',
        value: '${'a' * 39}🇮🇱tail',
      );

      expect(decomposed.displayValue, '${'a' * 29}e\u0301… (+1 lines)');
      expect(emoji.displayValue, '${'a' * 39}…');
      expect(flag.displayValue, '${'a' * 39}…');
    });

    test('help preview truncates styled text without leaking styles', () {
      final mock = MockTerminal();
      mock.mockOutput.setDimensions(columns: 14);
      mock.mockInput.queueKey(KeyEventType.esc);

      Terminice(terminal: mock).helpCenter(
        docs: const [
          HelpDoc(
            id: 'styled',
            title: 'Styled',
            content: '\x1B[31maaaaaaaa👩🏽‍💻tail',
          ),
        ],
      );

      final output = mock.mockOutput.allOutput;
      expect(stripAnsi(output), contains('aaaaaa...'));
      expect(output, contains('aaaaaa...\x1B[0m'));
      expect(output, isNot(contains('👩')));
    });

    test('checkbox keeps legacy dots while truncating whole graphemes', () {
      final mock = MockTerminal();
      mock.mockOutput.setDimensions(columns: 14);
      mock.mockInput.queueKey(KeyEventType.esc);

      Terminice(terminal: mock).checkboxSelector(
        'Checks',
        options: const ['aaaaaa👩🏽‍💻tail'],
      );

      final output = stripAnsi(mock.mockOutput.allOutput);
      expect(output, contains('aaaa...'));
      expect(output, isNot(contains('👩')));
    });
  });
}
