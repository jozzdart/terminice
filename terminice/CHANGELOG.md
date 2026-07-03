## 1.1.0

#### Added

- Added centralized `TerminiceConfig` for high-level prompt defaults and configuration editor propagation.
- Added compatibility and fallback fluent APIs, including effective theme/defaultTheme behavior for compatibility-derived themes.
- Added high-level line-mode fallback coverage for prompts when raw terminal mode is unavailable or fallback mode is requested.
- Added `task`, `progressTask`, and `trackStream` async helpers for long-running CLI work.
- Added `TaskProgress`, `TaskDisplay`, and `TaskFinalBehavior` controls for task progress, display style, and final output behavior.
- Added `whileRunning` and `trackStream` async sugar on loading/progress indicators, with plain fallback output for compatibility-aware sessions.
- Added `terminice.flow(...)`, a sequential flow builder that composes built-in `text`, `password`, `select`, `checkboxes`, and `confirm` steps plus custom steps.
- Added typed flow result/context accessors, context-aware `when` conditions, and `String?` flow validators for dependent CLI workflows.
- Flow built-in steps run through the configured Terminice instance, so existing component theming and fallback behavior carry through.

#### Changed

- Standardized high-level prompt and config validator semantics on `String?`, with legacy `''` still treated as success.
- `datePicker` now clamps and blocks `allowPast`/`allowFuture` navigation and initial values while preserving defaults.
- Clarified `filePicker(foldersOnly:)` behavior: directories navigate in `filePicker`, while `pathPicker` confirms directories.
- Standardized cancellation results: nullable prompts cancel to `null`, list selectors to `[]`, value prompts keep the exact initial/default, and config fields stay unchanged.
- High-level fallback prompts and selectors now distinguish EOF from blank lines while preserving blank-line defaults.
- Propagated editor-launched prompts through the active Terminice configuration.
- Async task helpers and indicator sugar clean up terminal state before rethrowing errors or completing cancellation/fallback flows.
- Progress indicators now normalize displayed counts, percentages, and bar fill consistently, including `total <= 0` as zero progress.

#### Fixed

- Fixed display-mode chaining so compatibility and fallback settings continue to apply after switching modes.

#### Documentation

- Updated README coverage and tests for configuration, compatibility, fallback behavior, and display-mode chaining.

## 1.0.1

- **Documentation**: Expanded the `README.md` catalogue with in-depth, exui-style reference sections for every public Terminice tool.
- **Documentation**: Added detailed usage notes, parameters, return/cancel behavior, controls, examples, and "why use this" guidance for prompts, selectors, pickers, indicators, configuration editor APIs, and utility guides.
- **Documentation**: Added focused coverage for config editor workflows, `ConfigFactory`, configurable field types, result serialization, indicator lifecycle controllers, filesystem picker behavior, and guide data shapes.

## 1.0.0

- **First stable release.**
- **Documentation**: Added comprehensive, production-ready Dartdoc comments to all public APIs (extensions, methods, classes, and properties) across the entire package.
- **Linting**: Enabled the `public_member_api_docs` linting rule in `analysis_options.yaml` to enforce 100% documentation coverage for all public members.
- **Refactor**: Centralized hint rendering logic into `terminice_core`'s `HintKeybindingsExtensions.writeHints()`.
- **Refactor**: Replaced duplicated manual hint chunking and rendering in `colorPicker` and `datePicker` with the new centralized `writeHints` method.

## 0.0.21

- **Documentation**: Completely rewrote the `README.md` with a new structure, comprehensive catalogue, quick start guides, and embedded interactive VHS showcase GIFs.
- **Bug fix**: Fixed an issue in `colorPicker` where long hint strings wrapped by the terminal emulator caused the internal line counter to desync, resulting in the frame title duplicating on every render step. Hints are now manually chunked and wrapped to ensure accurate line clearing.
- **Bug fix**: Fixed `datePicker` not respecting the `hintStyle` of the current theme (it always rendered bullets). It now correctly renders grid, bullets, or inline hints based on the active display mode.
- **Bug fix**: Fixed `tagSelector` hardcoding inline hints regardless of the theme's `hintStyle`. It now only shows inline hints if the theme specifically requests them.
- **Naming consistency**: All prompts now use `prompt` as the main text parameter. Most are positional; those with defaults (like `confirm`, `searchSelector`, etc.) use a named `prompt` or `title`.

## 0.0.20

Config editor polish: **custom icons**, **group styling**, and **slider labels**.

- **Custom `icon` parameter** — Every `Configurable` type now accepts an optional `icon` to override the default type glyph. Works on direct constructors and `ConfigFactory` methods alike. Subclasses provide a `defaultTypeIcon` fallback.
- **Distinct group styling** — `GroupConfigurable` rows render with bold labels, accent-colored field counts, and a dim `→` navigation arrow, making them visually distinct from leaf fields.
- **Updated default icons** — `GroupConfigurable` uses `⊞` (tree-expand), `PasswordConfigurable` uses `✲` (key-like), and `BoolConfigurable` uses `☉`.
- **Slider unit & percent control** — `slider()` now accepts a `unit` suffix (e.g. `'%'`, `'s'`, `'MB'`) shown alongside the value, and an opt-in `showPercent` flag that appends the calculated ratio percentage in parentheses. Both default to off, so the slider shows the raw value by default. `NumberConfigurable` and `ConfigFactory.number()` expose `showPercent` to forward this to slider mode.

## 0.0.19

Added **verify password** and **`terminice.form()`** using the new `FormPrompt` from terminice_core 0.0.13.

- **`password(verify: true)`** — New optional parameter on the password prompt. When enabled, shows "Password" and "Verify password" fields side-by-side in a single frame. Both must match to confirm. Existing behavior (`verify: false`) is completely unchanged.
- **`terminice.form()`** — Convenience extension that runs a `FormPrompt` with the current theme. Pass `title`, `fields`, and an optional `crossValidator` to collect multiple text inputs in one prompt.
- **`PasswordConfigurable.verify`** — New field on `PasswordConfigurable` and `ConfigFactory.password()` to enable verify mode from the config editor.

## 0.0.18

Added **`ConfigFactory`** — a shorthand factory for creating configurables with less boilerplate.

- **`terminice.config`** — Extension getter that returns a `ConfigFactory` instance. Store it as `final c = terminice.config` and build fields with concise one-liners.
- **Factory methods**: `c.boolean()`, `c.string()`, `c.password()`, `c.number()`, `c.select()`, `c.range()`, `c.rating()`, `c.theme()`, `c.group()` — each mirrors the full constructor of its corresponding `Configurable` type.
- `select` is used for enum fields since `enum` is a Dart reserved word.
- `ConfigFactory` is a `const` class — zero overhead, no state, works standalone or via the extension.

## 0.0.17

Added **nested group configurables** to the config editor, enabling hierarchical settings with infinite nesting depth.

- **`GroupConfigurable`** — Groups child fields into a navigable sub-editor. Appears in the parent list with a `▸` icon and a live summary (e.g. "2/5 modified"). Press Enter to drill in, Esc or "← Back" to return. Groups can contain other groups for arbitrary nesting.
- **Shared editor loop** — Extracted the rendering, navigation, and key-handling logic into a reusable internal loop. Both the top-level `configEditor` and nested group editors share the same code path, eliminating duplication.
- **Root-only save** — Only the top-level editor shows "✓ Save & confirm". Nested editors show "← Back" instead — edits are preserved in-place and only finalized when the user confirms at the root.
- **Recursive change detection** — `GroupConfigurable.isModified` checks all descendants recursively. The `*` modified indicator propagates up through all parent groups.
- **Nested JSON serialization** — `toJsonValue()` produces nested maps and `loadJsonValue()` distributes back to children, so groups round-trip through JSON seamlessly.
- **Recursive validation** — `GroupConfigurable.validate()` aggregates errors from all children, prefixed with the child label for context.

## 0.0.16

Introduced the **Config Editor** system - a searchable, theme-aware settings editor that composes existing prompts into a unified configuration flow.

- **`configEditor`** — Keyboard-driven settings editor that presents a searchable list of typed fields. Select a field to open its dedicated prompt, then return to the list. Single terminal session with clean rendering (no leftover artifacts between edits).
- **`Configurable<T>`** — Abstract base class for typed, serializable config fields with built-in validation, formatting, change detection (`isModified`), and JSON round-tripping (`toJsonValue` / `loadJsonValue`).
- **`ConfigResult`** — Result wrapper with `toMap()` serialization, typed `get<T>(key)` access, `hasChanges`, `modified` list, and `loadFromMap()` for restoring state.
- **8 configurable types**:
  - `BoolConfigurable` — Yes/no via confirm prompt.
  - `StringConfigurable` — Single-line text or multiline editor, with placeholder and required flag.
  - `PasswordConfigurable` — Masked input with optional reveal toggle.
  - `NumberConfigurable` — Text input or slider mode, with min/max/step/unit and integer-only option.
  - `EnumConfigurable` — Searchable dropdown from a fixed set of string options.
  - `RangeConfigurable` — Dual-handle range prompt with start/end serialization.
  - `RatingConfigurable` — Star rating with optional per-level labels.
  - `ThemeConfigurable` — Live theme picker from all 11 built-in presets (or custom map). Changing the theme re-renders the editor immediately.
- **Live theme switching** — `ThemeConfigurable` fields are auto-wired so selecting a new theme updates the editor's own frame, icons, and hints in real time.
- **Focused selection** — Enum and theme selectors start the cursor on the currently active value, with a `✓` marker for quick identification.
- **Field descriptions** — Optional `description` parameter on any configurable, shown as a dim subtitle below the focused field.
- **Search on by default** — The editor starts with search enabled for fast filtering by label or key.

## 0.0.15

- Added `termistyle` path override for local development alongside `terminice_core`.
- Bumped `terminice_core` dependency to 0.0.12.
- No public API or behavioral changes.

## 0.0.14

- **Documentation**: Completely rewrote the `README.md` with a production-grade opening and embedded an interactive, looping VHS showcase GIF.
- **Examples**: Added a comprehensive `showcase.dart` example demonstrating multiple prompts and themes chained together.
- **Bug fix**: Fixed `multiline` prompt ignoring spacebar inputs (added `KeyEventType.space` handling).
- **Bug fix**: Fixed `multiline` prompt not exiting properly when pressing `Ctrl+D` due to incorrect key action result mapping.

## 0.0.13

- **Centralized filesystem helpers**: Shared `pathBasename`, `shortPath`, and `sortedEntries` extracted from `filePicker` and `pathPicker`, removing duplicated path and directory-listing logic.
- **Centralized indicator lifecycle**: New `IndicatorLifecycle` mixin provides `prepareFrame()`, `clear()`, and `runSession()` for all 5 indicators, eliminating duplicated `RenderOutput` management and `TerminalSession` boilerplate.
- **Color picker UX fix**: Replaced `promptHexSync()` (which dropped out of raw mode to `readLineSync`) with an inline `TextInputBuffer`-based hex input. The hex field now renders inside the `FrameView` with live swatch preview, validity feedback, and contextual hints.
- **Deduplicated test mocks**: `MockTerminal` in tests now re-exports from `package:terminice_core/testing.dart` instead of maintaining a separate copy.
- Bumped `terminice_core` dependency to 0.0.10.

## 0.0.12

- **Display Mode Presets**: New fluent accessors for quick theme switching.
  - `terminice.minimal` — No borders, inline hints for functional-only output.
  - `terminice.compact` — Borders but no hints for space-constrained environments.
  - `terminice.verbose` — Full borders with grid hints for maximum discoverability.
- **Component Customization Methods**: Fine-grained theme control.
  - `withColors(TerminalColors)` — Swap color palette while preserving glyphs and features.
  - `withGlyphs(TerminalGlyphs)` — Change symbols (borders, arrows, checkboxes) independently.
  - `withFeatures(DisplayFeatures)` — Toggle borders, hints, bold titles on any theme.
- **New Exports**: `TerminalColors`, `TerminalGlyphs`, `DisplayFeatures`, `HintStyle` now available from the main package.
- **Theme Demo updated**: Now showcases glyphs and features alongside colors.
- Bumped `terminice_core` dependency to 0.0.9

## 0.0.11

- **Terminal abstraction integration**: Full support for custom terminal implementations.
  - Added `withTerminal()` method to `Terminice` for injecting custom terminals.
  - Added `activate()` method to switch context between multiple `Terminice` instances.
  - Added `resetTerminal()` static method to restore default `DartTerminal`.
  - Added `currentTerminal` static getter for accessing the active terminal.
- **Migrated color picker** to use `TerminalContext` instead of direct `dart:io` access.
- **Re-exported terminal types**: `Terminal`, `TerminalInput`, `TerminalOutput`, `DartTerminal`, `DartTerminalInput`, `DartTerminalOutput`, and `TerminalContext` are now available from the main package.
- **Test suite**: 46 tests covering API integration, terminal switching, and complex workflows.
- Bumped `terminice_core` dependency to 0.0.8

## 0.0.10

- Reduced minimum dart sdk version to 2.17.0
- Migrated `enum.name` to use custom extension methods to support older versions of Dart.
- Migrated tuples and records to classes to support older versions of Dart.
- Explicitly named all libraries to support older versions of Dart.
- Removed workspace resolution to support older versions of Dart.
- Bumped `terminice_core` dependency to 0.0.7

## 0.0.9

- Introduced the `guides` suite (`cheatSheet`, `hotkeyGuide`, `helpCenter`,
  `themeDemo`) to document key workflows directly from the CLI with polished
  dartdoc, usage samples, and pub.dev-ready framing.

## 0.0.8

- Added the indicator suite (`loadingSpinner`, `inlineSpinner`, `inlineProgressBar`,
  `progressBar`, `progressDots`) with full docs, API exports, and runnable samples.
  Covers framed and inline progress feedback, spinner styles, and theme-integrated
  messaging for long-running CLI workflows.

## 0.0.7

- Added `filePicker` and `pathPicker`, delivering full keyboard navigation,
  hidden-file toggles, and directory confirmation for filesystem workflows.

## 0.0.6

- Added `datePicker` — a framed calendar prompt with Monday/Sunday toggle,
  today shortcut, yearly jumps, allowed past/future guards, and full hint tray.

## 0.0.5

- Added `colorPicker` — a keyboard-first ANSI color grid with curated presets,
  live hex preview, hex entry shortcuts, and frame-integrated hint grid.

## 0.0.4

- Added `date` — a multi-field, keyboard-driven date prompt with live preview,
  today shortcut, and cancellable flow for safe calendar input.

## 0.0.3

Introduced the selector suite:

- **checkboxSelector** — Vertical checklist with select-all binding and live summary.
- **choiceSelector** — Dashboard grid of cards with optional multi-select.
- **commandPalette** — VS Code-style palette with fuzzy and substring ranking modes.
- **gridSelector** — Generic 2D grid selector supporting multi-select and custom widths.
- **searchSelector** — Scrollable list with optional search toggle and multi-select.
- **tagSelector** — Chip-style picker that auto-reflows based on terminal width.
- **toggleGroup** — Row-based toggle switches with focus navigation and "toggle all".

## 0.0.2

Added the full prompt catalog (text, password, confirm, multiline editor, slider, range, rating):

- **text** — Fast single-line input with immediate validation feedback.
- **password** — Secure masked entry with optional confirmation before submission.
- **confirm** — Streamlined yes/no flow that highlights the default action.
- **multiline** — Scrollable, multi-row composer with diff-friendly output.
- **slider** — Keyboard-driven selector for smooth movement through numeric ranges.
- **range** — Paired handles for picking inclusive min/max values within bounds.
- **rating** — Symbol-based scoring that surfaces descriptive labels alongside stars.

## 0.0.1

- Initial listing on pub.dev
