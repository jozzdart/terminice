import 'package:terminice/terminice.dart';
import 'package:terminice/src/core/layout_text.dart';
import 'package:terminice/src/pickers/_file_helpers.dart';
import 'package:terminice_core/terminice_core.dart'
    show KeyEventType, stripAnsi, visibleLength;
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

    test('config multiline previews preserve 30-character ASCII boundary', () {
      String preview(int length) => StringConfigurable(
            key: 'notes',
            label: 'Notes',
            value: '${'a' * length}\nsecond',
            multiline: true,
          ).displayValue;

      expect(preview(30), '${'a' * 30} (+1 lines)');
      expect(preview(31), '${'a' * 30}… (+1 lines)');
      expect(preview(32), '${'a' * 30}… (+1 lines)');
    });

    test('config single-line previews preserve 40-character ASCII boundary',
        () {
      String preview(int length) => StringConfigurable(
            key: 'name',
            label: 'Name',
            value: 'a' * length,
          ).displayValue;

      expect(preview(40), 'a' * 40);
      expect(preview(41), '${'a' * 40}…');
      expect(preview(42), '${'a' * 40}…');
    });

    test('config preview boundaries are grapheme- and cell-safe', () {
      String preview(String value, {bool multiline = false}) =>
          StringConfigurable(
            key: 'value',
            label: 'Value',
            value: multiline ? '$value\nsecond' : value,
            multiline: multiline,
          ).displayValue;

      expect(preview('e\u0301' * 30, multiline: true),
          '${'e\u0301' * 30} (+1 lines)');
      expect(preview('${'e\u0301' * 30}x', multiline: true),
          '${'e\u0301' * 30}… (+1 lines)');
      expect(preview('界' * 15, multiline: true), '${'界' * 15} (+1 lines)');
      expect(
          preview('${'界' * 15}x', multiline: true), '${'界' * 15}… (+1 lines)');
      expect(preview('👩🏽‍💻' * 20), '👩🏽‍💻' * 20);
      expect(preview('${'👩🏽‍💻' * 20}x'), '${'👩🏽‍💻' * 20}…');
      expect(preview('${'🇮🇱' * 20}x'), '${'🇮🇱' * 20}…');
    });

    test('shortPath preserves ASCII suffixes and clips Unicode boundaries', () {
      expect(shortPath('/ordinary/path'), '/ordinary/path');
      expect(shortPath('a' * 60), 'a' * 60);
      expect(shortPath('a' * 61), '...${'a' * 57}');

      final cjk = shortPath('界' * 31);
      final emoji = shortPath('👩🏽‍💻' * 31);
      final combining = shortPath('e\u0301' * 61);

      expect(cjk, '...${'界' * 28}');
      expect(emoji, '...${'👩🏽‍💻' * 28}');
      expect(combining, '...${'e\u0301' * 57}');
      expect(visibleLength(cjk), lessThanOrEqualTo(60));
      expect(visibleLength(emoji), lessThanOrEqualTo(60));
      expect(visibleLength(combining), 60);
    });

    test('shortPath renders path controls visibly before truncating', () {
      final shortened = shortPath('prefix\x1B[31m${'x' * 70}');

      expect(shortened, isNot(contains('\x1B')));
      expect(shortened, endsWith('x' * 57));
      expect(visibleLength(shortened), 60);
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
