import 'display_features.dart';
import 'terminal_colors.dart';
import 'terminal_glyphs.dart';

// Re-export for convenience
export 'display_features.dart';
export 'terminal_colors.dart';
export 'terminal_glyphs.dart';

/// Rich styling bundle composing colors, glyphs, and display features.
///
/// `PromptTheme` is the unified styling API for all terminal prompts.
/// It composes three independent concerns:
/// - [TerminalColors]: Color palette (ANSI escape sequences)
/// - [TerminalGlyphs]: Structural symbols (borders, arrows, checkboxes)
/// - [DisplayFeatures]: Behavioral flags (borders, hints, bold)
///
/// Use built-in themes or create custom combinations:
///
/// ```dart
/// // Built-in theme
/// final theme = PromptTheme.matrix;
///
/// // Minimal mode with any color palette
/// final minimal = PromptTheme(
///   colors: TerminalColors.ocean,
///   features: DisplayFeatures.minimal,
/// );
///
/// // Full customization
/// final custom = PromptTheme(
///   colors: TerminalColors.arcane,
///   glyphs: TerminalGlyphs.rounded,
///   features: DisplayFeatures.verbose,
/// );
/// ```
class PromptTheme {
  /// Color palette for ANSI escape sequences.
  final TerminalColors colors;

  /// Glyph set for structural symbols.
  final TerminalGlyphs glyphs;

  /// Display feature configuration.
  final DisplayFeatures features;

  /// Creates a theme by composing colors, glyphs, and features.
  ///
  /// All parameters default to their standard presets, producing
  /// a full-featured dark theme suitable for most terminals.
  const PromptTheme({
    this.colors = TerminalColors.dark,
    this.glyphs = TerminalGlyphs.unicode,
    this.features = DisplayFeatures.standard,
  });

  /// Creates a copy with modified components.
  PromptTheme copyWith({
    TerminalColors? colors,
    TerminalGlyphs? glyphs,
    DisplayFeatures? features,
  }) {
    return PromptTheme(
      colors: colors ?? this.colors,
      glyphs: glyphs ?? this.glyphs,
      features: features ?? this.features,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CONVENIENCE GETTERS - Colors
  // ════════════════════════════════════════════════════════════════════════════

  /// ANSI reset sequence.
  String get reset => colors.reset;

  /// ANSI bold sequence.
  String get bold => colors.bold;

  /// ANSI dim sequence.
  String get dim => colors.dim;

  /// Gray color.
  String get gray => colors.gray;

  /// Primary accent color.
  String get accent => colors.accent;

  /// Key accent color for hints.
  String get keyAccent => colors.keyAccent;

  /// Highlight color for focus.
  String get highlight => colors.highlight;

  /// Selection color.
  String get selection => colors.selection;

  /// Checkbox on color.
  String get checkboxOn => colors.checkboxOn;

  /// Checkbox off color.
  String get checkboxOff => colors.checkboxOff;

  /// Inverse video sequence.
  String get inverse => colors.inverse;

  /// Info color.
  String get info => colors.info;

  /// Warning color.
  String get warn => colors.warn;

  /// Error color.
  String get error => colors.error;

  // ════════════════════════════════════════════════════════════════════════════
  // CONVENIENCE GETTERS - Glyphs
  // ════════════════════════════════════════════════════════════════════════════

  /// Top border character.
  String get borderTop => glyphs.borderTop;

  /// Bottom border character.
  String get borderBottom => glyphs.borderBottom;

  /// Vertical border character.
  String get borderVertical => glyphs.borderVertical;

  /// Border connector character.
  String get borderConnector => glyphs.borderConnector;

  /// Horizontal border character.
  String get borderHorizontal => glyphs.borderHorizontal;

  /// Arrow/focus indicator.
  String get arrow => glyphs.arrow;

  /// Checkbox on symbol.
  String get checkboxOnSymbol => glyphs.checkboxOnSymbol;

  /// Checkbox off symbol.
  String get checkboxOffSymbol => glyphs.checkboxOffSymbol;

  // ════════════════════════════════════════════════════════════════════════════
  // CONVENIENCE GETTERS - Features
  // ════════════════════════════════════════════════════════════════════════════

  /// Whether to show borders.
  bool get showBorders => features.showBorders;

  /// Whether to bold titles.
  bool get boldTitles => features.boldTitles;

  /// Whether to use inverse highlight.
  bool get useInverseHighlight => features.useInverseHighlight;

  /// Whether to show connector lines.
  bool get showConnector => features.showConnector;

  /// Default hint style.
  HintStyle get hintStyle => features.hintStyle;

  // ════════════════════════════════════════════════════════════════════════════
  // BUILT-IN THEMES
  // ════════════════════════════════════════════════════════════════════════════

  /// Default high-contrast dark theme.
  static const PromptTheme dark = PromptTheme();

  /// Minimal functional theme - no borders, inline hints.
  static const PromptTheme minimal = PromptTheme(
    features: DisplayFeatures.minimal,
  );

  /// Compact theme - borders but no hints.
  static const PromptTheme compact = PromptTheme(
    features: DisplayFeatures.compact,
  );

  /// Matrix-inspired neon-green theme.
  static const PromptTheme matrix = PromptTheme(
    colors: TerminalColors.matrix,
    glyphs: TerminalGlyphs.rounded,
  );

  /// Fire theme – high-energy reds/oranges.
  static const PromptTheme fire = PromptTheme(
    colors: TerminalColors.fire,
    glyphs: TerminalGlyphs.double,
  );

  /// Pastel theme – soft, gentle colors.
  static const PromptTheme pastel = PromptTheme(
    colors: TerminalColors.pastel,
  );

  /// Ocean theme – calming blue/cyan tones.
  static const PromptTheme ocean = PromptTheme(
    colors: TerminalColors.ocean,
    glyphs: TerminalGlyphs.dotted,
  );

  /// Monochrome theme – high-contrast ASCII retro.
  static const PromptTheme monochrome = PromptTheme(
    colors: TerminalColors.monochrome,
    glyphs: TerminalGlyphs.ascii,
  );

  /// Neon theme – vibrant synthwave cyberpunk.
  static const PromptTheme neon = PromptTheme(
    colors: TerminalColors.neon,
    glyphs: TerminalGlyphs.heavy,
  );

  /// Arcane theme – mystical ancient tome aesthetic.
  static const PromptTheme arcane = PromptTheme(
    colors: TerminalColors.arcane,
    glyphs: TerminalGlyphs.arcane,
  );

  /// Phantom theme – ghostly apparition aesthetic.
  static const PromptTheme phantom = PromptTheme(
    colors: TerminalColors.phantom,
    glyphs: TerminalGlyphs.phantom,
  );
}
