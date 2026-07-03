import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart' show KeyEventType;
import 'package:test/test.dart';

import 'mock_terminal.dart';

void main() {
  group('datePicker', () {
    setUp(TerminalContext.reset);
    tearDown(TerminalContext.reset);

    test('defaults still allow moving into past dates', () {
      final mock = MockTerminal();
      mock.mockInput.queueKey(KeyEventType.arrowLeft);
      mock.mockInput.queueKey(KeyEventType.enter);

      final result = Terminice(terminal: mock).datePicker(
        'Pick date',
        initialDate: DateTime(2026, 1, 15),
      );

      expect(result, DateTime(2026, 1, 14));
    });

    test('allowPast false clamps an initial past date to today', () {
      final before = _today();
      final mock = MockTerminal();
      mock.mockInput.queueKey(KeyEventType.enter);

      final result = Terminice(terminal: mock).datePicker(
        'Pick date',
        initialDate: before.subtract(const Duration(days: 30)),
        allowPast: false,
      );

      _expectToday(result, before, _today());
    });

    test('allowFuture false clamps an initial future date to today', () {
      final before = _today();
      final mock = MockTerminal();
      mock.mockInput.queueKey(KeyEventType.enter);

      final result = Terminice(terminal: mock).datePicker(
        'Pick date',
        initialDate: before.add(const Duration(days: 30)),
        allowFuture: false,
      );

      _expectToday(result, before, _today());
    });

    test('allowPast false blocks day, week, and year navigation before today',
        () {
      final before = _today();
      final mock = MockTerminal();
      mock.mockInput.queueKey(KeyEventType.arrowLeft);
      mock.mockInput.queueKey(KeyEventType.arrowUp);
      mock.mockInput.queueKey(KeyEventType.char, 's');
      mock.mockInput.queueKey(KeyEventType.enter);

      final result = Terminice(terminal: mock).datePicker(
        'Pick date',
        initialDate: before,
        allowPast: false,
      );

      _expectToday(result, before, _today());
    });

    test('allowFuture false blocks day, week, and year navigation after today',
        () {
      final before = _today();
      final mock = MockTerminal();
      mock.mockInput.queueKey(KeyEventType.arrowRight);
      mock.mockInput.queueKey(KeyEventType.arrowDown);
      mock.mockInput.queueKey(KeyEventType.char, 'w');
      mock.mockInput.queueKey(KeyEventType.enter);

      final result = Terminice(terminal: mock).datePicker(
        'Pick date',
        initialDate: before,
        allowFuture: false,
      );

      _expectToday(result, before, _today());
    });

    test('Ctrl+E jumps to date-only today', () {
      final before = _today();
      final mock = MockTerminal();
      mock.mockInput.queueKey(KeyEventType.ctrlE);
      mock.mockInput.queueKey(KeyEventType.enter);

      final result = Terminice(terminal: mock).datePicker(
        'Pick date',
        initialDate: before.add(const Duration(days: 10)),
      );

      _expectToday(result, before, _today());
      expect(result, _dateOnly(result!));
    });

    test('cancel returns null', () {
      final mock = MockTerminal();
      mock.mockInput.queueKey(KeyEventType.esc);

      final result = Terminice(terminal: mock).datePicker(
        'Pick date',
        initialDate: DateTime(2026, 1, 15),
        allowPast: false,
      );

      expect(result, isNull);
    });
  });
}

DateTime _today() => _dateOnly(DateTime.now());

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

void _expectToday(DateTime? value, DateTime before, DateTime after) {
  expect(value, isNotNull);
  expect(value, _dateOnly(value!));
  expect(
    value == before || value == after,
    isTrue,
    reason: 'expected $value to be today ($before or $after)',
  );
}
