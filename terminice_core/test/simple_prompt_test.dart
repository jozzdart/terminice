import 'package:terminice_core/testing.dart';
import 'package:test/test.dart';

void main() {
  late MockTerminal terminal;

  setUp(() {
    terminal = MockTerminal();
    TerminalContext.current = terminal;
  });

  tearDown(TerminalContext.reset);

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
