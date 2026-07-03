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

    test('number rejects non-finite values', () {
      terminal.mockInput.queueLines(['NaN', 'Infinity', '5']);

      final result = FallbackPrompt.number(title: 'Count');

      expect(result, 5);
      expect(terminal.mockOutput.contains('Enter a finite number.'), isTrue);
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
  });
}
