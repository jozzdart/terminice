import 'package:terminice_core/terminice_core.dart';

/// LineBuilder – Centralized line-level styling utilities for terminal views.
///
/// Provides reusable, theme-aware methods for common UI patterns found
/// across terminal views and prompts. Eliminates duplication and ensures consistency.
///
/// **Key patterns centralized:**
/// - Frame prefix (left gutter with border vertical)
/// - Arrow/focus indicators
/// - Checkbox rendering
/// - Overflow indicators
/// - Line wrapping with optional inverse highlight
///
/// **Usage:**
/// ```dart
/// final lb = LineBuilder(theme);
///
/// // Frame prefix for content lines
/// out.writeln('${lb.gutter()}Content here');
///
/// // Arrow indicator for focused item
/// final arrow = lb.arrow(isFocused);
/// out.writeln('${lb.gutter()}$arrow Item');
///
/// // Checkbox for toggleable items
/// final check = lb.checkbox(isChecked);
/// out.writeln('${lb.gutter()}$check Option');
///
/// // Full line with optional inverse highlight
/// lb.writeLine(out, 'Content', highlighted: isFocused);
///
/// // Overflow indicators for scrollable lists
/// if (hasOverflowAbove) out.writeln(lb.overflowLine());
/// ```
///
/// **Benefits:**
/// - Single source of truth for styling patterns
/// - Consistent appearance across all views
/// - Easier theming customization
/// - Reduced boilerplate in view code
/// - Better testability
class LineBuilder {
  /// The theme providing colors and style symbols.
  final PromptTheme theme;

  /// Creates a LineBuilder with the given theme.
  const LineBuilder(this.theme);

  /// Shorthand access to the theme's style configuration.
  PromptStyle get style => theme.style;

  // ──────────────────────────────────────────────────────────────────────────
  // GUTTER / FRAME PREFIX
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the standard left gutter/frame prefix.
  ///
  /// This is the `│ ` pattern used at the start of content lines
  /// within a framed view.
  String gutter() => '${theme.gray}${style.borderVertical}${theme.reset} ';

  /// Returns a gutter-only line (no trailing space, just the border).
  ///
  /// Useful for empty separator lines within a frame.
  String gutterOnly() => '${theme.gray}${style.borderVertical}${theme.reset}';

  // ──────────────────────────────────────────────────────────────────────────
  // ARROW / FOCUS INDICATOR
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the arrow/focus indicator based on focus state.
  ///
  /// When [focused] is true, returns the themed arrow symbol.
  /// Otherwise returns a space for alignment.
  String arrow(bool focused) =>
      focused ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';

  /// Returns an accented arrow (always visible, used for bullets).
  String arrowAccent() => '${theme.accent}${style.arrow}${theme.reset}';

  /// Returns a dimmed arrow (for inactive/non-focused items).
  String arrowDim() => '${theme.dim}${style.arrow}${theme.reset}';

  // ──────────────────────────────────────────────────────────────────────────
  // CHECKBOX
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns a styled checkbox based on checked state.
  ///
  /// Uses theme colors and style symbols for on/off states.
  String checkbox(bool checked) {
    final sym = checked ? style.checkboxOnSymbol : style.checkboxOffSymbol;
    final col = checked ? theme.checkboxOn : theme.checkboxOff;
    return '$col$sym${theme.reset}';
  }

  /// Returns a highlighted checkbox (for focused items).
  ///
  /// Wraps the checkbox with inverse styling when [highlight] is true
  /// and the theme supports inverse highlighting.
  String checkboxHighlighted(bool checked, {bool highlight = false}) {
    final base = checkbox(checked);
    if (highlight && style.useInverseHighlight) {
      return '${theme.inverse}$base${theme.reset}';
    }
    return base;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SWITCH / TOGGLE CONTROL
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns a styled switch/toggle control.
  ///
  /// Displays "[✓] ON " or "[□] OFF" based on the [on] state.
  String switchControl(bool on) {
    final col = on ? theme.checkboxOn : theme.checkboxOff;
    final sym = on ? style.checkboxOnSymbol : style.checkboxOffSymbol;
    final text = on ? ' ON ' : ' OFF';
    return '$col$sym$text${theme.reset}';
  }

  /// Returns a highlighted switch control (for focused items).
  ///
  /// Wraps the switch control with inverse styling when [highlight] is true
  /// and the theme supports inverse highlighting.
  String switchControlHighlighted(bool on, {bool highlight = false}) {
    final base = switchControl(on);
    if (highlight && style.useInverseHighlight) {
      return '${theme.inverse}$base${theme.reset}';
    }
    return base;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // OVERFLOW INDICATORS
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the overflow indicator text (dimmed ellipsis).
  ///
  /// Used to indicate there are more items above/below the visible viewport.
  String overflow() => '${theme.dim}...${theme.reset}';

  /// Returns a complete overflow line with gutter prefix.
  ///
  /// Convenience method combining [gutter] and [overflow].
  String overflowLine() => '${gutter()}${overflow()}';

  // ──────────────────────────────────────────────────────────────────────────
  // EMPTY / PLACEHOLDER MESSAGES
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns a dimmed placeholder message in parentheses.
  ///
  /// Common patterns: "(no matches)", "(empty)", "(no tags)".
  String emptyMessage(String message) => '${theme.dim}($message)${theme.reset}';

  /// Returns a complete empty message line with gutter prefix.
  String emptyLine(String message) => '${gutter()}${emptyMessage(message)}';

  // ──────────────────────────────────────────────────────────────────────────
  // LINE WRITING WITH HIGHLIGHT
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a content line to the output with optional inverse highlight.
  ///
  /// This centralizes the common pattern of:
  /// ```dart
  /// if (isHighlighted && style.useInverseHighlight) {
  ///   out.writeln('$prefix${theme.inverse}$content${theme.reset}');
  /// } else {
  ///   out.writeln('$prefix$content');
  /// }
  /// ```
  ///
  /// [content] is the line content (without gutter prefix).
  /// [highlighted] determines if inverse styling should be applied.
  /// [includeGutter] controls whether to prepend the gutter prefix.
  void writeLine(
    RenderOutput out,
    String content, {
    bool highlighted = false,
    bool includeGutter = true,
  }) {
    final prefix = includeGutter ? gutter() : '';
    if (highlighted && style.useInverseHighlight) {
      out.writeln('$prefix${theme.inverse}$content${theme.reset}');
    } else {
      out.writeln('$prefix$content');
    }
  }

  /// Writes multiple content lines with the same settings.
  void writeLines(
    RenderOutput out,
    Iterable<String> lines, {
    bool includeGutter = true,
  }) {
    for (final line in lines) {
      writeLine(out, line, includeGutter: includeGutter);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // COMPOSITE BUILDERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Builds a standard selectable item line.
  ///
  /// Combines arrow indicator with content. Common in list views.
  ///
  /// Example output: `▶ Selected item` or `  Unselected item`
  String selectableLine(String content, {required bool focused}) {
    return '${arrow(focused)} $content';
  }

  /// Builds a checkbox item line.
  ///
  /// Combines arrow, checkbox, and content. Common in multi-select views.
  ///
  /// Example output: `▶ ■ Checked item` or `  □ Unchecked item`
  String checkboxLine(
    String content, {
    required bool focused,
    required bool checked,
  }) {
    return '${arrow(focused)} ${checkbox(checked)} $content';
  }

  /// Writes a selectable item line with full formatting.
  ///
  /// Convenience method that combines [selectableLine] with [writeLine].
  void writeSelectableLine(
    RenderOutput out,
    String content, {
    required bool focused,
    bool highlighted = false,
  }) {
    final line = selectableLine(content, focused: focused);
    writeLine(out, line, highlighted: highlighted && focused);
  }

  /// Writes a checkbox item line with full formatting.
  ///
  /// Convenience method that combines [checkboxLine] with [writeLine].
  void writeCheckboxLine(
    RenderOutput out,
    String content, {
    required bool focused,
    required bool checked,
    bool highlighted = false,
  }) {
    final line = checkboxLine(content, focused: focused, checked: checked);
    writeLine(out, line, highlighted: highlighted && focused);
  }
}
