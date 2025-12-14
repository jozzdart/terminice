import 'package:terminice_core/terminice_core.dart';

/// Helpers to render titles and horizontal border lines consistently.
class FrameRenderer {
  /// Properly balanced title: ╭─ Title ─╮
  static String titleWithBorders(String title, PromptTheme theme) {
    final s = theme.style;
    return '${theme.selection}${s.borderTop}─ $title ─${_matchingCorner(s.borderTop)}${theme.reset}';
  }

  /// Title with themed borders but custom color.
  static String titleWithBordersColored(
      String title, PromptTheme theme, String color) {
    final s = theme.style;
    return '$color${s.borderTop}─ $title ─${_matchingCorner(s.borderTop)}${theme.reset}';
  }

  /// Plain title with accent color.
  static String plainTitle(String title, PromptTheme theme) {
    return '${theme.selection}$title${theme.reset}';
  }

  /// Plain title with a custom color.
  static String plainTitleColored(
      String title, PromptTheme theme, String color) {
    return '$color$title${theme.reset}';
  }

  static String connectorLine(String title, PromptTheme theme) {
    final s = theme.style;
    return '${theme.gray}${s.borderConnector}${'─' * (title.length + 6)}${theme.reset}';
  }

  static String bottomLine(String title, PromptTheme theme) {
    final s = theme.style;
    // Match the visual width of the top line, but without a closing corner.
    // Top width = title.length + 6 (includes both corners and spacing/dashes).
    // Bottom: left corner + dashes => 1 + (title.length + 5) = title.length + 6
    return '${theme.gray}${s.borderBottom}${'─' * (title.length + 5)}${theme.reset}';
  }

  /// Bottom line with a custom color.
  static String bottomLineColored(
      String title, PromptTheme theme, String color) {
    final s = theme.style;
    return '$color${s.borderBottom}${'─' * (title.length + 5)}${theme.reset}';
  }

  /// Auto-picks a matching right corner for a given left corner glyph.
  static String _matchingCorner(String leftCorner) {
    switch (leftCorner) {
      case '╭':
        return '╮';
      case '╰':
        return '╯';
      case '╔':
        return '╗';
      case '╚':
        return '╝';
      case '┌':
        return '┐';
      case '└':
        return '┘';
      default:
        return leftCorner;
    }
  }
}
