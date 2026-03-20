## 0.0.1

Extracted the standalone styling system from `terminice_core` into its own package so that any Dart CLI tool, prompt library, or terminal renderer can share the same visual language without pulling in the full terminice stack.

- **Theme system** (`PromptTheme`): Unified composition of colors, glyphs, and display features with 11 built-in themes (dark, minimal, compact, matrix, fire, pastel, ocean, monochrome, neon, arcane, phantom) and full `copyWith` support.
- **Color palettes** (`TerminalColors`): 14 ANSI escape fields with 10 built-in presets spanning 8-color, 16-color, and 256-color terminals.
- **Glyph sets** (`TerminalGlyphs`): Box-drawing borders, arrows, and checkbox symbols with 9 built-in presets (unicode, ascii, rounded, double, heavy, dotted, arcane, phantom, minimal) plus `matchingCorner()` for balanced frames.
- **Display features** (`DisplayFeatures`): Behavioral flags (borders, bold titles, inverse highlight, connector lines, hint style) with 6 built-in presets (standard, minimal, compact, verbose, clean, focus).
- **Semantic tones**: `BadgeTone` (neutral, info, success, warning, danger) and `StatTone` (info, warn, error, accent, success, neutral) for theme-resolved semantic coloring.
- **Spinner frames** (`SpinnerFrames`): Enum with three animation styles (dots, bars, arcs) and their Unicode character sequences as top-level constants.
- **Inline styling** (`InlineStyle`): Theme-aware badge, spinner, progress bar, icon, and text coloring utilities that return styled strings without writing to stdout.
- **Syntax highlighting** (`SyntaxHighlighter`): Theme-aware line-level highlighting for Dart, JSON, and shell with auto-detection.
- **Frame rendering** (`FrameRenderer`, `FramedLayout`): Bordered title, connector, bottom line, and gutter generation driven purely by the active theme.
- **Table rendering** (`TableRenderer`, `ColumnConfig`, `ColumnAlign`): ANSI-aware column sizing, zebra-striped rows, and flexible alignment per column.
- **Text highlighting** (`highlightSubstring`): Case-insensitive substring match coloring using the theme's highlight color.
- **Tone resolution** (`toneColor`): Maps a `StatTone` to the corresponding ANSI color through the active theme.
- **Text utilities**: `stripAnsi`, `visibleLength`, `padVisibleRight`/`Left`/`Center`, `truncate`, `truncatePad`, `padRight`, `padLeft`, `clampInt`, `maxOf`, `minOf`, `columnWidth`, `columnWidthVisible`.
- Zero dependencies. SDK constraint `>=2.17.0 <4.0.0`.
