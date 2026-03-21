## 0.0.15

- **New**: Added `writeHints` method to `HintKeybindingsExtensions` to centralize hint rendering across all hint styles (bullets, grid, inline, none), including support for chunking bullets via `bulletsPerLine`.
- **Refactor**: Updated `FrameView` to use the new `writeHints` method internally.

## 0.0.14

Enhanced **`sliderBar`** with configurable value labels.

- **`value` and `unit` parameters** — `sliderBar` now accepts the actual numeric value and an optional unit suffix (e.g. `'%'`, `'s'`, `'MB'`). The value with its suffix is always shown when provided. The `showPercent` flag (now `false` by default) optionally appends the calculated ratio percentage in parentheses — e.g. `30s (25%)`.

## 0.0.13

Added **`FormPrompt`** — a reusable multi-field text input prompt.

- **`FormPrompt`** — Renders multiple labeled text fields inside a single `FrameView`. Supports per-field masking, placeholders, validation, and a cross-field validator. Composes existing `TextInputBuffer`, `FrameView`, `KeyBindings`, and `PromptRunner` with no changes to existing code.
- **`FormFieldConfig`** — Configuration for each field: `label`, `placeholder`, `masked`, `maskChar`, `allowReveal`, `required`, `validator`, `initialValue`.
- **`FormResult`** — Result wrapper with indexed `[]` access to field values.
- Key handling: Tab/↓ advance to next field, ↑ goes back, Enter advances or submits from the last field, Ctrl+R reveals masked fields, Esc cancels.

## 0.0.12

- **Styling extracted to `termistyle`**: All standalone style and rendering primitives (`PromptTheme`, `TerminalColors`, `TerminalGlyphs`, `DisplayFeatures`, `BadgeTone`, `InlineStyle`, `FrameRenderer`, `FramedLayout`, `TableRenderer`, `SyntaxHighlighter`, text utilities) now live in the `termistyle` package and are re-exported through the existing barrel.
- Removed duplicate `StatTone` enum and `_toneColor` helper from `frame_view.dart` in favor of the shared definitions from `termistyle`.
- Cleaned up the `style/` directory entirely — all style files are sourced from `termistyle`.
- No public API or behavioral changes. All existing code continues to work unchanged.

## 0.0.11

- **Bug fix**: Fixed `KeyBindings.ctrlD` returning `KeyActionResult.handled` instead of `KeyActionResult.confirmed`, which caused infinite loops in prompts relying on it for submission (like the multiline editor).
- **Bug fix**: Fixed `SearchableListPrompt` crashing with `Invalid argument(s)` when the terminal height or `maxVisible` parameter resulted in a viewport smaller than 5 lines.

## 0.0.10

- **Bug fix**: `SelectableListPromptBuilder.withSelectAll()` now correctly wires the `toggleAll` callback. Previously the builder created a binding with an empty closure and `build()` never passed extra bindings to the prompt.
- **New**: `SelectionController.validatedIndices()` static helper centralizes the initial-selection validation that was duplicated across `SelectableListPrompt`, `SearchableListPrompt`, and `SelectableGridPrompt`.
- **New**: `package:terminice_core/testing.dart` entrypoint exports `MockTerminal`, `SpyTerminal`, and `ErrorTerminal` so downstream packages can import test utilities without duplicating them.

## 0.0.9

- **Centralized Theme System**: Complete refactor separating styling into three composable concerns.
  - Added `TerminalColors` class with 9 built-in color palettes (dark, matrix, fire, pastel, ocean, monochrome, neon, arcane, phantom).
  - Added `TerminalGlyphs` class with 8 glyph presets (unicode, ascii, rounded, double, heavy, dotted, arcane, phantom, minimal).
  - Added `DisplayFeatures` class with 6 display mode presets (standard, minimal, compact, verbose, clean, focus).
  - Moved `HintStyle` enum to `DisplayFeatures` for centralized presentation control.
- **PromptTheme refactored**: Now composes `TerminalColors`, `TerminalGlyphs`, and `DisplayFeatures`.
  - Added convenience getters delegating to each component for ergonomic access.
  - Added `copyWith()` for easy theme customization.
  - Added new built-in themes: `PromptTheme.minimal`, `PromptTheme.compact`.
- **Rendering components updated**: `FrameView`, `LineBuilder`, `FramedLayout`, `FrameRenderer`, `TableRenderer` now use the new `theme.glyphs` and `theme.features` accessors.
  - `FrameView.hintStyle` now defaults from `theme.features.hintStyle` with per-component override.
  - `FrameView.showConnector` now defaults from `theme.features.showConnector`.

## 0.0.8

- **Terminal I/O Abstraction**: Introduced a centralized, pluggable terminal I/O system.
  - Added `Terminal` abstract class with `TerminalInput` and `TerminalOutput` interfaces.
  - Added `DartTerminal` as the default implementation using `dart:io` stdin/stdout.
  - Added `TerminalContext` singleton for global terminal access and replacement.
- **Migrated all core components** to use the new abstraction:
  - `TerminalControl` now uses `TerminalContext.input/output` for mode management and cursor control.
  - `KeyEventReader` now reads through `TerminalContext.input`.
  - `TerminalInfo` now queries dimensions through `TerminalContext.output`.
  - `RenderOutput` now writes through `TerminalContext.output`.
- **Testing support**: External users can now inject custom `Terminal` implementations for testing or alternative environments.
- **Test utilities**: Added comprehensive mock terminal implementations for testing:
  - `MockTerminal` with `MockTerminalInput` and `MockTerminalOutput` for full I/O simulation.
  - `SpyTerminal` for tracking method calls and verifying interactions.
  - `ErrorTerminal` for testing error handling scenarios.
  - Input queueing helpers for bytes, lines, and key events.
  - Output capture with pattern matching and inspection helpers.
- **Extensive test suite**: 69 tests covering terminal interfaces, context switching, and integration.
- No behavior changes - all existing code continues to work unchanged.

## 0.0.7

- Reduced minimum dart sdk version to 2.17.0
- Enforced type safety with the new dart sdk.
- Migrated tuples and records to classes to support older versions of Dart.
- Explicitly named all libraries to support older versions of Dart.
- Removed workspace resolution to support older versions of Dart.

## 0.0.6

- Added the entire prompt toolkit (`SimplePrompt`, selectable/searchable/ranked list prompts, grid selection, value prompts, `DynamicListPrompt`, and `TextInputBuffer`) to the public API.
- Documented every prompt with production-grade dartdoc plus README excerpts so the new surfaces render cleanly on pub.dev.
- Clarified how the prompt module composes the existing navigation, rendering, and IO primitives to build higher-level interactions.

## 0.0.5

- Added the full rendering toolkit (`FrameView`, `FrameContext`, `FrameRenderer`, `FramedLayout`, `LineBuilder`, `TableRenderer`, `InlineStyle`, `HintFormat`, syntax helpers) to the public API surface so prompts can share consistent terminal scaffolding.
- Wrote production-grade DartDoc, diagrams, and inline examples for every renderer to ensure the new APIs render cleanly on pub.dev and meet documentation guidelines.
- Documented how the rendering pieces integrate with `PromptRunner` and `KeyBindings`, including connector lines, table helpers, and hint grids, so downstream packages know when to pick each component.

## 0.0.4

- Added style primitives (`PromptTheme`, `PromptStyle`, `BadgeTone`, `Themeable`) so that prompts and downstream widgets can share consistent visuals.
- Documented the new styling features with production-grade DartDoc for pub.dev.
- Ensured style exports remain available through `terminice_core.dart`.

## 0.0.3

- Added navigation components (`FocusNavigator`, `ListNavigator`, `GridNavigator`, `SelectionController`) to the public API surface.
- Polished their DartDoc and improved in-tree examples for clear rendering on pub.dev.
- Documented the navigation toolkit in the `terminice_core` README.

## 0.0.2

- Added the complete `lib/src/io` module (key events, bindings, terminal helpers).
- Documented and exposed the IO utilities for downstream packages.
- Maintained new APIs through `terminice_core.dart`.
- Specified supported platforms in `pubspec.yaml`.

## 0.0.1

- Initial listing on pub.dev.
