import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

import '_indicator_base.dart';

/// Adds the [progressDots] method to the [Terminice] instance.
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
  ///
  /// The [prompt] is the label displayed above the dots.
  ProgressDots progressDots(String prompt) {
    return ProgressDots(prompt, theme: defaultTheme);
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
class ProgressDots with IndicatorLifecycle {
  /// The label displayed above the dots.
  final String prompt;

  /// The text displayed next to the dots.
  final String message;

  /// The maximum number of dots in the animation sequence.
  final int maxDots;

  /// The theme controlling the colors used for the dots and text.
  final PromptTheme theme;

  /// Creates a new [ProgressDots] indicator.
  ///
  /// The [prompt] is the label displayed above the dots.
  /// The [message] is the text displayed next to the dots.
  /// The [maxDots] controls the maximum number of dots in the animation sequence.
  /// The [theme] controls the colors used for the dots and text.
  ProgressDots(
    this.prompt, {
    this.message = 'Working',
    this.maxDots = 3,
    this.theme = PromptTheme.dark,
  }) : assert(maxDots > 0);

  /// Shows the dots at the given phase.
  void show({required int phase}) {
    final out = prepareFrame();
    _render(out, phase);
  }

  /// Runs with a callback that provides tick updates.
  void runWith(void Function(void Function() tick) callback) {
    runSession(() {
      int phase = 0;
      callback(() {
        show(phase: phase++);
      });
    });
  }

  void _render(RenderOutput out, int phase) {
    final widgetFrame = FrameView(title: prompt, theme: theme);
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
