import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

extension HotkeyGuideExtensions on Terminice {
  /// Renders an interactive hotkey guide that documents shortcuts and context.
  ///
  /// Provide `shortcuts` as a list of rows, where each row contains one or more
  /// columns (e.g. key combination, action, notes). The guide renders the rows
  /// in a `HintFormat.grid`, so every row should contain the same number of
  /// columns for consistent alignment.
  ///
  /// ```dart
  /// terminice.hotkeyGuide(
  ///   title: 'Selection shortcuts',
  ///   shortcuts: const [
  ///     ['Ctrl+C', 'Copy selection'],
  ///     ['Ctrl+V', 'Paste clipboard'],
  ///     ['Ctrl+Shift+K', 'Delete line'],
  ///   ],
  ///   footer: const ['Esc to close', '? for docs'],
  /// );
  /// ```
  ///
  /// Returns after the user presses `Esc`, `Enter`, or `?`, matching the
  /// declarative key bindings configured below.
  void hotkeyGuide({
    required List<List<String>> shortcuts,
    String title = 'Hotkeys',
    List<String> footer = const ['Esc or ? to close'],
  }) {
    final theme = defaultTheme;
    final footerHints = footer;
    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings([
          KeyBinding.multi(
            {KeyEventType.esc, KeyEventType.enter},
            (event) => KeyActionResult.confirmed,
          ),
          KeyBinding.char(
            (c) => c == '?',
            (event) => KeyActionResult.confirmed,
          ),
        ]) +
        KeyBindings.cancel();

    /// Renders the guide to a RenderOutput.
    void render(RenderOutput out) {
      final widgetFrame = FrameView(
        title: title,
        theme: theme,
      );

      widgetFrame.render(out, (ctx) {
        final body = HintFormat.grid(shortcuts, theme).split('\n');
        for (final line in body) {
          ctx.gutterLine(line);
        }

        if (footerHints.isNotEmpty) {
          ctx.gutterLine(HintFormat.comma(footerHints, theme));
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(
      render: render,
      bindings: bindings,
    );
  }
}
