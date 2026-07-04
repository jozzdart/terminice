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

    test('Configurable.trySetValue rejects invalid candidates', () {
      final field = StringConfigurable(
        key: 'name',
        label: 'Name',
        value: 'Ada',
        validator: (value) => value == 'Grace' ? '' : 'Wrong value',
      );

      expect(field.validationErrorFor('Grace'), isNull);
      expect(field.trySetValue('Linus'), isFalse);
      expect(field.value, 'Ada');
      expect(field.trySetValue('Grace'), isTrue);
      expect(field.value, 'Grace');
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

    group('configurable edit validation', () {
      test('BoolConfigurable rejects invalid candidates', () {
        final field = BoolConfigurable(
          key: 'enabled',
          label: 'Enabled',
          value: true,
          validator: (value) => value ? null : 'Must stay enabled',
        );

        final edited = field.edit(_fallbackWithLines(['no']));

        expect(edited, isFalse);
        expect(field.value, isTrue);
      });

      test('StringConfigurable rejects invalid candidates', () {
        final field = StringConfigurable(
          key: 'name',
          label: 'Name',
          value: 'Ada',
          validator: (value) => value == 'Ada' ? null : 'Wrong value',
        );

        final edited = field.edit(_fallbackWithLines(['bad']));

        expect(edited, isFalse);
        expect(field.value, 'Ada');
      });

      test('PasswordConfigurable rejects invalid candidates', () {
        final field = PasswordConfigurable(
          key: 'secret',
          label: 'Secret',
          value: 'correct',
          validator: (value) => value == 'correct' ? null : 'Wrong value',
        );

        final edited = field.edit(_fallbackWithLines(['bad']));

        expect(edited, isFalse);
        expect(field.value, 'correct');
      });

      test('NumberConfigurable text input rejects invalid candidates', () {
        final field = NumberConfigurable(
          key: 'count',
          label: 'Count',
          value: 1,
          min: 0,
          max: 10,
          validator: (value) => value < 3 ? null : 'Too high',
        );

        final edited = field.edit(_fallbackWithLines(['4']));

        expect(edited, isFalse);
        expect(field.value, 1);
      });

      test('NumberConfigurable slider rejects invalid candidates', () {
        final field = NumberConfigurable(
          key: 'count',
          label: 'Count',
          value: 1,
          min: 0,
          max: 10,
          useSlider: true,
          validator: (value) => value < 3 ? null : 'Too high',
        );

        final edited = field.edit(_fallbackWithLines(['4']));

        expect(edited, isFalse);
        expect(field.value, 1);
      });

      test('EnumConfigurable rejects invalid candidates', () {
        final field = EnumConfigurable(
          key: 'theme',
          label: 'Theme',
          value: 'dark',
          options: const ['dark', 'light'],
          validator: (value) => value == 'dark' ? null : 'Wrong value',
        );

        final edited = field.edit(_fallbackWithLines(['2']));

        expect(edited, isFalse);
        expect(field.value, 'dark');
      });

      test('RangeConfigurable rejects invalid candidates', () {
        final field = RangeConfigurable(
          key: 'window',
          label: 'Window',
          start: 1,
          end: 2,
          min: 0,
          max: 10,
          validator: (value) => value.end <= 3 ? null : 'Too high',
        );

        final edited = field.edit(_fallbackWithLines(['4', '6']));

        expect(edited, isFalse);
        expect(field.value, RangeValue(1, 2));
      });

      test('RatingConfigurable rejects invalid candidates', () {
        final field = RatingConfigurable(
          key: 'rating',
          label: 'Rating',
          value: 1,
          maxStars: 5,
          validator: (value) => value <= 2 ? null : 'Too high',
        );

        final edited = field.edit(_fallbackWithLines(['4']));

        expect(edited, isFalse);
        expect(field.value, 1);
      });

      test('ThemeConfigurable rejects invalid candidates', () {
        var onChangedCalls = 0;
        final field = ThemeConfigurable(
          key: 'theme',
          label: 'Theme',
          value: 'dark',
          themes: const {
            'dark': PromptTheme.dark,
            'light': PromptTheme.minimal,
          },
          validator: (value) => value == 'dark' ? null : 'Wrong value',
          onChanged: (_) => onChangedCalls++,
        );

        final edited = field.edit(_fallbackWithLines(['2']));

        expect(edited, isFalse);
        expect(field.value, 'dark');
        expect(onChangedCalls, 0);
      });
    });
  });
}

Terminice _fallbackWithLines(List<String> lines) {
  final mock = MockTerminal();
  mock.mockInput.queueLines(lines);
  return terminice.fallback.withTerminal(mock);
}
