# termistyle

> **Note:** If you are looking for ready-to-use interactive prompts, menus, and extensive built-in terminal tools, you probably want the main [**`terminice`** package on pub.dev](https://pub.dev/packages/terminice). `termistyle` was built specifically to power `terminice`, but is provided as a standalone package so you can use it to create your own custom terminal-styled packages.

`termistyle` is the standalone styling foundation extracted from the [terminice](https://pub.dev/packages/terminice) ecosystem. It gives any Dart CLI package access to the same ANSI color palettes, box-drawing glyph sets, composable themes, and rendering utilities that power terminice - without depending on terminice itself.

Use it when you are building a terminal tool, prompt library, ASCII art renderer, or any other CLI package that wants consistent, themeable output with zero external dependencies. Well-tested with 964 tests covering every public API surface.

## Install

```yaml
dependencies:
  termistyle: ^1.0.0
```

```dart
import 'package:termistyle/termistyle.dart';
```

## Theme system

A `PromptTheme` composes three independent concerns into one styling bundle:

| Concern  | Class             | Built-in presets                                                             |
| -------- | ----------------- | ---------------------------------------------------------------------------- |
| Colors   | `TerminalColors`  | dark, matrix, fire, pastel, ocean, monochrome, neon, arcane, phantom (10)    |
| Glyphs   | `TerminalGlyphs`  | unicode, ascii, rounded, double, heavy, dotted, arcane, phantom, minimal (9) |
| Features | `DisplayFeatures` | standard, minimal, compact, verbose, clean, focus (6)                        |

Eleven ready-made themes ship out of the box: `dark`, `minimal`, `compact`, `matrix`, `fire`, `pastel`, `ocean`, `monochrome`, `neon`, `arcane`, `phantom`.

```dart
// Use a built-in theme
final theme = PromptTheme.matrix;

// Mix and match components
final custom = PromptTheme(
  colors: TerminalColors.ocean,
  glyphs: TerminalGlyphs.rounded,
  features: DisplayFeatures.compact,
);

// Tweak a single component
final tweaked = PromptTheme.dark.copyWith(
  colors: TerminalColors.dark.copyWith(accent: '\x1B[95m'),
);
```

Every color, glyph, and feature flag supports `copyWith` for fine-grained overrides.

## Inline styling

`InlineStyle` wraps a theme and provides shorthand methods that return styled strings without writing to stdout:

```dart
final s = InlineStyle(PromptTheme.neon);

print(s.accent('Accent text'));
print(s.bold('Bold text'));
print(s.badge('OK', tone: BadgeTone.success));
print(s.spinner(tick));
print(s.progressBar(0.75));
print(s.successIcon());
```

## Frame rendering

`FramedLayout` generates bordered frame strings from the active theme:

```dart
final frame = FramedLayout('Deploy', theme: PromptTheme.arcane);

print(frame.top());        // ⸢─ Deploy ─⸣
print(frame.gutter() + 'Uploading assets...');
print(frame.bottom());     // ⸤──────────
```

`FrameRenderer` exposes the individual static helpers (`titleWithBorders`, `connectorLine`, `bottomLine`, etc.) for lower-level composition.

## Table rendering

`TableRenderer` builds ANSI-aware, themed tables with automatic column sizing, alignment, and zebra stripes:

```dart
final table = TableRenderer(
  columns: [
    ColumnConfig.left('Name'),
    ColumnConfig.center('Status'),
    ColumnConfig.right('Count'),
  ],
  theme: PromptTheme.ocean,
);

table.computeWidths(rows);
for (final line in table.buildLines(rows)) {
  print(line);
}
```

## Syntax highlighting

`SyntaxHighlighter` applies theme colors to Dart, JSON, and shell code with auto-detection:

```dart
final hi = SyntaxHighlighter(PromptTheme.matrix);

print(hi.dartLine("final x = 'hello';"));
print(hi.jsonLine('{"key": 42}'));
print(hi.shellLine('curl --silent https://example.com'));
print(hi.autoLine(unknownLine));
```

## Text utilities

ANSI-aware string helpers that work correctly with styled text:

```dart
final styled = '${theme.accent}Status${theme.reset}';

stripAnsi(styled);              // 'Status'
visibleLength(styled);          // 6
padVisibleRight(styled, 20);    // pads to 20 visible chars
padVisibleCenter(styled, 20);   // centers within 20 visible chars
truncate('Hello World', 8);     // 'Hello W…'
truncatePad('Hi', 10);          // 'Hi        '
columnWidthVisible(styledCells); // max visible width across cells
```

Numeric helpers (`clampInt`, `maxOf`, `minOf`) and plain-text padding (`padRight`, `padLeft`) are also included.

## Semantic tones

Two enums provide theme-resolved semantic coloring without hard-coded ANSI codes:

- **`BadgeTone`** -- `neutral`, `info`, `success`, `warning`, `danger`
- **`StatTone`** -- `info`, `warn`, `error`, `accent`, `success`, `neutral`

Resolve a tone to a color through the active theme:

```dart
final color = toneColor(StatTone.success, theme); // theme.checkboxOn
print('$color✔ Passed${theme.reset}');
```

## Spinner frames

Three animation styles with pre-built Unicode frame sequences:

```dart
// Enum: SpinnerFrames.dots, .bars, .arcs

final frames = spinnerFramesList(SpinnerFrames.dots);
// ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']

// Or use InlineStyle for themed spinners:
final s = InlineStyle(theme);
print(s.spinner(tick, frames: SpinnerFrames.arcs));
```

## API reference

### Style primitives

| Export            | Description                                                   |
| ----------------- | ------------------------------------------------------------- |
| `PromptTheme`     | Composable theme bundle (colors + glyphs + features)          |
| `TerminalColors`  | ANSI color palette with `copyWith` and 10 presets             |
| `TerminalGlyphs`  | Box-drawing symbols with `copyWith` and 9 presets             |
| `DisplayFeatures` | Behavioral flags with `copyWith` and 6 presets                |
| `HintStyle`       | Enum: `bullets`, `grid`, `inline`, `none`                     |
| `BadgeTone`       | Enum: `neutral`, `info`, `success`, `warning`, `danger`       |
| `StatTone`        | Enum: `info`, `warn`, `error`, `accent`, `success`, `neutral` |
| `SpinnerFrames`   | Enum: `dots`, `bars`, `arcs`                                  |

### Rendering utilities

| Export               | Description                                                       |
| -------------------- | ----------------------------------------------------------------- |
| `InlineStyle`        | Theme-aware badges, spinners, icons, progress bars, text coloring |
| `SyntaxHighlighter`  | Dart / JSON / shell line highlighting with auto-detection         |
| `FrameRenderer`      | Static helpers for bordered titles, connectors, bottom lines      |
| `FramedLayout`       | Composable frame layout (top, connector, bottom, gutter)          |
| `TableRenderer`      | ANSI-aware table with column alignment and zebra stripes          |
| `ColumnConfig`       | Column header, alignment, min/max width constraints               |
| `ColumnAlign`        | Enum: `left`, `center`, `right`                                   |
| `highlightSubstring` | Case-insensitive match highlighting using theme colors            |
| `toneColor`          | Resolves `StatTone` to ANSI color through a theme                 |

### Text utilities

| Export                                     | Description                                    |
| ------------------------------------------ | ---------------------------------------------- |
| `stripAnsi`                                | Remove ANSI escape codes from a string         |
| `visibleLength`                            | Printable character count after stripping ANSI |
| `padVisibleRight` / `Left` / `Center`      | ANSI-aware padding to a target width           |
| `padRight` / `padLeft`                     | Plain-text padding                             |
| `truncate`                                 | Truncate with ellipsis                         |
| `truncatePad`                              | Truncate and pad to fixed width                |
| `clampInt` / `maxOf` / `minOf`             | Integer helpers                                |
| `columnWidth` / `columnWidthVisible`       | Column sizing from content                     |
| `spinnerFramesList`                        | Frame data for a `SpinnerFrames` value         |
| `dotsFrames` / `barsFrames` / `arcsFrames` | Raw frame character lists                      |

## Testing

termistyle ships with 964 tests covering every public class, function, enum, preset, and edge case. Run them with:

```bash
dart test
```

## Relationship to terminice

`termistyle` contains the styling subset of `terminice_core` that has **zero dependencies** on terminal I/O, key handling, navigation, or prompt infrastructure. Everything in this package is pure Dart with no external dependencies.

The split allows packages like title renderers, log formatters, or dashboard builders to use the terminice visual language without importing the interactive prompt stack.

When terminice integrates `termistyle`, it will re-export the same types - existing terminice users will see no change in behavior, styling, or API surface.
