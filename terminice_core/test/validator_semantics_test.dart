import 'package:terminice_core/testing.dart';
import 'package:test/test.dart';

void main() {
  late MockTerminal terminal;

  setUp(() {
    terminal = MockTerminal();
    TerminalContext.current = terminal;
  });

  tearDown(TerminalContext.reset);

  group('validator semantics', () {
    test('TextPromptSync treats null as validator success', () {
      terminal.mockInput
        ..queueString('ada')
        ..queueKey(KeyEventType.enter);

      final result = TextPromptSync(
        title: 'Name',
        validator: (value) => value == 'ada' ? null : 'Wrong value',
      ).run();

      expect(result, 'ada');
    });

    test('TextPromptSync treats empty string as validator success', () {
      terminal.mockInput
        ..queueString('ada')
        ..queueKey(KeyEventType.enter);

      final result = TextPromptSync(
        title: 'Name',
        validator: (value) => value == 'ada' ? '' : 'Wrong value',
      ).run();

      expect(result, 'ada');
    });

    test('FormPrompt treats null and empty string as validator success', () {
      terminal.mockInput
        ..queueString('ada')
        ..queueKey(KeyEventType.enter);

      final result = FormPrompt(
        title: 'Profile',
        fields: [
          FormFieldConfig(
            label: 'Name',
            validator: (value) => value == 'ada' ? null : 'Wrong value',
          ),
        ],
        crossValidator: (_) => '',
      ).run();

      expect(result?.values, ['ada']);
    });
  });
}
