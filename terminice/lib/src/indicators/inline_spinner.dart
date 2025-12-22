import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

extension InlineSpinnerExtensions on Terminice {
  /// Creates a lightweight spinner that stays on a single console line.
  ///
  /// ```dart
  /// final spinner = terminice.inlineSpinner('Loading');
  /// spinner.show(0);
  /// // ... do work ...
  /// spinner.show(1);
  /// spinner.clear();
  /// ```
  InlineSpinner inlineSpinner(
    String message, {
    SpinnerStyle style = SpinnerStyle.dots,
  }) {
    return InlineSpinner(
      message,
      style: style,
      theme: defaultTheme,
    );
  }
}

/// Minimal spinner intended for inline log output.
///
/// It renders the current frame along with a dimmed status message so you can
/// surface progress in long-running CLI tasks without taking over the screen.
class InlineSpinner {
  final String message;
  final SpinnerStyle style;
  final PromptTheme theme;

  RenderOutput? _output;
  bool _started = false;

  InlineSpinner(
    this.message, {
    this.style = SpinnerStyle.dots,
    this.theme = PromptTheme.dark,
  });

  /// Renders the spinner frame indicated by [frame].
  void show(int frame) {
    _output ??= RenderOutput();
    final out = _output!;

    if (_started) out.clear();
    _started = true;

    final frames = framesForStyle(style);
    final spin = frames[frame % frames.length];
    out.writeln(
        '${theme.accent}$spin${theme.reset} ${theme.dim}$message${theme.reset}');
  }

  /// Clears the rendered spinner and frees the underlying buffer.
  void clear() {
    _output?.clear();
    _output = null;
    _started = false;
  }

  /// Returns the list of Unicode frames used by the configured [SpinnerStyle].
  static List<String> framesForStyle(SpinnerStyle s) {
    switch (s) {
      case SpinnerStyle.dots:
        return const ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
      case SpinnerStyle.bars:
        return const [
          '▁',
          '▂',
          '▃',
          '▄',
          '▅',
          '▆',
          '▇',
          '█',
          '▇',
          '▆',
          '▅',
          '▄',
          '▃',
          '▂'
        ];
      case SpinnerStyle.arcs:
        return const ['◜', '◠', '◝', '◞', '◡', '◟'];
    }
  }
}

/// Available visual styles for spinners and shimmer effects.
///
/// - `dots`: Braille-inspired glyphs with fluid motion.
/// - `bars`: Rising bar graph that loops over a wave.
/// - `arcs`: Rotating quarter/half circles for a softer feel.
enum SpinnerStyle { dots, bars, arcs }

extension SpinnerStyleExtensions on SpinnerStyle {
  String get name {
    switch (this) {
      case SpinnerStyle.dots:
        return 'Dots';
      case SpinnerStyle.bars:
        return 'Bars';
      case SpinnerStyle.arcs:
        return 'Arcs';
    }
  }
}
