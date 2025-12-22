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

  /// Shorthand access to glyphs.
  TerminalGlyphs get glyphs => theme.glyphs;

  /// Shorthand access to features.
  DisplayFeatures get features => theme.features;

  /// Returns the top title line (unstyled; caller may add bold if desired).
  String top() {
    return features.showBorders
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
  /// Returns empty string when borders are disabled.
  String gutter() {
    return features.showBorders
        ? '${theme.gray}${glyphs.borderVertical}${theme.reset} '
        : '';
  }

  /// Returns just the gutter character without trailing space.
  /// Returns empty string when borders are disabled.
  String gutterOnly() {
    return features.showBorders
        ? '${theme.gray}${glyphs.borderVertical}${theme.reset}'
        : '';
  }
}
