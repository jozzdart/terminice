import 'prompt_theme.dart';

/// Broad terminal capability levels for adapting prompt themes.
///
/// The compatibility layer is pure styling. It does not inspect the current
/// terminal or perform any I/O; callers choose a mode and apply it to a
/// [PromptTheme].
enum TerminalCompatibility {
  /// Preserve the theme exactly as provided.
  modern,

  /// Keep ANSI colors, but prefer ASCII glyphs and simpler display features.
  basic,

  /// Use ASCII glyphs, no ANSI colors, and minimal output with no hints.
  legacy;

  /// Returns [theme] adapted for this compatibility level.
  PromptTheme applyTo(PromptTheme theme) {
    switch (this) {
      case TerminalCompatibility.modern:
        return theme;
      case TerminalCompatibility.basic:
        return theme.copyWith(
          glyphs: TerminalGlyphs.ascii,
          features: _basicFeatures(theme.features),
        );
      case TerminalCompatibility.legacy:
        return theme.copyWith(
          colors: TerminalColors.none,
          glyphs: TerminalGlyphs.ascii,
          features: _legacyFeatures,
        );
    }
  }
}

/// Applies [TerminalCompatibility] to a [PromptTheme].
extension PromptThemeCompatibility on PromptTheme {
  /// Returns this theme adapted for [compatibility].
  PromptTheme withCompatibility(TerminalCompatibility compatibility) {
    return compatibility.applyTo(this);
  }
}

const DisplayFeatures _legacyFeatures = DisplayFeatures(
  showBorders: false,
  boldTitles: false,
  useInverseHighlight: false,
  showConnector: false,
  hintStyle: HintStyle.none,
);

DisplayFeatures _basicFeatures(DisplayFeatures features) {
  return features.copyWith(
    useInverseHighlight: false,
    showConnector: false,
    hintStyle: _basicHintStyle(features.hintStyle),
  );
}

HintStyle _basicHintStyle(HintStyle hintStyle) {
  switch (hintStyle) {
    case HintStyle.bullets:
    case HintStyle.grid:
      return HintStyle.inline;
    case HintStyle.inline:
    case HintStyle.none:
      return hintStyle;
  }
}
