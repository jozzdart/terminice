import 'package:terminice/terminice.dart';
import 'package:test/test.dart';

import 'mock_terminal.dart';

void main() {
  setUp(TerminalContext.reset);
  tearDown(TerminalContext.reset);

  group('validator semantics', () {
    test('text fallback accepts null and empty-string validator success', () {
      final mock = MockTerminal();
      mock.mockInput.queueLines(['Ada', 'Grace']);

      final t = terminice.fallback.withTerminal(mock);

      expect(
        t.text(
          'Name',
          validator: (value) => value == 'Ada' ? null : 'Wrong value',
        ),
        'Ada',
      );
      expect(
        t.text(
          'Name',
          validator: (value) => value == 'Grace' ? '' : 'Wrong value',
        ),
        'Grace',
      );
    });

    test('Configurable.validate normalizes empty-string success', () {
      final field = StringConfigurable(
        key: 'name',
        label: 'Name',
        value: 'Ada',
        validator: (_) => '',
      );

      expect(field.validate(), isNull);
    });

    test('StringConfigurable edit passes nullable validator through', () {
      final mock = MockTerminal();
      mock.mockInput.queueLine('Ada');
      final field = StringConfigurable(
        key: 'name',
        label: 'Name',
        validator: (value) => value == 'Ada' ? null : 'Wrong value',
      );

      final edited = field.edit(terminice.fallback.withTerminal(mock));

      expect(edited, isTrue);
      expect(field.value, 'Ada');
    });

    test('NumberConfigurable edit passes nullable validator through', () {
      final mock = MockTerminal();
      mock.mockInput.queueLine('42');
      final field = NumberConfigurable(
        key: 'port',
        label: 'Port',
        value: 1,
        min: 1,
        max: 100,
        validator: (value) => value == 42 ? null : 'Wrong value',
      );

      final edited = field.edit(terminice.fallback.withTerminal(mock));

      expect(edited, isTrue);
      expect(field.value, 42);
    });

    test(
        'EnumConfigurable edit treats empty-string validator result as success',
        () {
      final mock = MockTerminal();
      mock.mockInput.queueLine('2');
      final field = EnumConfigurable(
        key: 'theme',
        label: 'Theme',
        value: 'dark',
        options: const ['dark', 'light'],
        validator: (_) => '',
      );

      final edited = field.edit(terminice.fallback.withTerminal(mock));

      expect(edited, isTrue);
      expect(field.value, 'light');
    });
  });
}
