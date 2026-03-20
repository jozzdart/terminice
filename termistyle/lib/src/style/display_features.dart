/// Hint display style options for keyboard bindings.
enum HintStyle {
  /// Bullet-style hints on a single line.
  bullets,

  /// Grid-style hints with aligned columns.
  grid,

  /// Inline comma-separated hints in parentheses.
  inline,

  /// No hints displayed.
  none,
}

/// Display feature flags controlling presentation behavior.
///
/// `DisplayFeatures` separates behavioral concerns from colors and glyphs,
/// allowing the same visual theme to behave differently based on context.
/// Use built-in presets or create custom feature sets.
///
/// ```dart
/// // Minimal mode: no borders, inline hints
/// final theme = PromptTheme(features: DisplayFeatures.minimal);
///
/// // Compact mode: borders but no hints
/// final theme = PromptTheme(features: DisplayFeatures.compact);
///
/// // Custom features
/// final custom = DisplayFeatures(
///   showBorders: true,
///   boldTitles: false,
///   hintStyle: HintStyle.grid,
/// );
/// ```
class DisplayFeatures {
  /// Whether the outer border should be drawn.
  final bool showBorders;

  /// Whether titles/prompts should be rendered in bold.
  final bool boldTitles;

  /// Whether highlighted rows should invert foreground/background colors.
  final bool useInverseHighlight;

  /// Whether to show a connector line after the header in frames.
  final bool showConnector;

  /// Default hint style for keyboard bindings display.
  final HintStyle hintStyle;

  /// Creates a display feature configuration.
  ///
  /// All parameters are optional with sensible defaults that provide
  /// a rich, full-featured terminal experience.
  const DisplayFeatures({
    this.showBorders = true,
    this.boldTitles = true,
    this.useInverseHighlight = true,
    this.showConnector = false,
    this.hintStyle = HintStyle.bullets,
  });

  /// Creates a copy with modified properties.
  DisplayFeatures copyWith({
    bool? showBorders,
    bool? boldTitles,
    bool? useInverseHighlight,
    bool? showConnector,
    HintStyle? hintStyle,
  }) {
    return DisplayFeatures(
      showBorders: showBorders ?? this.showBorders,
      boldTitles: boldTitles ?? this.boldTitles,
      useInverseHighlight: useInverseHighlight ?? this.useInverseHighlight,
      showConnector: showConnector ?? this.showConnector,
      hintStyle: hintStyle ?? this.hintStyle,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILT-IN PRESETS
  // ════════════════════════════════════════════════════════════════════════════

  /// Standard display with all features enabled.
  /// Borders, bold titles, bullet hints.
  static const DisplayFeatures standard = DisplayFeatures();

  /// Minimal display for functional-only output.
  /// No borders, no bold, inline hints.
  static const DisplayFeatures minimal = DisplayFeatures(
    showBorders: false,
    boldTitles: false,
    useInverseHighlight: false,
    hintStyle: HintStyle.inline,
  );

  /// Compact display with borders but no hints.
  /// Good for space-constrained environments.
  static const DisplayFeatures compact = DisplayFeatures(
    showBorders: true,
    boldTitles: true,
    hintStyle: HintStyle.none,
  );

  /// Verbose display with grid hints and connectors.
  /// Maximum information for discoverability.
  static const DisplayFeatures verbose = DisplayFeatures(
    showBorders: true,
    boldTitles: true,
    showConnector: true,
    hintStyle: HintStyle.grid,
  );

  /// Clean display with borders but minimal hints.
  /// Inline hints for a streamlined look.
  static const DisplayFeatures clean = DisplayFeatures(
    showBorders: true,
    boldTitles: true,
    hintStyle: HintStyle.inline,
  );

  /// Focus mode with no hints for experienced users.
  /// Borders and styling remain, hints are hidden.
  static const DisplayFeatures focus = DisplayFeatures(
    showBorders: true,
    boldTitles: true,
    hintStyle: HintStyle.none,
  );
}
