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
