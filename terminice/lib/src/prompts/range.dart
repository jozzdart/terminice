import 'dart:math' as math;

import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Dual-handle range prompt for selecting a numeric or percentage span.
///
/// Controls:
/// - ← / → adjust the active handle by `step`
/// - ↑ / ↓ or Space switches between start/end handles
/// - Enter confirms
/// - Esc / Ctrl+C cancel (returns the initial values)
///
/// ```dart
/// final (start, end) = terminice.range(
///   'Memory budget',
///   startInitial: 2,
///   endInitial: 8,
///   unit: 'GB',
/// );
/// ```
extension RangePromptExtensions on Terminice {
  /// Range prompt for selecting a `(start, end)` tuple.
  ///
  /// Returns `(start, end)` inclusive of the provided bounds.
  ///
  /// **Example:**
  /// ```dart
  /// final (from, to) = terminice.range('Quiet hours', unit: 'h');
  /// ```
  RangeResult range(
    String label, {
    num min = 0,
    num max = 100,
    num startInitial = 20,
    num endInitial = 80,
    num step = 1,
    int width = 28,
    String unit = '%',
  }) {
    final theme = defaultTheme;
    final rangePrompt = RangeValuePrompt(
      title: label,
      min: min,
      max: max,
      startInitial: startInitial,
      endInitial: endInitial,
      step: step,
      theme: theme,
    );

    void renderBar(
      FrameContext ctx,
      num start,
      num end,
      bool editingStart,
    ) {
      // Effective width (responsive to terminal columns)
      final effWidth = math.max(10, math.min(width, TerminalInfo.columns - 8));

      int valueToIndex(num v, int w) {
        final ratio = (v - min) / (max - min);
        return (ratio * w).round().clamp(0, w);
      }

      // Compute positions
      final startIdx = valueToIndex(start, effWidth);
      final endIdx = valueToIndex(end, effWidth);

      // Format values
      final sRaw = (start == start.roundToDouble()
              ? start.toInt().toString()
              : start.toStringAsFixed(1)) +
          unit;
      final eRaw = (end == end.roundToDouble()
              ? end.toInt().toString()
              : end.toStringAsFixed(1)) +
          unit;

      // Layout
      final displayLen = sRaw.length + 1 + eRaw.length;
      final centerIdx = ((startIdx + endIdx) / 2).round();
      final leftPad = math.max(0, centerIdx - (displayLen ~/ 2));

      // Range text
      final rangeTxt = '${theme.bold}${theme.accent}$sRaw—$eRaw${theme.reset}';

      final border = '${theme.gray}┃${theme.reset}';
      final activeIdx = editingStart ? startIdx : endIdx;

      // Caret pointer
      ctx.line('$border${' ' * (2 + activeIdx)}${theme.accent}^${theme.reset}');
      ctx.line('$border${' ' * (2 + leftPad)}$rangeTxt');

      // Bar with handles
      final barLine = StringBuffer();
      barLine.write('$border ');
      for (int i = 0; i <= effWidth; i++) {
        if (i == startIdx) {
          final isActive = editingStart;
          String glyph;
          if (isActive) {
            glyph = '${theme.inverse}${theme.accent}█${theme.reset}';
          } else {
            glyph = '${theme.accent}█${theme.reset}';
          }
          barLine.write(glyph);
        } else if (i == endIdx) {
          final isActive = !editingStart;
          String glyph;
          if (isActive) {
            glyph = '${theme.inverse}${theme.accent}█${theme.reset}';
          } else {
            glyph = '${theme.accent}█${theme.reset}';
          }
          barLine.write(glyph);
        } else if (i > startIdx && i < endIdx) {
          barLine.write('${theme.accent}━${theme.reset}');
        } else if (i < effWidth) {
          barLine.write('${theme.dim}·${theme.reset}');
        }
      }
      ctx.line(barLine.toString());

      // Active indicator
      final activeLabel = editingStart ? 'start' : 'end';
      ctx.labeledAccent('Active', activeLabel);
    }

    return rangePrompt.run(
      render: (ctx, start, end, editingStart) {
        renderBar(
          ctx,
          start,
          end,
          editingStart,
        );
      },
    );
  }
}
