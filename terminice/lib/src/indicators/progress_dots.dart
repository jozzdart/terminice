import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

extension ProgressDotsExtensions on Terminice {
  /// Creates a themed dot indicator for lightweight progress feedback.
  ///
  /// ```dart
  /// final dots = terminice.progressDots('Loading');
  /// dots.show(phase: 0);
  /// // ... do work ...
  /// dots.show(phase: 1);
  /// dots.clear();
  /// ```
  ProgressDots progressDots(String label) {
    return ProgressDots(label, theme: defaultTheme);
  }
}

/// Frame-based dots indicator for ambient progress feedback.
///
/// Customize the [message] that precedes the dots or tune [maxDots] for longer
/// or shorter animation ramps without changing your rendering loop.
///
/// **Usage:**
///
/// 1. **Static display** (caller controls updates):
/// ```dart
/// final dots = ProgressDots('Loading');
/// dots.show(phase: 0);
/// // ... do work ...
/// dots.show(phase: 1);
/// dots.clear();
/// ```
///
/// 2. **With callback** (caller provides updates):
/// ```dart
/// ProgressDots('Processing').runWith((tick) {
///   for (int i = 0; i < 10; i++) {
///     doWork();
///     tick();
///   }
/// });
/// ```
class ProgressDots {
  final String label;
  final String message;
  final int maxDots;
  final PromptTheme theme;

  RenderOutput? _output;
  bool _started = false;

  ProgressDots(
    this.label, {
    this.message = 'Working',
    this.maxDots = 3,
    this.theme = PromptTheme.dark,
  }) : assert(maxDots > 0);

  /// Shows the dots at the given phase.
  void show({required int phase}) {
    _output ??= RenderOutput();
    final out = _output!;

    if (_started) out.clear();
    _started = true;

    _render(out, phase);
  }

  /// Clears the dots from the terminal.
  void clear() {
    _output?.clear();
    _output = null;
    _started = false;
  }

  /// Runs with a callback that provides tick updates.
  void runWith(void Function(void Function() tick) callback) {
    TerminalSession(hideCursor: true).run(() {
      int phase = 0;
      callback(() {
        show(phase: phase++);
      });
      clear();
    });
  }

  void _render(RenderOutput out, int phase) {
    final widgetFrame = FrameView(title: label, theme: theme);
    widgetFrame.showTo(out, (ctx) {
      final dots = '.' * ((phase % (maxDots + 1)));
      ctx.gutterLine(
          '${theme.dim}$message${theme.reset} ${theme.accent}$dots${theme.reset}');
    });

    out.writeln(HintFormat.bullets([
      'Dots indicator',
      'Theme-aligned borders',
    ], theme, dim: true));
  }
}
