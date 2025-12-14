import 'prompt_style.dart';

/// Rich styling bundle pairing ANSI color codes with [PromptStyle] glyphs.
///
/// Whereas [PromptStyle] focuses on the characters that form the prompt
/// scaffold, `PromptTheme` owns the escape sequences and symbolic colors used
/// across the UI. Provide a custom instance to align the toolkit with your
/// brand palette or terminal aesthetic.
///
/// ```dart
/// final midnight = PromptTheme(
///   accent: '\x1B[38;5;141m',
///   highlight: '\x1B[38;5;81m',
///   style: const PromptStyle(arrow: '❯'),
/// );
/// ```
class PromptTheme {
  /// Structural glyph configuration to use when drawing frames and controls.
  final PromptStyle style;

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

  /// Creates a full theme definition. All parameters accept ANSI escape
  /// sequences (standard or 256-color). Defaults favor broad terminal
  /// compatibility so prompts stay legible even in limited environments.
  const PromptTheme({
    this.style = const PromptStyle(),
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
    this.info = '\x1B[36m', // cyan by default
    this.warn = '\x1B[33m', // yellow by default
    this.error = '\x1B[31m', // red by default
  });

  /// Default high-contrast dark theme tuned for general use.
  static const PromptTheme dark = PromptTheme();

  /// Matrix-inspired neon-green palette for classic hacker aesthetics.
  static const PromptTheme matrix = PromptTheme(
    accent: '\x1B[32m',
    highlight: '\x1B[92m',
    selection: '\x1B[32m',
    checkboxOn: '\x1B[32m',
    checkboxOff: '\x1B[90m',
    info: '\x1B[32m', // green info
    warn: '\x1B[93m', // bright yellow warning
    error: '\x1B[31m', // red error
    style: PromptStyle(
      borderTop: '╭',
      borderBottom: '╰',
      borderVertical: '│',
      borderConnector: '├',
      arrow: '❯',
      checkboxOnSymbol: '◉',
      checkboxOffSymbol: '○',
    ),
  );

  /// Fire theme – high-energy reds/oranges that demand attention.
  static const PromptTheme fire = PromptTheme(
    accent: '\x1B[31m',
    highlight: '\x1B[33m',
    selection: '\x1B[31m',
    checkboxOn: '\x1B[31m',
    checkboxOff: '\x1B[90m',
    info: '\x1B[36m', // cyan info for readability
    warn: '\x1B[33m', // yellow warning
    error: '\x1B[31m', // red error
    style: PromptStyle(
      borderTop: '╔',
      borderBottom: '╚',
      borderVertical: '║',
      borderConnector: '╟',
      arrow: '➤',
      checkboxOnSymbol: '■',
      checkboxOffSymbol: '□',
    ),
  );

  /// Pastel theme – soft gradients for calm, friendly prompts.
  static const PromptTheme pastel = PromptTheme(
    accent: '\x1B[95m',
    highlight: '\x1B[93m',
    selection: '\x1B[94m',
    checkboxOn: '\x1B[96m',
    checkboxOff: '\x1B[90m',
    info: '\x1B[96m', // pastel cyan
    warn: '\x1B[93m', // pastel yellow
    error: '\x1B[91m', // light red
    style: PromptStyle(
      borderTop: '┌',
      borderBottom: '└',
      borderVertical: '│',
      borderConnector: '├',
      arrow: '›',
      checkboxOnSymbol: '◆',
      checkboxOffSymbol: '◇',
    ),
  );

  /// Ocean theme – Calming deep blue and cyan tones like ocean depths.
  ///
  /// Best for: Long sessions, reading-heavy tasks, calm environments.
  static const PromptTheme ocean = PromptTheme(
    accent: '\x1B[94m', // bright blue
    highlight: '\x1B[96m', // bright cyan
    selection: '\x1B[34m', // blue
    keyAccent: '\x1B[36m', // cyan
    checkboxOn: '\x1B[94m', // bright blue
    checkboxOff: '\x1B[90m', // gray
    info: '\x1B[96m', // bright cyan
    warn: '\x1B[93m', // bright yellow
    error: '\x1B[91m', // bright red
    style: PromptStyle(
      borderTop: '╭',
      borderBottom: '╰',
      borderVertical: '┊',
      borderConnector: '├',
      arrow: '▸',
      checkboxOnSymbol: '●',
      checkboxOffSymbol: '○',
    ),
  );

  /// Monochrome theme – High-contrast ASCII retro terminal aesthetic.
  ///
  /// Best for: Classic terminal feel, high-visibility, minimal distraction.
  static const PromptTheme monochrome = PromptTheme(
    accent: '\x1B[97m', // bright white
    highlight: '\x1B[7m', // inverse for stark contrast
    selection: '\x1B[37m', // white
    keyAccent: '\x1B[97m', // bright white
    checkboxOn: '\x1B[97m', // bright white
    checkboxOff: '\x1B[90m', // gray
    info: '\x1B[37m', // white
    warn: '\x1B[97m', // bright white
    error: '\x1B[4m\x1B[97m', // underlined bright white
    style: PromptStyle(
      borderTop: '+',
      borderBottom: '+',
      borderVertical: '|',
      borderConnector: '+',
      arrow: '>',
      checkboxOnSymbol: '[x]',
      checkboxOffSymbol: '[ ]',
    ),
  );

  /// Neon theme – Vibrant synthwave cyberpunk with electric colors.
  ///
  /// Best for: Creative sessions, standout visuals, futuristic vibe.
  static const PromptTheme neon = PromptTheme(
    accent: '\x1B[95m', // bright magenta
    highlight: '\x1B[96m', // bright cyan
    selection: '\x1B[93m', // bright yellow
    keyAccent: '\x1B[95m', // bright magenta
    checkboxOn: '\x1B[96m', // bright cyan
    checkboxOff: '\x1B[90m', // gray
    info: '\x1B[95m', // bright magenta
    warn: '\x1B[93m', // bright yellow
    error: '\x1B[91m', // bright red
    style: PromptStyle(
      borderTop: '┏',
      borderBottom: '┗',
      borderVertical: '┃',
      borderConnector: '┣',
      arrow: '>',
      checkboxOnSymbol: '◈',
      checkboxOffSymbol: '◇',
    ),
  );

  /// Arcane theme – Mystical ancient tome aesthetic with magical runes.
  ///
  /// Uses 256-color palette for deep amethyst, ancient gold, and mystic hues.
  /// Unique glyph-like borders evoke spell scrolls and enchanted manuscripts.
  ///
  /// Best for: When you want magic in your terminal.
  static const PromptTheme arcane = PromptTheme(
    accent: '\x1B[38;5;141m', // soft amethyst violet
    highlight: '\x1B[38;5;220m', // ancient gold
    selection: '\x1B[38;5;99m', // deep mystic purple
    keyAccent: '\x1B[38;5;178m', // warm amber
    checkboxOn: '\x1B[38;5;220m', // gold (activated rune)
    checkboxOff: '\x1B[38;5;240m', // faded stone gray
    info: '\x1B[38;5;147m', // light lavender mist
    warn: '\x1B[38;5;214m', // burning orange
    error: '\x1B[38;5;160m', // blood crimson
    style: PromptStyle(
      borderTop: '⸢',
      borderBottom: '⸤',
      borderVertical: '⁞',
      borderConnector: '⊢',
      arrow: '⊳',
      checkboxOnSymbol: '⬢',
      checkboxOffSymbol: '⬡',
    ),
  );

  /// Phantom theme – Ghostly apparition materializing from shadow.
  ///
  /// Ethereal gray-violet tones with spectral glows. Half-brackets float
  /// like corners emerging from void. Broken bars suggest translucency.
  /// The presence/absence symbolized by watching eyes and empty circles.
  ///
  /// Best for: When you want to feel like a ghost in the machine.
  static const PromptTheme phantom = PromptTheme(
    accent: '\x1B[38;5;103m', // ghostly gray-violet
    highlight: '\x1B[38;5;255m', // sudden spectral flash
    selection: '\x1B[38;5;60m', // shadow purple
    keyAccent: '\x1B[38;5;146m', // faded lavender whisper
    checkboxOn: '\x1B[38;5;189m', // spectral presence glow
    checkboxOff: '\x1B[38;5;236m', // deep shadow absence
    info: '\x1B[38;5;103m', // ghostly murmur
    warn: '\x1B[38;5;180m', // eerie candlelight amber
    error: '\x1B[38;5;131m', // blood mist
    style: PromptStyle(
      borderTop: '⌜',
      borderBottom: '⌞',
      borderVertical: '¦',
      borderConnector: '·',
      arrow: '›',
      checkboxOnSymbol: '◉',
      checkboxOffSymbol: '◌',
    ),
  );
}
