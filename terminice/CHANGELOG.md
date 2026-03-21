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
