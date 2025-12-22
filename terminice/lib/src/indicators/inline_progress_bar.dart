import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

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
  InlineProgressBar inlineProgressBar(String label) {
    return InlineProgressBar(label, theme: defaultTheme);
  }
}

/// Theme-aware inline progress indicator meant for log-style updates.
///
/// Keeps output to a single terminal line while still showing contextual
/// percent information, making it ideal for CI logs or verbose scripts where a
/// full framed widget would be too heavy.
class InlineProgressBar {
  final String label;
  final PromptTheme theme;

  RenderOutput? _output;
  bool _started = false;

  InlineProgressBar(this.label, {this.theme = PromptTheme.dark});

  /// Renders the current progress percentage next to the label.
  ///
  /// [current] and [total] are used to compute an integer percentage. Values
  /// outside the 0-total range are clamped implicitly by integer rounding.
  void show({required int current, required int total}) {
    _output ??= RenderOutput();
    final out = _output!;

    if (_started) out.clear();
    _started = true;

    final percent = total > 0 ? (current / total * 100).round() : 0;
    out.writeln(
        '${theme.accent}$label${theme.reset} ${theme.dim}$percent%${theme.reset}');
  }

  /// Clears the previous inline output so the next update can redraw cleanly.
  void clear() {
    _output?.clear();
    _output = null;
    _started = false;
  }
}
