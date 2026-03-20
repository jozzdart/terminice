/// Color palette for terminal output using ANSI escape sequences.
///
/// `TerminalColors` encapsulates all color definitions used across prompts,
/// keeping color concerns separate from glyphs and display features.
/// Use built-in presets or create custom palettes for brand alignment.
///
/// ```dart
/// // Use a built-in palette
/// final theme = PromptTheme(colors: TerminalColors.matrix);
///
/// // Create a custom palette
/// final custom = TerminalColors(
///   accent: '\x1B[38;5;141m',
///   highlight: '\x1B[38;5;81m',
/// );
/// ```
class TerminalColors {
  /// ANSI escape sequence that resets the terminal back to its defaults.
  final String reset;

  /// ANSI escape sequence that enables bold output.
  final String bold;

  /// ANSI escape sequence that dims the current output.
  final String dim;

  /// Neutral gray foreground color code.
  final String gray;

  /// Primary accent color for labels and highlights.
  final String accent;

  /// Accent color dedicated to key bindings and shortcut hints.
  final String keyAccent;

  /// Color for momentary highlights such as focused rows.
  final String highlight;

  /// Color used for selection regions or active multi-select rows.
  final String selection;

  /// Foreground color for selected checkboxes or toggles.
  final String checkboxOn;

  /// Foreground color for unselected checkboxes or toggles.
  final String checkboxOff;

  /// ANSI escape sequence for inverse video effects.
  final String inverse;

  /// Informational/status color.
  final String info;

  /// Warning color.
  final String warn;

  /// Error color.
  final String error;

  /// Creates a color palette. All parameters accept ANSI escape sequences.
  /// Defaults favor broad terminal compatibility.
  const TerminalColors({
    this.reset = '\x1B[0m',
    this.bold = '\x1B[1m',
    this.dim = '\x1B[2m',
    this.gray = '\x1B[90m',
    this.accent = '\x1B[36m',
    this.keyAccent = '\x1B[37m',
    this.highlight = '\x1B[33m',
    this.selection = '\x1B[35m',
    this.checkboxOn = '\x1B[32m',
    this.checkboxOff = '\x1B[90m',
    this.inverse = '\x1B[7m',
    this.info = '\x1B[36m',
    this.warn = '\x1B[33m',
    this.error = '\x1B[31m',
  });

  /// Creates a copy with modified properties.
  TerminalColors copyWith({
    String? reset,
    String? bold,
    String? dim,
    String? gray,
    String? accent,
    String? keyAccent,
    String? highlight,
    String? selection,
    String? checkboxOn,
    String? checkboxOff,
    String? inverse,
    String? info,
    String? warn,
    String? error,
  }) {
    return TerminalColors(
      reset: reset ?? this.reset,
      bold: bold ?? this.bold,
      dim: dim ?? this.dim,
      gray: gray ?? this.gray,
      accent: accent ?? this.accent,
      keyAccent: keyAccent ?? this.keyAccent,
      highlight: highlight ?? this.highlight,
      selection: selection ?? this.selection,
      checkboxOn: checkboxOn ?? this.checkboxOn,
      checkboxOff: checkboxOff ?? this.checkboxOff,
      inverse: inverse ?? this.inverse,
      info: info ?? this.info,
      warn: warn ?? this.warn,
      error: error ?? this.error,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILT-IN PRESETS
  // ════════════════════════════════════════════════════════════════════════════

  /// Default high-contrast dark palette tuned for general use.
  static const TerminalColors dark = TerminalColors();

  /// Matrix-inspired neon-green palette for classic hacker aesthetics.
  static const TerminalColors matrix = TerminalColors(
    accent: '\x1B[32m',
    highlight: '\x1B[92m',
    selection: '\x1B[32m',
    checkboxOn: '\x1B[32m',
    checkboxOff: '\x1B[90m',
    info: '\x1B[32m',
    warn: '\x1B[93m',
    error: '\x1B[31m',
  );

  /// Fire palette – high-energy reds/oranges that demand attention.
  static const TerminalColors fire = TerminalColors(
    accent: '\x1B[31m',
    highlight: '\x1B[33m',
    selection: '\x1B[31m',
    checkboxOn: '\x1B[31m',
    checkboxOff: '\x1B[90m',
    info: '\x1B[36m',
    warn: '\x1B[33m',
    error: '\x1B[31m',
  );

  /// Pastel palette – soft gradients for calm, friendly prompts.
  static const TerminalColors pastel = TerminalColors(
    accent: '\x1B[95m',
    highlight: '\x1B[93m',
    selection: '\x1B[94m',
    checkboxOn: '\x1B[96m',
    checkboxOff: '\x1B[90m',
    info: '\x1B[96m',
    warn: '\x1B[93m',
    error: '\x1B[91m',
  );

  /// Ocean palette – Calming deep blue and cyan tones like ocean depths.
  static const TerminalColors ocean = TerminalColors(
    accent: '\x1B[94m',
    highlight: '\x1B[96m',
    selection: '\x1B[34m',
    keyAccent: '\x1B[36m',
    checkboxOn: '\x1B[94m',
    checkboxOff: '\x1B[90m',
    info: '\x1B[96m',
    warn: '\x1B[93m',
    error: '\x1B[91m',
  );

  /// Monochrome palette – High-contrast ASCII retro terminal aesthetic.
  static const TerminalColors monochrome = TerminalColors(
    accent: '\x1B[97m',
    highlight: '\x1B[7m',
    selection: '\x1B[37m',
    keyAccent: '\x1B[97m',
    checkboxOn: '\x1B[97m',
    checkboxOff: '\x1B[90m',
    info: '\x1B[37m',
    warn: '\x1B[97m',
    error: '\x1B[4m\x1B[97m',
  );

  /// Neon palette – Vibrant synthwave cyberpunk with electric colors.
  static const TerminalColors neon = TerminalColors(
    accent: '\x1B[95m',
    highlight: '\x1B[96m',
    selection: '\x1B[93m',
    keyAccent: '\x1B[95m',
    checkboxOn: '\x1B[96m',
    checkboxOff: '\x1B[90m',
    info: '\x1B[95m',
    warn: '\x1B[93m',
    error: '\x1B[91m',
  );

  /// Arcane palette – Mystical ancient tome aesthetic with magical runes.
  /// Uses 256-color palette for deep amethyst, ancient gold, and mystic hues.
  static const TerminalColors arcane = TerminalColors(
    accent: '\x1B[38;5;141m',
    highlight: '\x1B[38;5;220m',
    selection: '\x1B[38;5;99m',
    keyAccent: '\x1B[38;5;178m',
    checkboxOn: '\x1B[38;5;220m',
    checkboxOff: '\x1B[38;5;240m',
    info: '\x1B[38;5;147m',
    warn: '\x1B[38;5;214m',
    error: '\x1B[38;5;160m',
  );

  /// Phantom palette – Ghostly apparition materializing from shadow.
  /// Ethereal gray-violet tones with spectral glows.
  static const TerminalColors phantom = TerminalColors(
    accent: '\x1B[38;5;103m',
    highlight: '\x1B[38;5;255m',
    selection: '\x1B[38;5;60m',
    keyAccent: '\x1B[38;5;146m',
    checkboxOn: '\x1B[38;5;189m',
    checkboxOff: '\x1B[38;5;236m',
    info: '\x1B[38;5;103m',
    warn: '\x1B[38;5;180m',
    error: '\x1B[38;5;131m',
  );
}
