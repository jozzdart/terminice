import 'package:test/test.dart';
import 'package:terminice/terminice.dart';
import 'package:terminice/testing.dart' show MockTerminal;

void main() {
  setUp(TerminalContext.reset);
  tearDown(TerminalContext.reset);

  test('theme demo applies the client color policy to previews', () {
    final terminal = MockTerminal();
    terminal.mockInput.queueByte(27);

    terminice
        .withColorMode(TerminiceColorMode.never)
        .withTerminal(terminal)
        .themeDemo();

    final output = terminal.mockOutput.allOutput;
    expect(output, contains('Theme Preview'));
    expect(output, contains(PromptTheme.dark.glyphs.arrow));
    for (final color in [
      TerminalColors.dark.gray,
      TerminalColors.dark.accent,
      TerminalColors.dark.keyAccent,
      TerminalColors.dark.highlight,
      TerminalColors.dark.selection,
      TerminalColors.dark.checkboxOn,
      TerminalColors.dark.checkboxOff,
      TerminalColors.dark.info,
      TerminalColors.dark.warn,
      TerminalColors.dark.error,
    ]) {
      expect(output, isNot(contains(color)));
    }
  });
}
