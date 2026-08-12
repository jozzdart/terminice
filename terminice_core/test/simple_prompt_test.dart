import 'package:terminice_core/testing.dart';
import 'package:test/test.dart';

void main() {
  late MockTerminal terminal;

  setUp(() {
    terminal = MockTerminal();
    TerminalContext.current = terminal;
  });

  tearDown(TerminalContext.reset);

  group('SimplePrompts.confirm', () {
    test('defaults to No', () {
      terminal.mockInput.queueKey(KeyEventType.enter);

      expect(
        SimplePrompts.confirm(title: 'Confirm', message: 'Continue?').run(),
        isFalse,
      );
    });

    test('explicit defaultYes selects Yes', () {
      terminal.mockInput.queueKey(KeyEventType.enter);

      expect(
        SimplePrompts.confirm(
          title: 'Confirm',
          message: 'Continue?',
          defaultYes: true,
        ).run(),
        isTrue,
      );
    });
  });

  group('SimplePrompts.number', () {
    test('cancel returns the exact supplied initial value', () {
      terminal.mockInput.queueKey(KeyEventType.esc);

      final result = SimplePrompts.number(
        title: 'Count',
        initial: 42,
        min: 0,
        max: 10,
      ).run();

      expect(result, 42);
    });

    test('confirm uses the clamped interactive start value', () {
      terminal.mockInput.queueKey(KeyEventType.enter);

      final result = SimplePrompts.number(
        title: 'Count',
        initial: 42,
        min: 0,
        max: 10,
      ).run();

      expect(result, 10);
    });
  });
}
