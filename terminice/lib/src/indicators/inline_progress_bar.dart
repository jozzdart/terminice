import 'package:terminice/terminice.dart';

import '_indicator_base.dart';

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
  InlineProgressBar inlineProgressBar(String prompt) {
    return InlineProgressBar(prompt, theme: defaultTheme);
  }
}

/// Theme-aware inline progress indicator meant for log-style updates.
///
/// Keeps output to a single terminal line while still showing contextual
/// percent information, making it ideal for CI logs or verbose scripts where a
/// full framed widget would be too heavy.
class InlineProgressBar with IndicatorLifecycle {
  final String prompt;
  final PromptTheme theme;

  InlineProgressBar(this.prompt, {this.theme = PromptTheme.dark});

  /// Renders the current progress percentage next to the label.
  ///
  /// [current] and [total] are used to compute an integer percentage. Values
  /// outside the 0-total range are clamped implicitly by integer rounding.
  void show({required int current, required int total}) {
    final out = prepareFrame();
    final percent = total > 0 ? (current / total * 100).round() : 0;
    out.writeln(
        '${theme.accent}$prompt${theme.reset} ${theme.dim}$percent%${theme.reset}');
  }
}
