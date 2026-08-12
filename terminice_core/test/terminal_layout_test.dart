import 'package:terminice_core/testing.dart';
import 'package:test/test.dart';

void main() {
  late MockTerminal terminal;

  setUp(() {
    terminal = MockTerminal();
    TerminalContext.current = terminal;
  });

  tearDown(TerminalContext.reset);

  group('terminal cell-aware core layouts', () {
    test('hint grids align wide and ANSI-styled labels', () {
      const red = '\x1B[31m';
      const reset = '\x1B[0m';

      final hints = HintFormat.grid([
        ['界', 'Open'],
        ['$red A$reset', 'Close'],
      ], PromptTheme.dark);
      final lines = stripAnsi(hints).split('\n');

      expect(lines[1], '  界  Open   ');
      expect(lines[2], '   A  Close');
    });

    test('selectable grid auto sizing uses terminal cell width', () {
      terminal.mockInput.queueKey(KeyEventType.enter);
      final wide = SelectableGridPrompt<String>(
        title: 'Wide',
        items: ['界界界界界界'],
        columns: 1,
      )..run();

      expect(wide.computedCellWidth, 16);

      terminal
        ..output.reset()
        ..mockInput.queueKey(KeyEventType.enter);
      final styled = SelectableGridPrompt<String>(
        title: 'Styled',
        items: ['\x1B[31mabc\x1B[0m'],
        columns: 1,
      )..run();

      expect(styled.computedCellWidth, 10);
    });

    test('default grid cells truncate whole graphemes and stay aligned', () {
      terminal.mockInput.queueKey(KeyEventType.enter);

      SelectableGridPrompt<String>(
        title: 'Grid',
        items: [
          '界界界界',
          'e\u0301e\u0301e\u0301e\u0301e\u0301e\u0301e\u0301',
          '👍🏽👍🏽👍🏽👍🏽',
          '🇮🇱🇮🇱🇮🇱🇮🇱',
          '👩‍💻👩‍💻👩‍💻👩‍💻',
          '\x1B[31mabcdefghijk\x1B[0m',
        ],
        columns: 1,
        cellWidth: 8,
        theme: PromptTheme.compact,
      ).run(showRowSeparators: false);

      final plain = stripAnsi(terminal.output.allOutput);
      expect(plain, contains('界界…   '));
      expect(plain, contains('e\u0301e\u0301e\u0301e\u0301e\u0301…  '));
      expect(plain, contains('👍🏽👍🏽…   '));
      expect(plain, contains('🇮🇱🇮🇱…   '));
      expect(plain, contains('👩‍💻👩‍💻…   '));
      expect(
        terminal.output.allOutput,
        contains('\x1B[31mabcde…\x1B[0m  '),
      );
    });

    test('chips and cards preserve ASCII and use cell-aware padding', () {
      terminal.mockInput.queueKey(KeyEventType.enter);
      final prompt = SelectableGridPrompt<String>(
        title: 'Grid',
        items: ['item'],
        columns: 1,
        cellWidth: 8,
      )..run();

      expect(stripAnsi(prompt.renderChip('abc', false, false)), '[ abc ] ');
      expect(
        prompt.renderChip('abc', false, true),
        '[ ${prompt.theme.accent}abc${prompt.theme.reset} ] ',
      );
      expect(
        prompt.renderChip('abc', true, true),
        '${prompt.theme.inverse}${prompt.theme.selection}'
        '[ abc ] ${prompt.theme.reset}',
      );
      expect(visibleLength(prompt.renderChip('界', false, false)), 8);

      final asciiCard = prompt.renderCard(
        title: 'abc',
        subtitle: 'xyz',
        isFocused: false,
        isSelected: false,
      );
      expect(stripAnsi(asciiCard.top), 'abc     ');
      expect(stripAnsi(asciiCard.bottom), 'xyz     ');

      final unicodeCard = prompt.renderCard(
        title: '\x1B[31m👩‍💻👩‍💻👩‍💻👩‍💻👩‍💻\x1B[0m',
        subtitle: '🇮🇱🇮🇱🇮🇱🇮🇱🇮🇱',
        isFocused: false,
        isSelected: false,
      );
      expect(visibleLength(unicodeCard.top), 8);
      expect(visibleLength(unicodeCard.bottom), 8);
      expect(stripAnsi(unicodeCard.top), '👩‍💻👩‍💻👩‍💻… ');
      expect(stripAnsi(unicodeCard.bottom), '🇮🇱🇮🇱🇮🇱… ');
      expect(unicodeCard.top, contains('\x1B[0m'));
    });

    test('narrow chips truncate without splitting or leaking styles', () {
      terminal.mockInput.queueKey(KeyEventType.enter);
      final prompt = SelectableGridPrompt<String>(
        title: 'Grid',
        items: ['item'],
        columns: 1,
        cellWidth: 8,
      )..run();

      void expectChip(
        String chip,
        String plain, {
        String? includesStyle,
      }) {
        expect(visibleLength(chip), 8);
        expect(stripAnsi(chip), plain);
        if (includesStyle != null) {
          expect(chip, contains(includesStyle));
          expect(chip, contains(prompt.theme.reset));
          expect(chip.endsWith(prompt.theme.reset), isTrue);
        }
      }

      expectChip(prompt.renderChip('abcdefgh', false, false), '[ abcde…');
      expectChip(prompt.renderChip('界界界', false, false), '[ 界界… ');
      expectChip(
          prompt.renderChip('👍🏽👍🏽👍🏽', false, false), '[ 👍🏽👍🏽… ');
      expectChip(
          prompt.renderChip('👩‍💻👩‍💻👩‍💻', false, false), '[ 👩‍💻👩‍💻… ');
      expectChip(
        prompt.renderChip('\x1B[31mabcdefgh\x1B[0m', false, false),
        '[ abcde…',
        includesStyle: '\x1B[31m',
      );
      expectChip(
        prompt.renderChip('abcdefgh', false, true),
        '[ abcde…',
        includesStyle: prompt.theme.accent,
      );
      expectChip(
        prompt.renderChip('👩‍💻👩‍💻👩‍💻', true, true),
        '[ 👩‍💻👩‍💻… ',
        includesStyle: prompt.theme.inverse,
      );
    });

    test('form labels align by visible terminal cells', () {
      terminal.mockInput
        ..queueKey(KeyEventType.enter)
        ..queueKey(KeyEventType.enter);

      FormPrompt(
        title: 'Form',
        fields: const [
          FormFieldConfig(label: '界'),
          FormFieldConfig(label: '\x1B[31mA\x1B[0m'),
        ],
        theme: PromptTheme.compact,
      ).run();

      final plain = stripAnsi(terminal.output.allOutput);
      expect(plain, contains('界  '));
      expect(plain, contains('A   '));
    });
  });
}
