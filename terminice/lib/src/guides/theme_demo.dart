import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

extension ThemeDemoExtensions on Terminice {
  /// Launches an interactive theme gallery for previewing bundled `PromptTheme`s.
  ///
  /// Users can cycle through curated themes before optionally launching a
  /// sample `searchSelector` that adopts the currently highlighted theme. This
  /// is helpful when documenting design guidelines, onboarding users to the
  /// library, or preparing screenshots for pub.dev.
  ///
  /// Controls:
  /// - `↑ / ↓`: Move between available themes.
  /// - `Enter`: Accept and open the preview prompt.
  /// - `Esc`: Exit the demo without launching the prompt.
  void themeDemo() {
    final themes = {
      'Dark': PromptTheme.dark,
      'Matrix': PromptTheme.matrix,
      'Fire': PromptTheme.fire,
      'Pastel': PromptTheme.pastel,
      'Ocean': PromptTheme.ocean,
      'Monochrome': PromptTheme.monochrome,
      'Neon': PromptTheme.neon,
      'Arcane': PromptTheme.arcane,
      'Phantom': PromptTheme.phantom,
    };
    final themeNames = themes.keys.toList();

    // Use centralized focus navigation
    final focus = FocusNavigator(itemCount: themeNames.length);
    String selected = themeNames.first;
    bool showPromptPreview = false;

    void renderThemePreview(RenderOutput out, String name, PromptTheme theme) {
      final glyphs = theme.glyphs;

      final widgetFrame = FrameView(
        title: 'Theme Preview',
        theme: theme,
      );

      widgetFrame.render(out, (ctx) {
        ctx.labeledAccent('Theme', name);
        ctx.gutterLine('Arrow: ${theme.accent}${glyphs.arrow}${theme.reset}');
        ctx.gutterLine(
            'Checkbox: ${theme.checkboxOn}${glyphs.checkboxOnSymbol}${theme.reset} / ${theme.checkboxOff}${glyphs.checkboxOffSymbol}${theme.reset}');
        ctx.gutterLine(
            'Border: ${theme.selection}${glyphs.borderTop}${glyphs.borderConnector}${glyphs.borderBottom}${theme.reset}');
        ctx.gutterLine(
            'Highlight: ${theme.highlight}Highlight text${theme.reset}');
        ctx.gutterLine(
            'Inverse: ${theme.inverse} Inverted line ${theme.reset}');
      });

      out.writeln(
          '${theme.gray}${glyphs.borderBottom}${glyphs.borderHorizontal * 25}${theme.reset}');
      out.writeln(HintFormat.bullets([
        '↑↓ to browse',
        'Enter to preview prompt',
        'Esc to exit',
      ], theme, dim: true));
    }

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings.verticalNavigation(
          onUp: () {
            focus.moveUp();
            selected = themeNames[focus.focusedIndex];
          },
          onDown: () {
            focus.moveDown();
            selected = themeNames[focus.focusedIndex];
          },
        ) +
        KeyBindings.confirm(onConfirm: () {
          showPromptPreview = true;
          return KeyActionResult.confirmed;
        }) +
        KeyBindings.cancel();

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(
      render: (out) => renderThemePreview(out, selected, themes[selected]!),
      bindings: bindings,
    );

    if (showPromptPreview) {
      final fruits = [
        'apple',
        'banana',
        'cherry',
        'date',
        'fig',
        'grape',
        'lemon',
        'mango',
        'pear',
        'plum',
      ];
      themed(themes[selected]!).searchSelector(
        options: fruits,
        prompt: 'Previewing theme: $selected',
        multiSelect: true,
      );
    }
  }
}
