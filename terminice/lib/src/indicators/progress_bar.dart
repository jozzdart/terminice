import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

import '_indicator_base.dart';

/// Adds the [progressBar] method to the [Terminice] instance.
extension ProgressBarExtensions on Terminice {
  /// Creates a progress bar indicator.
  ///
  /// ```dart
  /// final bar = terminice.progressBar('Downloading');
  /// bar.show(current: 0, total: 100);
  /// // ... do work ...
  /// bar.show(current: 50, total: 100);
  /// bar.clear();
  /// ```
  ///
  /// The [prompt] is the label displayed above the progress bar.
  ProgressBar progressBar(String prompt) {
    return ProgressBar(prompt, theme: defaultTheme);
  }
}

/// Themed progress bar for displaying determinate progress.
///
/// **Usage:**
///
/// 1. **Static display** (caller controls updates):
/// ```dart
/// final bar = ProgressBar('Downloading');
/// bar.show(current: 0, total: 100);
/// // ... do work ...
/// bar.show(current: 50, total: 100);
/// bar.clear();
/// ```
///
/// 2. **With callback** (caller provides progress):
/// ```dart
/// ProgressBar('Processing').runWith((update) {
///   for (int i = 0; i <= 100; i++) {
///     update(i, 100);
///   }
/// });
/// ```
class ProgressBar with IndicatorLifecycle {
  /// The label displayed above the progress bar.
  final String prompt;

  /// The width of the progress bar in characters.
  final int width;

  /// The theme controlling the colors used for the progress bar and text.
  final PromptTheme theme;

  /// Creates a progress bar.
  ///
  /// The [prompt] is the label displayed above the progress bar.
  /// The optional [width] lets you dial in the bar footprint to match the
  /// caller's terminal columns while keeping the shimmer effect intact.
  /// The [theme] controls the colors used for the progress bar and text.
  ProgressBar(
    this.prompt, {
    this.width = 36,
    this.theme = PromptTheme.dark,
  }) : assert(width > 4);

  /// Shows the progress bar at the given progress.
  void show({
    required int current,
    required int total,
    int shimmerPhase = 0,
  }) {
    final out = prepareFrame();
    _render(out, current, total, shimmerPhase);
  }

  /// Runs the progress bar with a callback that provides updates.
  void runWith(
      void Function(void Function(int current, int total) update) callback) {
    runSession(() {
      int phase = 0;
      callback((current, total) {
        show(current: current, total: total, shimmerPhase: phase++);
      });
    });
  }

  void _render(RenderOutput out, int current, int total, int shimmerPhase) {
    final widgetFrame = FrameView(title: prompt, theme: theme);
    widgetFrame.showTo(out, (ctx) {
      final ratio = total > 0 ? current / total : 0.0;
      final filled = (ratio * width).clamp(0, width).round();
      final percent = (ratio * 100).clamp(0, 100).round();

      final buffer = StringBuffer();
      for (int i = 0; i < width; i++) {
        final isFilled = i < filled;
        if (!isFilled) {
          buffer.write('${theme.dim}·${theme.reset}');
          continue;
        }

        final headPos = filled - 1;
        final distance = (i - headPos).abs();
        final headGlow = (3 - distance).clamp(0, 3);

        final cycle = ((i + shimmerPhase) % 6);
        final baseColor = (cycle < 3) ? theme.accent : theme.highlight;

        const shades = ['░', '▒', '▓', '█'];
        final ch = shades[headGlow.clamp(0, 3)];

        if (i == headPos) {
          buffer.write('${theme.inverse}$baseColor$ch${theme.reset}');
        } else if (headGlow > 0) {
          buffer.write('${theme.bold}$baseColor$ch${theme.reset}');
        } else {
          buffer.write('$baseColor$ch${theme.reset}');
        }
      }

      ctx.gutterLine(buffer.toString());
      ctx.gutterLine(
          '${theme.dim}Progress:${theme.reset} ${theme.accent}$percent%${theme.reset}   '
          '${theme.dim}($current/$total)${theme.reset}');
    });

    out.writeln(HintFormat.bullets([
      'Progress bar',
      'Theme-aware accents',
    ], theme, dim: true));
  }
}
