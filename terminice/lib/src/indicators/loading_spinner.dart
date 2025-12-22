import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

extension LoadingSpinnerExtensions on Terminice {
  /// Creates a themed loading spinner with customizable message and style.
  ///
  /// ```dart
  /// final spinner = terminice.loadingSpinner('Loading');
  /// spinner.show(0);
  /// // ... do work ...
  /// spinner.show(1);
  /// spinner.clear();
  /// ```
  LoadingSpinner loadingSpinner(
    String label, {
    String message = 'Loading',
    SpinnerStyle style = SpinnerStyle.dots,
  }) {
    return LoadingSpinner(
      label,
      message: message,
      style: style,
      theme: defaultTheme,
    );
  }
}

/// Theme-aware loading spinner with multiple visual styles.
///
/// Styles: dots (braille), bars (rising/falling), arcs (quarter/half circles).
///
/// **Usage:**
///
/// 1. **Static display** (caller controls updates):
/// ```dart
/// final spinner = LoadingSpinner('Loading');
/// spinner.show(frame: 0);
/// // ... do work ...
/// spinner.show(frame: 1);
/// spinner.clear();
/// ```
///
/// 2. **With callback** (caller drives progress):
/// ```dart
/// LoadingSpinner('Processing').runWith((tick) {
///   for (int i = 0; i < 10; i++) {
///     doWork();
///     tick();
///   }
/// });
/// ```
class LoadingSpinner {
  final String label;
  final String message;
  final SpinnerStyle style;
  final PromptTheme theme;

  RenderOutput? _output;
  bool _started = false;

  /// Creates a loading spinner.
  LoadingSpinner(
    this.label, {
    this.message = 'Loading',
    this.style = SpinnerStyle.dots,
    this.theme = PromptTheme.dark,
  });

  /// Shows the spinner at the given frame.
  void show(int frame) {
    _output ??= RenderOutput();
    final out = _output!;

    if (_started) out.clear();
    _started = true;

    _render(out, frame);
  }

  /// Clears the spinner from the terminal.
  void clear() {
    _output?.clear();
    _output = null;
    _started = false;
  }

  /// Runs the spinner with a callback that provides tick updates.
  void runWith(void Function(void Function() tick) callback) {
    TerminalSession(hideCursor: true).run(() {
      int frame = 0;
      callback(() {
        show(frame++);
      });
      clear();
    });
  }

  void _render(RenderOutput out, int frameIndex) {
    final frames = InlineSpinner.framesForStyle(style);
    final widgetFrame = FrameView(title: label, theme: theme);

    final color = (frameIndex % 2 == 0) ? theme.accent : theme.highlight;

    widgetFrame.showTo(out, (ctx) {
      final spin = frames[frameIndex % frames.length];
      ctx.gutterLine(
          '${theme.dim}$message${theme.reset}  ${theme.bold}$color$spin${theme.reset}');
    });
    final styleName = style.name;

    out.writeln(HintFormat.bullets([
      'Theme-aware spinner',
      'Style: $styleName',
    ], theme, dim: true));
  }
}
