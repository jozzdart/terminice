/// Glyph configuration for the structural parts of a prompt.
///
/// `PromptStyle` focuses purely on the characters and symbols that form the
/// prompt scaffold (box drawing, arrows, checkboxes, etc.). Pair this with a
/// [`PromptTheme`](prompt_theme.dart) to colorize and animate the rest of the
/// presentation.
///
/// ```dart
/// const chrome = PromptStyle(
///   borderTop: '╭',
///   borderBottom: '╰',
///   arrow: '❯',
/// );
/// ```
class PromptStyle {
  /// Box-drawing character used for the top edge of the prompt container.
  final String borderTop;

  /// Box-drawing character used for the bottom edge of the prompt container.
  final String borderBottom;

  /// Box-drawing character used for the vertical edges of the prompt.
  final String borderVertical;

  /// Character that connects vertical borders to child sections.
  final String borderConnector;

  /// Icon rendered before focusable rows to indicate direction/focus.
  final String arrow;

  /// Symbol for selected checkboxes or toggles.
  final String checkboxOnSymbol;

  /// Symbol for unselected checkboxes or toggles.
  final String checkboxOffSymbol;

  /// Whether highlighted rows should invert foreground/background colors.
  final bool useInverseHighlight;

  /// Whether prompts should be rendered in bold by default.
  final bool boldPrompt;

  /// Whether the outer border should be drawn at all.
  final bool showBorder;

  /// Creates a new glyph set for prompts.
  ///
  /// Every parameter is optional and defaults to a safe ASCII/box-drawing
  /// alternative, making the style immediately compatible with most
  /// terminals—including those with limited Unicode support. Feel free to
  /// override a single glyph or build an entirely custom aesthetic.
  const PromptStyle({
    this.borderTop = '┌',
    this.borderBottom = '└',
    this.borderVertical = '│',
    this.borderConnector = '├',
    this.arrow = '▶',
    this.checkboxOnSymbol = '■',
    this.checkboxOffSymbol = '□',
    this.useInverseHighlight = true,
    this.boldPrompt = true,
    this.showBorder = true,
  });
}
