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
