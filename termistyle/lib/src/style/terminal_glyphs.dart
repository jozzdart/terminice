/// Glyph set for structural terminal elements.
///
/// `TerminalGlyphs` focuses purely on the characters and symbols that form
/// the prompt scaffold (box drawing, arrows, checkboxes, etc.). Use built-in
/// presets or create custom glyph sets for different terminal capabilities.
///
/// ```dart
/// // Use rounded corners
/// final theme = PromptTheme(glyphs: TerminalGlyphs.rounded);
///
/// // ASCII-only for maximum compatibility
/// final theme = PromptTheme(glyphs: TerminalGlyphs.ascii);
///
/// // Custom glyph set
/// final custom = TerminalGlyphs(
///   borderTop: '╭',
///   arrow: '❯',
/// );
/// ```
class TerminalGlyphs {
  /// Box-drawing character used for the top edge of the prompt container.
  final String borderTop;

  /// Box-drawing character used for the bottom edge of the prompt container.
  final String borderBottom;

  /// Box-drawing character used for the vertical edges of the prompt.
  final String borderVertical;

  /// Character that connects vertical borders to child sections.
  final String borderConnector;

  /// Horizontal line character for borders.
  final String borderHorizontal;

  /// Icon rendered before focusable rows to indicate direction/focus.
  final String arrow;

  /// Symbol for selected checkboxes or toggles.
  final String checkboxOnSymbol;

  /// Symbol for unselected checkboxes or toggles.
  final String checkboxOffSymbol;

  /// Creates a glyph set for prompts.
  ///
  /// Every parameter is optional and defaults to safe Unicode box-drawing
  /// characters, making the style immediately compatible with most
  /// terminals. Feel free to override a single glyph or build an entirely
  /// custom aesthetic.
  const TerminalGlyphs({
    this.borderTop = '┌',
    this.borderBottom = '└',
    this.borderVertical = '│',
    this.borderConnector = '├',
    this.borderHorizontal = '─',
    this.arrow = '▶',
    this.checkboxOnSymbol = '■',
    this.checkboxOffSymbol = '□',
  });

  /// Creates a copy with modified properties.
  TerminalGlyphs copyWith({
    String? borderTop,
    String? borderBottom,
    String? borderVertical,
    String? borderConnector,
    String? borderHorizontal,
    String? arrow,
    String? checkboxOnSymbol,
    String? checkboxOffSymbol,
  }) {
    return TerminalGlyphs(
      borderTop: borderTop ?? this.borderTop,
      borderBottom: borderBottom ?? this.borderBottom,
      borderVertical: borderVertical ?? this.borderVertical,
      borderConnector: borderConnector ?? this.borderConnector,
      borderHorizontal: borderHorizontal ?? this.borderHorizontal,
      arrow: arrow ?? this.arrow,
      checkboxOnSymbol: checkboxOnSymbol ?? this.checkboxOnSymbol,
      checkboxOffSymbol: checkboxOffSymbol ?? this.checkboxOffSymbol,
    );
  }

  /// Returns the matching right corner for a given left corner glyph.
  String matchingCorner(String leftCorner) {
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
      case '┏':
        return '┓';
      case '┗':
        return '┛';
      case '+':
        return '+';
      case '⸢':
        return '⸣';
      case '⸤':
        return '⸥';
      case '⌜':
        return '⌝';
      case '⌞':
        return '⌟';
      default:
        return leftCorner;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILT-IN PRESETS
  // ════════════════════════════════════════════════════════════════════════════

  /// Default Unicode box drawing characters.
  static const TerminalGlyphs unicode = TerminalGlyphs();

  /// Pure ASCII for maximum terminal compatibility.
  static const TerminalGlyphs ascii = TerminalGlyphs(
    borderTop: '+',
    borderBottom: '+',
    borderVertical: '|',
    borderConnector: '+',
    borderHorizontal: '-',
    arrow: '>',
    checkboxOnSymbol: '[x]',
    checkboxOffSymbol: '[ ]',
  );

  /// Rounded corners for a softer aesthetic.
  static const TerminalGlyphs rounded = TerminalGlyphs(
    borderTop: '╭',
    borderBottom: '╰',
    borderVertical: '│',
    borderConnector: '├',
    borderHorizontal: '─',
    arrow: '❯',
    checkboxOnSymbol: '◉',
    checkboxOffSymbol: '○',
  );

  /// Double-line borders for a bold, classic look.
  static const TerminalGlyphs double = TerminalGlyphs(
    borderTop: '╔',
    borderBottom: '╚',
    borderVertical: '║',
    borderConnector: '╟',
    borderHorizontal: '═',
    arrow: '➤',
    checkboxOnSymbol: '■',
    checkboxOffSymbol: '□',
  );

  /// Heavy/thick box drawing characters.
  static const TerminalGlyphs heavy = TerminalGlyphs(
    borderTop: '┏',
    borderBottom: '┗',
    borderVertical: '┃',
    borderConnector: '┣',
    borderHorizontal: '━',
    arrow: '>',
    checkboxOnSymbol: '◈',
    checkboxOffSymbol: '◇',
  );

  /// Dotted/dashed vertical lines for a lighter feel.
  static const TerminalGlyphs dotted = TerminalGlyphs(
    borderTop: '╭',
    borderBottom: '╰',
    borderVertical: '┊',
    borderConnector: '├',
    borderHorizontal: '─',
    arrow: '▸',
    checkboxOnSymbol: '●',
    checkboxOffSymbol: '○',
  );

  /// Mystical/arcane aesthetic with unique symbols.
  static const TerminalGlyphs arcane = TerminalGlyphs(
    borderTop: '⸢',
    borderBottom: '⸤',
    borderVertical: '⁞',
    borderConnector: '⊢',
    borderHorizontal: '─',
    arrow: '⊳',
    checkboxOnSymbol: '⬢',
    checkboxOffSymbol: '⬡',
  );

  /// Phantom/ghost aesthetic with floating corners.
  static const TerminalGlyphs phantom = TerminalGlyphs(
    borderTop: '⌜',
    borderBottom: '⌞',
    borderVertical: '¦',
    borderConnector: '·',
    borderHorizontal: '─',
    arrow: '›',
    checkboxOnSymbol: '◉',
    checkboxOffSymbol: '◌',
  );

  /// Minimal arrow and simple checkbox symbols.
  static const TerminalGlyphs minimal = TerminalGlyphs(
    borderTop: '',
    borderBottom: '',
    borderVertical: '',
    borderConnector: '',
    borderHorizontal: '',
    arrow: '›',
    checkboxOnSymbol: '✓',
    checkboxOffSymbol: '·',
  );
}
