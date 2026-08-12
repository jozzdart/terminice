import 'package:terminice/terminice.dart';

import '../progress_display.dart';
import '_indicator_base.dart';

/// Adds the [inlineProgressBar] method to the [Terminice] instance.
extension InlineProgressBarExtensions on Terminice {
  /// Creates a one-line progress readout that mirrors the active theme.
  ///
  /// ```dart
  /// final bar = terminice.inlineProgressBar('Downloading');
  /// bar.show(current: 0, total: 100);
  /// // ... do work ...
  /// bar.show(current: 50, total: 100);
  /// bar.clear();
  /// ```
  ///
  /// The [prompt] is the label displayed next to the percentage.
  InlineProgressBar inlineProgressBar(String prompt) {
    return InlineProgressBar._fromTerminice(prompt, this, theme: defaultTheme);
  }
}

/// Theme-aware inline progress indicator meant for log-style updates.
///
/// Keeps output to a single terminal line while still showing contextual
/// percent information, making it ideal for CI logs or verbose scripts where a
/// full framed widget would be too heavy.
class InlineProgressBar with IndicatorLifecycle {
  /// The text displayed next to the progress percentage.
  final String prompt;

  /// The theme controlling the colors used for the progress bar and text.
  final PromptTheme theme;

  /// Creates a new [InlineProgressBar].
  ///
  /// The [prompt] is the text displayed next to the progress percentage.
  /// The [theme] controls the colors used for the progress bar and text.
  ///
  /// Direct construction captures the ambient terminal and automatically
  /// detected execution mode at construction time. Use
  /// [Terminice.inlineProgressBar] to capture a client's terminal and explicit
  /// fallback policy at creation time.
  InlineProgressBar(this.prompt, {this.theme = PromptTheme.dark}) {
    initializeAutomatically();
  }

  InlineProgressBar._fromTerminice(
    this.prompt,
    Terminice origin, {
    this.theme = PromptTheme.dark,
  }) {
    initializeFromTerminice(origin);
  }

  /// Renders the current progress percentage next to the label.
  ///
  /// [current] and [total] are used to compute an integer percentage. Values
  /// outside the 0-total range are clamped for display.
  void show({required int current, required int total}) {
    final display = progressDisplay(current: current, total: total);
    renderIndicator(
        '$prompt: ${display.percent}% (${display.current}/${display.total})',
        (out) {
      out.writeln(
          '${theme.accent}$prompt${theme.reset} ${theme.dim}${display.percent}%${theme.reset}');
    });
  }
}
