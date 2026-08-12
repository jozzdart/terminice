import 'package:terminice_core/testing.dart';
import 'package:test/test.dart';

void main() {
  late MockTerminal terminal;

  setUp(() {
    terminal = MockTerminal();
    TerminalContext.current = terminal;
  });

  tearDown(TerminalContext.reset);

  group('FallbackPrompt', () {
    test('text validates with the empty-string success convention', () {
      terminal.mockInput.queueLines(['ab', 'abcd']);

      final result = FallbackPrompt.text(
        title: 'Name',
        validator: (value) => value.length < 4 ? 'Too short' : '',
      );

      expect(result, 'abcd');
      expect(terminal.mockOutput.contains('Too short'), isTrue);
    });

    test('text validates with the nullable success convention', () {
      terminal.mockInput.queueLines(['ab', 'abcd']);

      final result = FallbackPrompt.text(
        title: 'Name',
        validator: (value) => value.length < 4 ? 'Too short' : null,
      );

      expect(result, 'abcd');
      expect(terminal.mockOutput.contains('Too short'), isTrue);
    });

    test('text distinguishes EOF from empty default input when opted out', () {
      terminal.mockInput.queueLine('');

      final emptyResult = FallbackPrompt.text(
        title: 'Name',
        defaultValue: 'Ada',
        returnDefaultOnEndOfInput: false,
      );
      final eofResult = FallbackPrompt.text(
        title: 'Name',
        defaultValue: 'Ada',
        returnDefaultOnEndOfInput: false,
      );

      expect(emptyResult, 'Ada');
      expect(eofResult, isNull);
    });

    test('text returns the default on EOF by default', () {
      final result = FallbackPrompt.text(
        title: 'Name',
        defaultValue: 'Ada',
      );

      expect(result, 'Ada');
    });

    test('password uses line input without changing terminal modes', () {
      terminal.mockInput.queueLine('secret');

      final result = FallbackPrompt.password(title: 'Password');

      expect(result, 'secret');
      expect(terminal.mockInput.echoMode, isTrue);
      expect(terminal.mockInput.lineMode, isTrue);
    });

    test('confirm returns the default for empty input', () {
      terminal.mockInput.queueLine('');

      final result = FallbackPrompt.confirm(
        title: 'Continue?',
        defaultValue: true,
      );

      expect(result, isTrue);
      expect(terminal.mockOutput.writes, contains('Continue? [Y/n]: '));
    });

    test('singleSelect returns the selected one-based option', () {
      terminal.mockInput.queueLine('2');

      final result = FallbackPrompt.singleSelect(
        title: 'Pick one',
        options: ['alpha', 'beta', 'gamma'],
      );

      expect(result, 'beta');
    });

    test('multiSelect parses comma-separated one-based options', () {
      terminal.mockInput.queueLine('1, 3');

      final result = FallbackPrompt.multiSelect(
        title: 'Pick many',
        options: ['alpha', 'beta', 'gamma'],
      );

      expect(result, ['alpha', 'gamma']);
    });

    test('sanitizes hostile titles, labels, defaults, and validator errors',
        () {
      terminal.mockInput.queueLines(['2', 'bad', 'good']);

      final selected = FallbackPrompt.singleSelect<Object>(
        title: 'Pick\x1b[2J\r\nnow',
        options: [
          _HostileLabel('first\x1b]0;owned\x07'),
          _HostileLabel('second\x9b31m'),
        ],
      );
      final value = FallbackPrompt.text(
        title: 'Name\x00',
        defaultValue: 'Ada\x7f',
        validator: (input) => input == 'bad' ? 'No\x1b[31m\r\nretry' : null,
      );

      expect(selected.toString(), contains('second'));
      expect(value, 'good');
      final snapshot = terminal.outputSnapshot;
      expect(snapshot.containsAnsiControls, isFalse);
      expect(snapshot.raw, contains(r'Pick\x1b[2J\r now'));
      expect(snapshot.raw, contains(r'first\x1b]0;owned\x07'));
      expect(snapshot.raw, contains(r'second\x9b31m'));
      expect(snapshot.raw, contains(r'Name\x00 [Ada\x7f]: '));
      expect(snapshot.raw, contains(r'No\x1b[31m\r retry'));
    });

    test('multiSelect uses fallbackIndex for empty input without defaults', () {
      terminal.mockInput.queueLine('');

      final result = FallbackPrompt.multiSelect(
        title: 'Pick many',
        options: ['alpha', 'beta', 'gamma'],
        fallbackIndex: 0,
      );

      expect(result, ['alpha']);
    });

    test('multiSelect explicit none returns empty despite fallbackIndex', () {
      terminal.mockInput.queueLine('none');

      final result = FallbackPrompt.multiSelect(
        title: 'Pick many',
        options: ['alpha', 'beta', 'gamma'],
        fallbackIndex: 0,
      );

      expect(result, isEmpty);
    });

    test('singleSelect ignores out-of-range defaultIndex', () {
      terminal.mockInput.queueLine('');

      final result = FallbackPrompt.singleSelect(
        title: 'Pick one',
        options: ['alpha', 'beta', 'gamma'],
        defaultIndex: 999,
      );

      expect(result, isNull);
    });

    test('singleSelect distinguishes EOF from empty default input', () {
      terminal.mockInput.queueLine('');

      final emptyResult = FallbackPrompt.singleSelect(
        title: 'Pick one',
        options: ['alpha', 'beta', 'gamma'],
        defaultIndex: 1,
        returnDefaultOnEndOfInput: false,
      );
      final eofResult = FallbackPrompt.singleSelect(
        title: 'Pick one',
        options: ['alpha', 'beta', 'gamma'],
        defaultIndex: 1,
        returnDefaultOnEndOfInput: false,
      );
      final defaultEofResult = FallbackPrompt.singleSelect(
        title: 'Pick one',
        options: ['alpha', 'beta', 'gamma'],
        defaultIndex: 1,
      );

      expect(emptyResult, 'beta');
      expect(eofResult, isNull);
      expect(defaultEofResult, 'beta');
    });

    test('multiSelect distinguishes EOF from empty default input', () {
      terminal.mockInput.queueLine('');

      final emptyResult = FallbackPrompt.multiSelect(
        title: 'Pick many',
        options: ['alpha', 'beta', 'gamma'],
        defaultIndices: {1, 2},
        returnDefaultOnEndOfInput: false,
      );
      final eofResult = FallbackPrompt.multiSelect(
        title: 'Pick many',
        options: ['alpha', 'beta', 'gamma'],
        defaultIndices: {1, 2},
        returnDefaultOnEndOfInput: false,
      );
      final defaultEofResult = FallbackPrompt.multiSelect(
        title: 'Pick many',
        options: ['alpha', 'beta', 'gamma'],
        defaultIndices: {1, 2},
      );

      expect(emptyResult, ['beta', 'gamma']);
      expect(eofResult, isEmpty);
      expect(defaultEofResult, ['beta', 'gamma']);
    });

    test('number retries bad input and returns a valid value', () {
      terminal.mockInput.queueLines(['nope', '11', '7']);

      final result = FallbackPrompt.number(
        title: 'Count',
        min: 1,
        max: 10,
      );

      expect(result, 7);
      expect(terminal.mockOutput.contains('Enter a number.'), isTrue);
      expect(
          terminal.mockOutput.contains('Enter a number at most 10.'), isTrue);
    });

    test('number retries values not aligned to step from min', () {
      terminal.mockInput.queueLines(['1.2', '1.3']);

      final result = FallbackPrompt.number(
        title: 'Decimal',
        min: 0.1,
        max: 2,
        step: 0.2,
      );

      expect(result, 1.3);
      expect(terminal.mockOutput.contains('increments of 0.2'), isTrue);
    });

    test('number rejects invalid step configuration', () {
      expect(
        () => FallbackPrompt.number(title: 'Invalid', step: 0),
        throwsArgumentError,
      );
    });

    test('number rejects non-finite defaults and bounds before I/O', () {
      final cases = <num? Function()>[
        () => FallbackPrompt.number(
              title: 'Invalid',
              defaultValue: double.nan,
            ),
        () => FallbackPrompt.number(
              title: 'Invalid',
              defaultValue: double.infinity,
            ),
        () => FallbackPrompt.number(
              title: 'Invalid',
              defaultValue: double.negativeInfinity,
            ),
        () => FallbackPrompt.number(
              title: 'Invalid',
              min: double.infinity,
            ),
        () => FallbackPrompt.number(
              title: 'Invalid',
              min: double.nan,
            ),
        () => FallbackPrompt.number(
              title: 'Invalid',
              min: double.negativeInfinity,
            ),
        () => FallbackPrompt.number(
              title: 'Invalid',
              max: double.negativeInfinity,
            ),
        () => FallbackPrompt.number(
              title: 'Invalid',
              max: double.nan,
            ),
        () => FallbackPrompt.number(
              title: 'Invalid',
              max: double.infinity,
            ),
        () => FallbackPrompt.number(
              title: 'Invalid',
              min: -1.7976931348623157e308,
              max: 1.7976931348623157e308,
              step: 0.1,
            ),
      ];

      for (final run in cases) {
        final caseTerminal = MockTerminal();
        TerminalContext.current = caseTerminal;
        expect(run, throwsArgumentError);
        expect(caseTerminal.mockOutput.allOutput, isEmpty);
      }
    });

    test('number normalizes a blank and EOF default to the valid step grid',
        () {
      terminal.mockInput.queueLine('');

      final blankResult = FallbackPrompt.number(
        title: 'Count',
        defaultValue: 99,
        min: 1,
        max: 9,
        step: 3,
      );
      final eofResult = FallbackPrompt.number(
        title: 'Count',
        defaultValue: 3,
        min: 0,
        max: 10,
        step: 2,
      );

      expect(blankResult, 7);
      expect(eofResult, 4);
    });

    test('number rejects non-finite values', () {
      terminal.mockInput.queueLines(['NaN', 'Infinity', '5']);

      final result = FallbackPrompt.number(title: 'Count');

      expect(result, 5);
      expect(terminal.mockOutput.contains('Enter a finite number.'), isTrue);
    });

    test('number accepts null and empty-string validator success', () {
      terminal.mockInput.queueLines(['4', '5']);

      final nullableResult = FallbackPrompt.number(
        title: 'Even',
        validator: (value) => value % 2 == 0 ? null : 'Must be even',
      );
      final legacyResult = FallbackPrompt.number(
        title: 'Positive',
        validator: (value) => value > 0 ? '' : 'Must be positive',
      );

      expect(nullableResult, 4);
      expect(legacyResult, 5);
    });

    test('number distinguishes EOF from empty default input', () {
      terminal.mockInput.queueLine('');

      final emptyResult = FallbackPrompt.number(
        title: 'Count',
        defaultValue: 3,
        returnDefaultOnEndOfInput: false,
      );
      final eofResult = FallbackPrompt.number(
        title: 'Count',
        defaultValue: 3,
        returnDefaultOnEndOfInput: false,
      );
      final defaultEofResult = FallbackPrompt.number(
        title: 'Count',
        defaultValue: 3,
      );

      expect(emptyResult, 3);
      expect(eofResult, isNull);
      expect(defaultEofResult, 3);
    });

    test('range rejects out-of-range input before accepting valid values', () {
      terminal.mockInput.queueLines(['-1', '4', '12', '8']);

      final result = FallbackPrompt.range(
        title: 'Window',
        min: 0,
        max: 10,
      );

      expect(result?.start, 4);
      expect(result?.end, 8);
      expect(
        terminal.mockOutput.contains('Enter a number at least 0.'),
        isTrue,
      );
      expect(
        terminal.mockOutput.contains('Enter a number at most 10.'),
        isTrue,
      );
    });

    test('range orders and clamps fallback defaults after validation', () {
      terminal.mockInput.queueLines(['', '']);

      final result = FallbackPrompt.range(
        title: 'Window',
        startDefault: 20,
        endDefault: -5,
        min: 0,
        max: 10,
      );

      expect(result?.start, 0);
      expect(result?.end, 10);
    });

    test('range snaps and orders blank defaults on the valid step grid', () {
      terminal.mockInput.queueLines(['', '']);

      final result = FallbackPrompt.range(
        title: 'Window',
        startDefault: 10,
        endDefault: 2,
        min: 0,
        max: 9,
        step: 2,
      );

      expect(result?.start, 2);
      expect(result?.end, 8);
    });

    test('range rejects non-finite defaults and invalid bounds before I/O', () {
      final cases = <FallbackRangeResult? Function()>[
        () => FallbackPrompt.range(
              title: 'Invalid',
              startDefault: double.nan,
              endDefault: 2,
            ),
        () => FallbackPrompt.range(
              title: 'Invalid',
              startDefault: 1,
              endDefault: double.infinity,
            ),
        () => FallbackPrompt.range(
              title: 'Invalid',
              startDefault: double.negativeInfinity,
              endDefault: 2,
            ),
        () => FallbackPrompt.range(
              title: 'Invalid',
              min: double.negativeInfinity,
            ),
        () => FallbackPrompt.range(
              title: 'Invalid',
              min: 10,
              max: 0,
            ),
      ];

      for (final run in cases) {
        final caseTerminal = MockTerminal();
        TerminalContext.current = caseTerminal;
        expect(run, throwsArgumentError);
        expect(caseTerminal.mockOutput.allOutput, isEmpty);
      }
    });

    test('range distinguishes EOF from empty default input', () {
      terminal.mockInput.queueLines(['', '']);

      final emptyResult = FallbackPrompt.range(
        title: 'Window',
        startDefault: 2,
        endDefault: 4,
        returnDefaultOnEndOfInput: false,
      );
      final eofResult = FallbackPrompt.range(
        title: 'Window',
        startDefault: 2,
        endDefault: 4,
        returnDefaultOnEndOfInput: false,
      );
      final defaultEofResult = FallbackPrompt.range(
        title: 'Window',
        startDefault: 2,
        endDefault: 4,
      );

      expect(emptyResult?.start, 2);
      expect(emptyResult?.end, 4);
      expect(eofResult, isNull);
      expect(defaultEofResult?.start, 2);
      expect(defaultEofResult?.end, 4);
    });

    test('form retries cross-validator and applies initial values', () {
      terminal.mockInput.queueLines([
        '',
        'first',
        'second',
        '',
        'secret',
        'secret',
      ]);

      final result = FallbackPrompt.form(
        fields: [
          const FallbackFormField(
            label: 'Name',
            initialValue: 'Ada',
            required: true,
          ),
          const FallbackFormField(
            label: 'Password',
            masked: true,
            required: true,
          ),
          const FallbackFormField(
            label: 'Confirm',
            masked: true,
            required: true,
          ),
        ],
        crossValidator: (values) =>
            values[1] != values[2] ? 'Passwords do not match' : null,
      );

      expect(result?.values, ['Ada', 'secret', 'secret']);
      expect(terminal.mockOutput.contains('Passwords do not match'), isTrue);
      expect(terminal.mockOutput.contains('masked'), isTrue);
    });

    test('form treats empty-string cross-validator result as success', () {
      terminal.mockInput.queueLine('Ada');

      final result = FallbackPrompt.form(
        fields: [
          const FallbackFormField(label: 'Name', required: true),
        ],
        crossValidator: (_) => '',
      );

      expect(result?.values, ['Ada']);
    });

    test('form distinguishes EOF from empty initial-value input', () {
      terminal.mockInput.queueLine('');

      final emptyResult = FallbackPrompt.form(
        fields: [
          const FallbackFormField(label: 'Name', initialValue: 'Ada'),
        ],
        returnDefaultOnEndOfInput: false,
      );
      final eofResult = FallbackPrompt.form(
        fields: [
          const FallbackFormField(label: 'Name', initialValue: 'Ada'),
        ],
        returnDefaultOnEndOfInput: false,
      );
      final defaultEofResult = FallbackPrompt.form(
        fields: [
          const FallbackFormField(label: 'Name', initialValue: 'Ada'),
        ],
      );

      expect(emptyResult?.values, ['Ada']);
      expect(eofResult, isNull);
      expect(defaultEofResult?.values, ['Ada']);
    });
  });
}

class _HostileLabel {
  const _HostileLabel(this.value);

  final String value;

  @override
  String toString() => value;
}
