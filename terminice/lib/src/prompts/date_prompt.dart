import 'package:intl/intl.dart';

import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Adds the production-grade, keyboard-first `date` prompt to `Terminice`.
///
/// The widget renders dedicated Day/Month/Year fields with inline hints so
/// operators always know which shortcuts are available. Use [Terminice.date]
/// to collect calendar-safe dates without building custom UI.
extension DatePromptExtensions on Terminice {
  /// Presents an accessible, multi-field date selector with live preview.
  ///
  /// Users edit day, month, and year independently while the prompt keeps the
  /// time component zeroed and surfaces a formatted preview for validation.
  ///
  /// ### Parameters
  /// - `label` – Title shown at the top of the frame. Falls back to `"Date"`
  ///   when left blank so prompts stay branded.
  /// - `initial` – Optional starting value. Only the date portion is used; the
  ///   time-of-day gets stripped to avoid timezone drift.
  ///
  /// ### Controls
  /// - ←/→ switch between fields
  /// - ↑/↓ adjust the active field
  /// - [Ctrl+E] jump to the current day
  /// - [Enter] confirm selection
  /// - [Esc] cancel and return `null`
  ///
  /// Returns the finalized `DateTime` in the local timezone, or `null` if the
  /// user cancels.
  ///
  /// ### Example
  /// ```dart
  /// final date = terminice.date('Launch date', initial: DateTime(2025, 12, 14));
  /// print(date); // -> 2025-12-14 00:00:00.000
  /// ```
  DateTime? date(
    String label, {
    DateTime? initial,
  }) {
    if (label.isEmpty) label = 'Date';
    final theme = defaultTheme;
    final initialDate = initial ?? DateTime.now();

    DateTime selected =
        DateTime(initialDate.year, initialDate.month, initialDate.day);
    int fieldIndex = 0; // 0=day, 1=month, 2=year
    bool cancelled = false;

    void adjustField(int delta) {
      switch (fieldIndex) {
        case 0:
          selected = selected.add(Duration(days: delta));
          break;
        case 1:
          selected = DateTime(
            selected.year,
            selected.month + delta,
            selected.day,
          );
          break;
        case 2:
          selected = DateTime(
            selected.year + delta,
            selected.month,
            selected.day,
          );
          break;
      }
    }

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings([
          // ←/→ switch field
          KeyBinding.single(
            KeyEventType.arrowLeft,
            (event) {
              fieldIndex = (fieldIndex - 1).clamp(0, 2);
              return KeyActionResult.handled;
            },
            hintLabel: '←/→',
            hintDescription: 'switch',
          ),
          KeyBinding.single(
            KeyEventType.arrowRight,
            (event) {
              fieldIndex = (fieldIndex + 1).clamp(0, 2);
              return KeyActionResult.handled;
            },
          ),
          // ↑/↓ adjust field
          KeyBinding.single(
            KeyEventType.arrowUp,
            (event) {
              adjustField(1);
              return KeyActionResult.handled;
            },
            hintLabel: '↑/↓',
            hintDescription: 'adjust',
          ),
          KeyBinding.single(
            KeyEventType.arrowDown,
            (event) {
              adjustField(-1);
              return KeyActionResult.handled;
            },
          ),
          // Ctrl+E - today
          KeyBinding.single(
            KeyEventType.ctrlE,
            (event) {
              selected = DateTime.now();
              return KeyActionResult.handled;
            },
            hintLabel: 'Ctrl+E',
            hintDescription: 'today',
          ),
        ]) +
        KeyBindings.confirm() +
        KeyBindings.cancel(onCancel: () => cancelled = true);

    void render(RenderOutput out) {
      final title = '$label — Choose Date';
      final widgetFrame = FrameView(
        title: '  $title  ',
        theme: theme,
        bindings: bindings,
        hintStyle: HintStyle.bullets,
      );

      widgetFrame.render(out, (ctx) {
        final monthName = DateFormat('MMMM').format(selected);

        // Field highlighting
        String fmt(String label, String value, bool active) {
          if (active) {
            return '${theme.inverse} $label: $value ${theme.reset}';
          } else {
            return '${theme.dim}$label:${theme.reset} $value';
          }
        }

        // Fields
        final fields = [
          fmt('Day', selected.day.toString().padLeft(2), fieldIndex == 0),
          fmt('Month', monthName, fieldIndex == 1),
          fmt('Year', selected.year.toString(), fieldIndex == 2),
        ];

        // Layout
        ctx.gutterLine(fields.join('   '));

        // Preview
        final formatted =
            DateFormat('EEE, d MMM yyyy').format(selected).padLeft(10);
        ctx.gutterLine(
            '${theme.gray}Preview:${theme.reset} ${theme.accent}$formatted${theme.reset}');
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    return (cancelled || result == PromptResult.cancelled) ? null : selected;
  }
}
