import 'package:terminice_core/terminice_core.dart';

/// Helpers to render titles and horizontal border lines consistently.
class FrameRenderer {
  /// Properly balanced title: ╭─ Title ─╮
  static String titleWithBorders(String title, PromptTheme theme) {
    final g = theme.glyphs;
    return '${theme.selection}${g.borderTop}${g.borderHorizontal} $title ${g.borderHorizontal}${g.matchingCorner(g.borderTop)}${theme.reset}';
  }

  /// Title with themed borders but custom color.
  static String titleWithBordersColored(
      String title, PromptTheme theme, String color) {
    final g = theme.glyphs;
    return '$color${g.borderTop}${g.borderHorizontal} $title ${g.borderHorizontal}${g.matchingCorner(g.borderTop)}${theme.reset}';
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
    final g = theme.glyphs;
    return '${theme.gray}${g.borderConnector}${g.borderHorizontal * (title.length + 6)}${theme.reset}';
  }

  static String bottomLine(String title, PromptTheme theme) {
    final g = theme.glyphs;
    // Match the visual width of the top line, but without a closing corner.
    // Top width = title.length + 6 (includes both corners and spacing/dashes).
    // Bottom: left corner + dashes => 1 + (title.length + 5) = title.length + 6
    return '${theme.gray}${g.borderBottom}${g.borderHorizontal * (title.length + 5)}${theme.reset}';
  }

  /// Bottom line with a custom color.
  static String bottomLineColored(
      String title, PromptTheme theme, String color) {
    final g = theme.glyphs;
    return '$color${g.borderBottom}${g.borderHorizontal * (title.length + 5)}${theme.reset}';
  }
}
