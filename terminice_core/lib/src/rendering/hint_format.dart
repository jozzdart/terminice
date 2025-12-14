import 'dart:math';
import 'package:terminice_core/terminice_core.dart';

/// Centralized formatting helpers for keyboard hint blocks.
///
/// `HintFormat` keeps all pub.dev-facing hint renderings consistent by
/// handling bullet separators, section dividers, and ANSI-safe column padding.
/// Prefer these helpers instead of ad-hoc string building so new layouts and
/// theme tweaks stay in sync across every prompt.
class HintFormat {
  /// Builds the legacy single-line bullet list: `⌘K Jump • Enter Confirm`.
  ///
  /// When [dim] is true the entire string is rendered with the theme's dim
  /// color which is ideal for inline overlays. Otherwise the standard accent
  /// gray is used to keep hints visually distinct from content.
  static String bullets(
    List<String> segments,
    PromptTheme theme, {
    bool dim = false,
  }) {
    final color = dim ? theme.dim : theme.gray;
    return '$color${segments.join(' • ')}${theme.reset}';
  }

  /// Produces a multi-column grid (two columns by default) with aligned keys.
  ///
  /// This is the most legible format for dense keybinding lists because each
  /// column width is computed ahead of time using ANSI-aware math, ensuring
  /// columns never wobble when colors are applied.
  static String grid(List<List<String>> rows, PromptTheme theme) {
    final buffer = StringBuffer();
    final color = theme.gray;

    // Compute column widths for alignment
    final col1Width = rows.fold<int>(
        0, (w, row) => max(w, (row.isNotEmpty ? row[0].length : 0)));
    final col2Width = rows.fold<int>(
        0, (w, row) => max(w, row.length > 1 ? row[1].length : 0));

    buffer.writeln('${theme.dim}Controls:${theme.reset}');
    for (final row in rows) {
      final key = row.isNotEmpty ? row[0].padRight(col1Width + 2) : '';
      final action = row.length > 1 ? row[1].padRight(col2Width + 2) : '';
      buffer.writeln('  $color$key${theme.reset}$action');
    }
    return buffer.toString().trimRight();
  }

  /// Renders grouped sections such as "Navigation", "Editing", "Confirm".
  ///
  /// Use this when distinct command categories exist. Each group title uses
  /// bold styling so it stands out even when the caller applies additional
  /// framing around the hint block.
  static String sections(Map<String, List<String>> groups, PromptTheme theme) {
    final buffer = StringBuffer();
    final color = theme.gray;

    buffer.writeln('${theme.dim}Controls${theme.reset}');
    buffer.writeln('${theme.dim}────────────────────${theme.reset}');
    for (final entry in groups.entries) {
      buffer.writeln(
          ' ${theme.bold}${entry.key}:${theme.reset}  $color${entry.value.join('   ')}${theme.reset}');
    }
    return buffer.toString();
  }

  /// Wraps a keyboard label in square brackets with the proper accent color.
  static String key(String label, PromptTheme theme) {
    return '[${theme.keyAccent}$label${theme.reset}]';
  }

  /// Combines a key label with its action (e.g. `[Esc] Cancel`).
  static String hint(String keyLabel, String action, PromptTheme theme) {
    return '${key(keyLabel, theme)} $action';
  }

  /// Builds a dim, parenthesized comma-separated hint string.
  /// Example: "(Enter to confirm, Esc to cancel)"
  static String comma(List<String> segments, PromptTheme theme) {
    return '${theme.dim}(${segments.join(', ')})${theme.reset}';
  }
}

/// Convenience extensions so `KeyBindings` can emit polished hint strings.
extension HintKeybindingsExtensions on KeyBindings {
  /// Generates a hints grid string for display.
  String toHintsGrid(PromptTheme theme) {
    return HintFormat.grid(toHintEntries(), theme);
  }

  /// Generates a hints bullets string for display.
  String toHintsBullets(PromptTheme theme) {
    final entries = toHintEntries();
    final segments =
        entries.map((e) => HintFormat.hint(e[0], e[1], theme)).toList();
    return HintFormat.bullets(segments, theme);
  }
}
