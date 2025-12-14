import 'package:terminice_core/terminice_core.dart';

/// FramedLayout – pure string generator for framed terminal output.
///
/// Generates styled frame strings (top border, connectors, bottom border)
/// without writing directly to any output. Used internally by [FrameView]
/// and other rendering components.
///
/// **Design principle:** This class is a pure data/string generator.
/// For rendering, use [FrameView] which composes with this class
/// and handles proper output management.
///
/// **Usage:**
/// ```dart
/// final frame = FramedLayout('My Title', theme: theme);
/// final topLine = frame.top();    // Returns string, doesn't print
/// final bottomLine = frame.bottom();
/// ```
class FramedLayout {
  final String title;
  final PromptTheme theme;

  const FramedLayout(this.title, {this.theme = const PromptTheme()});

  /// Returns the top title line (unstyled; caller may add bold if desired).
  String top() {
    final s = theme.style;
    return s.showBorder
        ? FrameRenderer.titleWithBorders(title, theme)
        : FrameRenderer.plainTitle(title, theme);
  }

  /// Returns the connector line sized to the title/content width.
  String connector() {
    return FrameRenderer.connectorLine(title, theme);
  }

  /// Returns the bottom line sized to match the top.
  String bottom() {
    return FrameRenderer.bottomLine(title, theme);
  }

  /// Returns the left gutter prefix string: `│ `
  String gutter() {
    final s = theme.style;
    return '${theme.gray}${s.borderVertical}${theme.reset} ';
  }

  /// Returns just the gutter character without trailing space.
  String gutterOnly() {
    final s = theme.style;
    return '${theme.gray}${s.borderVertical}${theme.reset}';
  }
}
