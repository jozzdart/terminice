![terminice](https://i.imgur.com/wAVyfdI.png)

<h3 align="center"><i>Terminal interfaces, finally done right.</i></h3>

<p align="center">
  <img src="https://img.shields.io/codefactor/grade/github/jozzdart/terminice/main?style=flat-square">
  <img src="https://img.shields.io/github/license/jozzdart/terminice?style=flat-square">
  <img src="https://img.shields.io/pub/points/terminice?style=flat-square">
  <img src="https://img.shields.io/pub/v/terminice?style=flat-square">
</p>

<p align="center">
  <a href="https://buymeacoffee.com/yosefd99v" target="https://buymeacoffee.com/yosefd99v">
    <img src="https://img.shields.io/badge/Buy%20me%20a%20coffee-Support (:-blue?logo=buymeacoffee&style=flat-square" />
  </a>
</p>

> **The ultimate UI toolkit for Dart command-line apps.**

**`terminice`** gives you **30+ ready-to-use terminal components**—from simple prompts to complex searchable menus and config editors.

**Universal theming out of the box.** Every single prompt, selector, picker, and indicator automatically adapts to your chosen theme. Pick from **11 built-in themes** or customize your own via a fluent API.

**Zero boilerplate.** No widget trees or manual state management. Just call a method and get a polished, keyboard-driven UI instantly.

<p align="center">
  <img src="assets/showcase.gif" alt="terminice interactive showcase" width="1000"/>
</p>

### Features

- **30+ built-in prompts** — Text, password, confirm, multiline editor, slider, range, rating, date, form, and 7 selector variants. Plus pickers for files, paths, colors, and dates.
- **11 color themes** — Dark, Matrix, Fire, Pastel, Ocean, Monochrome, Neon, Arcane, Phantom, and display modes (Minimal, Compact, Verbose). Mix and match colors, glyphs, and features freely.
- **Config editor** — A searchable, nested settings editor that composes existing prompts into a unified configuration flow with live theme switching, validation, and JSON serialization.
- **Progress and task feedback** — Loading spinners, inline spinners, progress bars, progress dots, and async task helpers for long-running `Future` and `Stream` work.
- **Message primitives** — Small `info`, `success`, `warn`, `error`, `detail`, `log`, and `newline` helpers for polished CLI status lines around prompts, tasks, and flows.
- **Zero boilerplate** — One import, one global instance, chainable theme accessors. No setup, no context objects, no widget trees.
- **Cross-platform** — Works on Linux, macOS, and Windows. Backed by a testable terminal abstraction you can swap for custom I/O.
- **Modular architecture** — Built on `terminice_core`, which exposes navigation primitives, prompt scaffolds, and rendering utilities for when you need full control.
- **Custom components** — Package your own reusable prompts and workflows with the same Terminice theme, terminal, fallback, compatibility, and test harness behavior as built-ins.

#### Table of Contents

- [**Features**](#features)
- [**Meet Terminice**](#meet-terminice)
- [**The Terminice Catalogue**](#-the-terminice-catalogue)
- [**Quick Start**](#quick-start)
- [**Core Concepts & Behavior**](#core-concepts--behavior)
- [**Theming & Display Modes**](#-theming--display-modes)
- [**Command App Integration**](#command-app-integration)
- [**Testing Terminice CLIs**](#testing-terminice-clis)
- [**Custom Components & Extensibility**](#custom-components--extensibility)

### Meet Terminice

Most CLIs start with a question.

```dart
final name = terminice.text('Project name');
```

Then the question becomes a choice.

```dart
final template = terminice.searchSelector(
  prompt: 'Template',
  options: ['CLI', 'Server', 'Package'],
);
```

Then input becomes private, searchable, or filesystem-aware.

```dart
final token = terminice.password('API token');
final config = terminice.filePicker('Config file');
```

And long work can still feel alive.

```dart
final bar = terminice.progressBar('Uploading');
bar.show(current: 42, total: 100);
bar.clear();
```

Use one styled instance when you want everything to feel like one product.

```dart
final t = terminice.neon.compact;

final name = t.text('Project name');
final config = t.filePicker('Config file');
final ok = t.confirm(message: 'Create $name?');
```

That is where Terminice fits: the human-facing layer of your CLI. It does not replace `package:args`, `CommandRunner`, `dart:io`, process tools, or your app architecture. It gives those commands beautiful prompts, menus, flows, progress, messages, fallback behavior, themes, and tests.

#### Why developers reach for it

- **Beautiful by default** - rich terminal UI from small method calls.
- **Easy to grow** - start with one prompt, then add menus, flows, tasks, config editors, or custom components.
- **Unified by instance** - theme, display mode, fallback, terminal, and testing move together.
- **Robust in real environments** - interactive locally, plain and predictable in CI, scripts, tests, and limited terminals.

The goal is simple: make beautiful terminal UIs easy for anyone, while still giving serious CLI apps a centralized, consistent, fallback-safe, and testable system.

# 📚 The `terminice` Catalogue

Explore the complete collection of tools available in `terminice`.  
Every tool is fully themeable and ready to use with zero setup.

#### 📝 Prompts

Standard input controls for gathering user data.

- [`text` — Single-line text input.](#text---single-line-text-input)
- [`password` — Secure, masked text input.](#password---masked-text-input)
- [`confirm` — Yes/No boolean confirmation.](#confirm---yesno-confirmation)
- [`multiline` — Multi-line text editor.](#multiline---terminal-text-area)
- [`slider` — Numeric selection along a single axis.](#slider---numeric-selection)
- [`range` — Dual-thumb slider for selecting a min/max range.](#range---dual-handle-numeric-range)
- [`rating` — Star-based rating input.](#rating---star-rating-input)
- [`date` — Date picker.](#date---keyboard-date-prompt)
- [`form` — Form prompt.](#form---multi-field-input)

#### 🎯 Selectors

Interactive menus for choosing from predefined options.

- [`searchSelector` — Filterable list of options.](#searchselector---filterable-list-selection)
- [`choiceSelector` — Card-based choices with optional multi-select.](#choiceselector---card-based-choice-grid)
- [`checkboxSelector` — Multi-select list with checkboxes.](#checkboxselector---multi-select-checklist)
- [`gridSelector` — 2D grid selection.](#gridselector---two-dimensional-selection-grid)
- [`tagSelector` — Select and manage multiple tags.](#tagselector---chip-style-multi-select)
- [`toggleGroup` — Independent editable boolean switches.](#togglegroup---editable-boolean-switches)
- [`commandPalette` — Global command launcher with fuzzy search.](#commandpalette---fuzzy-command-launcher)

#### 🗂️ Pickers

Specialized components for selecting complex data types.

- [`filePicker` — Browse and select files from the filesystem.](#filepicker---searchable-file-browser)
- [`pathPicker` — Browse and select directories.](#pathpicker---directory-and-path-browser)
- [`colorPicker` — Interactive color selection.](#colorpicker---ansi-color-grid)
- [`datePicker` — Calendar-based date selection.](#datepicker---calendar-date-selection)

#### ⏳ Indicators

Visual feedback for long-running tasks.

- [`loadingSpinner` — Full-featured loading animation.](#loadingspinner---framed-loading-spinner)
- [`inlineSpinner` — Compact loading animation for inline use.](#inlinespinner---one-line-spinner)
- [`progressBar` — Standard progress bar with percentage.](#progressbar---framed-determinate-progress)
- [`inlineProgressBar` — Compact progress bar.](#inlineprogressbar---one-line-percent-indicator)
- [`progressDots` — Minimalist dot-based progress indicator.](#progressdots---framed-dot-progress)

#### 🧰 Workflow & CLI UX

Helpers for turning individual components into complete command-line experiences.

- [`message primitives` — `info`, `success`, `warn`, `error`, `detail`, `log`, and `newline`.](#message-primitives---small-status-lines)
- [`task` — Run a task with spinner or dots status.](#task---async-status-wrapper)
- [`progressTask` — Run a task with determinate progress.](#progresstask---async-progress-wrapper)
- [`trackStream` — Collect a stream while tracking progress.](#trackstream---stream-progress-collector)
- [`TaskProgress` — Mutable progress state passed to progress tasks.](#taskprogress---mutable-progress-state)
- [`TaskDisplay` — Rendering mode for task helpers.](#taskdisplay---task-rendering-mode)
- [`TaskFinalBehavior` — Final output policy for task helpers.](#taskfinalbehavior---final-output-policy)
- [`flow` — Sequential flow builder.](#flow---sequential-flow-composition)
- [`custom components` — Reusable class or callback components.](#custom-components--extensibility)

#### ⚙️ Configuration & Guides

Advanced tools for settings, documentation, shortcuts, and theme exploration.

- [`configEditor` — A searchable, nested settings editor for complex configurations.](#configeditor---searchable-nested-settings-editor)
- [`cheatSheet` — Display a quick reference guide.](#cheatsheet---framed-reference-table)
- [`helpCenter` — Interactive help documentation viewer.](#helpcenter---searchable-help-browser)
- [`hotkeyGuide` — Display available keyboard shortcuts.](#hotkeyguide---interactive-shortcut-guide)
- [`themeDemo` — Showcase all available themes and colors.](#themedemo---interactive-theme-gallery)

### Quick Start

Get up and running in seconds. No setup required—just import and call.

#### 1. Ask for input

Gather text, passwords, or confirmations with a single line of code.

```dart
final name = terminice.text('Project name');
final ship = terminice.confirm(prompt: 'Ship to production?', message: 'Are you sure?');
```

<img src="assets/quick_start_1.gif" alt="terminice text and confirm prompts" width="1000"/>

#### 2. Build interactive menus

Need a searchable list? It's just as easy.

```dart
final lang = terminice.searchSelector(
  prompt: 'Language',
  options: ['Dart', 'Go', 'Rust', 'TypeScript'],
  showSearch: true,
);
```

<img src="assets/quick_start_2.gif" alt="terminice search selector" width="1000"/>

#### 3. Change themes instantly

Want a different vibe? Just chain a theme name before your prompt.

```dart
// Hacker green
final secret = terminice.matrix.password('Passphrase');

// High-energy cyberpunk
final memory = terminice.neon.slider('Memory', min: 128, max: 2048);
```

<img src="assets/quick_start_3.gif" alt="terminice themes showcase" width="1000"/>

For a complete list of available tools, check out [**The Terminice Catalogue**](#-the-terminice-catalogue).

### Core Concepts & Behavior

This section covers the mechanics that make Terminice predictable across a full CLI app.

#### Prompt Execution & Async Tasks

Prompts, selectors, pickers, and config editors are synchronous. You do not need to `await` user-input prompts; each call blocks until the user provides input or cancels, then returns the result directly.

Async task helpers are the exception because they wrap your `Future` or `Stream`. They render status while work is active, return the typed result on success, and rethrow errors after rendering the final failure or cancel status.

```dart
final name = terminice.text('Name');
final age = terminice.slider('Age', min: 0, max: 100);

final result = await terminice.task('Publishing', run: publish);
```

#### Shared API Design

Most tools in the library share a consistent set of parameters to keep the API predictable:

- `prompt` or `label`: The main text displayed to the user.
- `initial` or `defaultValue`: The starting value or selection.
- `required`: (On text/password prompts) Prevents the user from submitting an empty value.
- `validator`: A function that returns a `String?` error message if the input is invalid.

#### Cancellation Behavior

Prompts use a consistent cancellation policy:

- Nullable prompts return `null` when cancelled.
- Value prompts return the exact caller-supplied `initial` or default value when cancelled, even if the active interactive value is clamped while editing.
- Config editor fields leave their existing value unchanged when a field edit is cancelled.
- List and multi selectors return a non-null list; cancelled multi-selection prompts may return `[]`.

#### Validation

Validating input is built directly into the prompts. Simply provide a `validator` function that returns a `String` error message if the input is invalid, or `null` if it passes. Returning `''` is also accepted as a legacy-compatible success value.

```dart
final email = terminice.text(
  'Email address',
  validator: (val) {
    if (!val.contains('@')) return 'Please enter a valid email';
    return null; // Input is valid
  },
);
```

For basic required fields, you don't even need a custom validator. Just use the `required` flag:

```dart
final name = terminice.text(
  'Full name',
  required: true, // Automatically prevents empty submissions
);
```

Validation works seamlessly with other tools too, like the multiline editor:

```dart
final commitMsg = terminice.multiline(
  'Commit message',
  validator: (lines) {
    if (lines.isEmpty) return 'Message cannot be empty';
    if (lines.first.length > 50) return 'First line must be under 50 chars';
    return null;
  },
);
```

#### Theming & Chaining

You don't need to pass a theme object to every prompt. Instead, `terminice` uses a fluent, chainable API. Every theme or display mode getter returns a new, scoped `Terminice` instance.

```dart
// Chain a theme and a display mode directly
final choice = terminice.ocean.compact.confirm(message: 'Save changes?');

// Or save a scoped instance for reuse
final t = terminice.neon.minimal;
final user = t.text('Username');
final pass = t.password('Password');
```

Display modes preserve the active colors and glyphs, so both of these chains produce Ocean colors with compact display features:

```dart
final a = terminice.ocean.compact;
final b = terminice.compact.ocean;
```

#### Centralized Instance Configuration

Each `Terminice` instance carries a single immutable `TerminiceConfig`. That config controls the effective theme for component calls that use the caller theme, including prompts, selectors, pickers, most guides, and indicators, plus fallback behavior for covered high-level prompts.

```dart
final t = terminice.withConfig(
  const TerminiceConfig(
    baseTheme: PromptTheme.ocean,
    featureOverride: DisplayFeatures.compact,
    compatibility: TerminalCompatibility.basic,
    fallbackMode: TerminiceFallbackMode.auto,
  ),
);

final name = t.text('Name');
final role = t.searchSelector(
  prompt: 'Role',
  options: ['Admin', 'User'],
);
```

- `baseTheme` is the original theme chosen by the caller.
- `featureOverride` applies a display mode such as `DisplayFeatures.compact`.
- `compatibility` adapts the theme for terminal capability.
- `fallbackMode` decides when covered high-level prompts use line-mode fallback.
- `TerminiceConfig.effectiveTheme` is the theme produced from those values.
- `defaultTheme` exposes that effective theme on the `Terminice` instance.

You can build the same configuration fluently:

```dart
final t = terminice.ocean.compact.basic.autoFallback;
```

Use `withConfig(...)` to replace the whole instance config while preserving the terminal. Use `withTheme(...)` or `themed(...)` to change the base theme while preserving display mode, compatibility, fallback mode, and terminal. Use `withCompatibility(...)` or `withFallbackMode(...)` when you want to pass the enum explicitly.

Because configuration lives on the instance, changing the instance changes theme and behavior consistently across component calls:

```dart
final plain = terminice.legacy.fallback;

final project = plain.text('Project name');
final confirm = plain.confirm(message: 'Create $project?');
```

#### Compatibility Modes

Compatibility modes are styling transforms. They do not inspect the terminal; choose the mode you want for the `Terminice` instance.

- `terminice.modern` - Default behavior. Preserves the active theme exactly.
- `terminice.basic` - Uses ASCII glyphs and simpler hints/display while keeping ANSI colors.
- `terminice.legacy` - Uses ASCII glyphs, disables ANSI colors, and keeps output minimal with no hints.

```dart
final readable = terminice.fire.basic;
final plainText = terminice.ocean.legacy;
```

#### Fallback Policies

The default behavior is unchanged: `terminice` uses the rich interactive prompts unless you opt into fallback.

- `terminice.interactive` - Forces rich prompts. This is the default `fallbackMode`.
- `terminice.autoFallback` - Uses line-mode fallback when input or output is not a terminal.
- `terminice.fallback` - Always uses line-mode fallback for covered high-level prompts.

```dart
final ci = terminice.autoFallback.basic;
final confirmed = ci.confirm(message: 'Continue?');
```

Line-mode fallback uses simple text and numbered prompts instead of raw-mode keyboard UIs. Password fallback reads a normal line; it does **not** mask input in line mode.

Fallback coverage currently includes `text`, `password`, `confirm`, `form`, `searchSelector`, `gridSelector`, `checkboxSelector`, `choiceSelector`, `tagSelector`, `toggleGroup`, `commandPalette`, `slider`, `range`, `rating`, and the focused enum/theme selects used by the config editor.

Components without fallback coverage still receive the effective theme when they use the caller theme, but remain rich/interactive until fallback support is added. Today that includes pickers, guides such as `cheatSheet`, `helpCenter`, and `hotkeyGuide`, manual indicator controller calls such as `show(...)`, `multiline`, `date`, and the config editor shell itself; config editor field prompts that call covered components still inherit the instance fallback policy. Async task helpers use plain task rendering in fallback/plain modes.

### ▧ Theming & Display Modes

`terminice` makes styling effortless. Every prompt adapts automatically to the selected theme and display mode. Just chain the theme or mode accessor before calling any prompt.

|                           Dark                            |                          Matrix                           |                             Fire                              |
| :-------------------------------------------------------: | :-------------------------------------------------------: | :-----------------------------------------------------------: |
|  <img src="assets/theme_showcase_dark.gif" width="300"/>  | <img src="assets/theme_showcase_matrix.gif" width="300"/> |    <img src="assets/theme_showcase_fire.gif" width="300"/>    |
|                        **Pastel**                         |                         **Ocean**                         |                        **Monochrome**                         |
| <img src="assets/theme_showcase_pastel.gif" width="300"/> | <img src="assets/theme_showcase_ocean.gif" width="300"/>  | <img src="assets/theme_showcase_monochrome.gif" width="300"/> |
|                         **Neon**                          |                        **Arcane**                         |                          **Phantom**                          |
|  <img src="assets/theme_showcase_neon.gif" width="300"/>  | <img src="assets/theme_showcase_arcane.gif" width="300"/> |  <img src="assets/theme_showcase_phantom.gif" width="300"/>   |

#### ❖ Available Themes

| Theme            | Description                               | Usage                  |
| :--------------- | :---------------------------------------- | :--------------------- |
| ◉ **Dark**       | The default. Clean, subtle, professional. | `terminice.dark`       |
| ▤ **Matrix**     | Hacker green on black.                    | `terminice.matrix`     |
| ▧ **Fire**       | Warm reds, oranges, and yellows.          | `terminice.fire`       |
| ▦ **Pastel**     | Soft, muted, and friendly colors.         | `terminice.pastel`     |
| ▪ **Ocean**      | Deep blues and calming cyans.             | `terminice.ocean`      |
| ▣ **Monochrome** | Pure black and white. High contrast.      | `terminice.monochrome` |
| ▱ **Neon**       | Bright, high-energy cyberpunk colors.     | `terminice.neon`       |
| ▰ **Arcane**     | Mystical purples and magentas.            | `terminice.arcane`     |
| ◈ **Phantom**    | Ghostly grays and ethereal tones.         | `terminice.phantom`    |

#### ◩ Display Modes

Control the verbosity and framing of your prompts:

- **`verbose`** (Default) — Full borders, contextual hints, and clear separation.
- **`compact`** — Keeps borders but removes hints for a tighter layout.
- **`minimal`** — Strips away borders and frames for a classic, inline CLI feel.

Display modes only override display features. Active colors and glyphs are preserved, so `terminice.ocean.compact` and `terminice.compact.ocean` resolve to the same effective theme.

#### ⌨ Example

```dart
// Combine theme and display mode
final name = terminice.ocean.compact.text('Name');

// Store a themed instance for consistency
final t = terminice.fire.minimal;
final age = t.text('Age');
final role = t.searchSelector(prompt: 'Role', options: ['Admin', 'User']);
```

## Command App Integration

Terminice is the terminal UI layer inside command apps. It does not parse arguments, dispatch commands, run command classes, or replace your logging framework. Use the command structure you already prefer, then call Terminice from inside handlers when you need prompts, flows, terminal-facing messages, async task feedback, fallback/CI output, custom components, or testable terminal UI.

For command structure, use plain `main(List<String> args)`, `package:args` with `CommandRunner`, Mason-style command classes, or your own router. Keep Terminice at the edge where the command talks to the user.

See [example/command_app_example.dart](example/command_app_example.dart) for a complete manual-dispatch command app and [example/command_app_testing_example.dart](example/command_app_testing_example.dart) for command handler tests.

### Plain main and manual dispatch

```dart
import 'dart:io';

import 'package:terminice/terminice.dart';

Future<void> main(List<String> args) async {
  exitCode = await runCommandApp(args, terminice.autoFallback);
}

Future<int> runCommandApp(List<String> args, Terminice t) async {
  final command = args.isEmpty ? null : args.first;

  switch (command) {
    case 'init':
      final name = t.text('Project name', placeholder: 'demo');
      await t.task('Install starter files', run: installFiles);
      t.success('Created $name');
      return 0;
    default:
      t.info('Commands: init');
      return 64;
  }
}
```

### package:args CommandRunner

This is a README-only integration pattern. If your app uses `package:args`, add it to your app and pass a configured `Terminice` instance into each command.

```dart
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:terminice/terminice.dart';

class InitCommand extends Command<int> {
  InitCommand(this.t) {
    argParser.addFlag('yes', abbr: 'y');
  }

  final Terminice t;

  @override
  String get name => 'init';

  @override
  String get description => 'Create a starter project.';

  @override
  Future<int> run() async {
    final name = t.text('Project name', placeholder: 'demo');
    final yes = argResults!.flag('yes') || t.confirm(message: 'Create?');

    if (!yes) return 1;

    await t.task('Creating $name', run: () async {});
    t.success('Created $name');
    return 0;
  }
}

Future<void> main(List<String> args) async {
  final runner = CommandRunner<int>('tool', 'Example command app')
    ..addCommand(InitCommand(terminice.autoFallback));

  exitCode = await runner.run(args) ?? 0;
}
```

### Mason-style command classes

If your app follows a command-class pattern, inject `Terminice` the same way you would inject a logger or project service.

```dart
class CreateCommand {
  CreateCommand({required this.terminice});

  final Terminice terminice;

  Future<int> run({required bool dryRun}) async {
    final name = terminice.text('Project name');

    if (dryRun) {
      terminice.detail('Would create $name');
      return 0;
    }

    await terminice.task('Generating files', run: generateFiles);
    terminice.success('Created $name');
    return 0;
  }
}
```

### CI and noninteractive mode

Prefer flags for required CI values and choose a plain/fallback Terminice instance when the command is noninteractive.

```dart
Future<int> publish({
  required bool ci,
  required bool yes,
  required Terminice terminice,
}) async {
  final t = ci ? terminice.legacy.fallback : terminice.autoFallback;

  if (ci && !yes) {
    t.error('CI publish requires --yes.');
    return 64;
  }

  final confirmed = yes || t.confirm(message: 'Publish package?');
  if (!confirmed) return 1;

  await t.task(
    'Upload package',
    display: ci ? TaskDisplay.plain : TaskDisplay.auto,
    run: uploadPackage,
    success: 'Package published',
  );

  return 0;
}
```

### Testing command handlers

Make command handlers accept a `Terminice` instance, then run them through `TerminiceTester`.

```dart
import 'package:test/test.dart';
import 'package:terminice/testing.dart';

import '../example/command_app_example.dart';

void main() {
  test('init command completes from fallback input', () async {
    final tester = TerminiceTester.fallback(
      lines: const ['demo', '1', '1,3', 'yes'],
    );

    final code = await tester.runAsync(
      (t) => runCommandApp(const ['init'], t),
    );

    expect(code, 0);
    expect(tester.output.plainText, contains('Created demo'));
  });
}
```

## Testing Terminice CLIs

Serious CLIs need tests that do not depend on a real terminal, real stdin, or timing-sensitive stdout capture. Import the sidecar testing library from tests:

```dart
import 'package:test/test.dart';
import 'package:terminice/testing.dart';
```

`package:terminice/testing.dart` re-exports the public Terminice API, core mock-terminal testing primitives, and `TerminiceTester`. It is intentionally a test sidecar; these utilities are not exported from `package:terminice/terminice.dart`.

### Fallback and Line-Mode Flows

Use `TerminiceTester.fallback` for deterministic line-mode coverage. This is ideal for testing flow logic, validators, cancellation behavior, and CI-safe prompt paths.

```dart
test('creates a project from fallback input', () {
  final tester = TerminiceTester.fallback(lines: ['demo', 'yes']);

  final result = tester.run(
    (t) => t
        .flow('Create project')
        .text('name', 'Project name')
        .confirm('create', message: 'Create project?')
        .run(),
  );

  expect(result.toMap(), equals({'name': 'demo', 'create': true}));
  expect(tester.output.plainText, contains('Create project?'));
});
```

### Interactive Key Scripts

Use `TerminiceTester.interactive` with `TerminalScript` when you want to exercise the rich raw-mode prompt path. Scripts are reusable and can queue text, key presses, arrows, Enter, Escape, Tab, Space, and Ctrl keys.

```dart
test('chooses No in the interactive confirm prompt', () {
  final tester = TerminiceTester.interactive(
    script: TerminalScript.build((script) => script.right().enter()),
  );

  final result = tester.run(
    (t) => t.confirm(message: 'Publish release?'),
  );

  expect(result, isFalse);
  expect(tester.output.containsAnsiControls, isTrue);
});
```

### Output Assertions

Every tester exposes `tester.output`, a `TerminalOutputSnapshot` with `raw`, `plainText`, `normalizedText`, `plainLines`, and `containsAnsiControls`. Prefer `plainText` when ANSI styling is irrelevant, `normalizedText` for stable line assertions, and `containsAnsiControls` when you need to prove a path rendered with or without terminal control output.

```dart
final tester = TerminiceTester.nonInteractive();

final count = await tester.runAsync(
  (t) => t.task<int>(
    'Warm cache',
    run: () async => 42,
    success: 'cache ready',
  ),
);

expect(count, 42);
expect(tester.output.normalizedText, equals('OK: cache ready'));
expect(tester.output.containsAnsiControls, isFalse);
```

## Custom Components & Extensibility

Wrap project-specific terminal UI in a `TerminiceComponent<T>` when it should be reusable, typed, and configured by the caller. Components receive a `TerminiceComponentContext`, so they inherit the active Terminice instance: theme and display mode, terminal, compatibility settings, fallback policy, and the same `TerminiceTester` harness used by your tests.

Most projects should start with the built-in Terminice prompts, selectors, pickers, indicators, tasks, config editors, and flows. They cover the common CLI surface without any extra abstraction.

Custom components are the escape hatch for the cases where the catalogue is almost enough, but your CLI has a domain-specific interaction that deserves a name. Instead of copying Terminice internals, forking a prompt, or dropping to a lower-level TUI package, you can package the custom piece and still keep the Terminice experience around it.

Use custom components when you want:

- A reusable project-specific prompt, picker, or mini-workflow.
- A custom interaction that still inherits the caller's theme, terminal, fallback mode, and compatibility settings.
- A component that works in normal calls, flows, and `TerminiceTester` without separate test plumbing.
- A small extension point without turning your CLI into a full TUI application.

Use a class when the component has a name or options:

```dart
class ProjectSlugComponent extends TerminiceComponent<String> {
  const ProjectSlugComponent({this.prompt = 'Project slug'});

  final String prompt;

  @override
  String run(TerminiceComponentContext context) {
    final value = context.terminice.text(
      prompt,
      placeholder: 'my_cli',
    );

    return value == null || value.isEmpty ? 'my_cli' : value;
  }
}

final slug = terminice.ocean.autoFallback.runComponent(
  const ProjectSlugComponent(),
);
```

Use a callback for local one-offs:

```dart
final region = terminice.runWithComponent<String>((context) {
  final selected = context.terminice.searchSelector(
    prompt: 'Region',
    options: ['local', 'staging', 'production'],
  );

  return selected.isEmpty ? 'local' : selected.first;
});
```

Components also drop into flows as typed steps:

```dart
final regionComponent = TerminiceComponent<String>.from((context) {
  final selected = context.terminice.searchSelector(
    prompt: 'Region',
    options: ['local', 'staging', 'production'],
  );

  return selected.isEmpty ? 'local' : selected.first;
});

final result = terminice.flow('Create project')
    .component<String>(
      'slug',
      'Project slug',
      component: const ProjectSlugComponent(),
    )
    .component<String>(
      'region',
      'Region',
      component: regionComponent,
    )
    .run();
```

For lower-level flow wiring, `FlowContext.runComponent(component)` runs through the flow's configured Terminice instance. `FlowContext.promptTitle(title)` gives progress-aware titles when `.progress()` is enabled, while `fallbackPromptTitle(title)` keeps fallback/plain prompts clean.

---

### `text` - Single-Line Text Input

Collect a single trimmed string with optional placeholder text and inline validation. This is the default building block for names, IDs, short notes, paths, and other one-line values.

- `text`
  `(String prompt, {placeholder, validator, required})`
  Opens a themed text input frame.
- `prompt` - Title displayed above the input.
- `placeholder` - Dimmed hint text shown while the input is empty.
- `required` - Defaults to `true`; empty submissions are blocked with an inline error.
- `validator` - Optional `String? Function(String)` that receives trimmed input. Return `null` for valid input, or a non-empty error message to block confirmation. Returning `''` is still accepted as success for backwards compatibility.
- Returns `String?` - The trimmed input on Enter, or `null` when the user cancels with Esc/Ctrl+C.
- Controls - Type normally, Backspace deletes, Enter confirms, Esc cancels.

#### Examples

```dart
final projectName = terminice.text(
  'Project name',
  placeholder: 'my_awesome_app',
);

if (projectName == null) {
  print('No project created.');
}
```

```dart
final nickname = terminice.text(
  'Nickname',
  required: false,
  placeholder: 'Optional',
);

print('Nickname: ${nickname?.isEmpty == true ? "(none)" : nickname}');
```

```dart
final email = terminice.text(
  'Email address',
  placeholder: 'ada@example.com',
  validator: (value) {
    if (!value.contains('@')) return 'Enter a valid email address';
    return null;
  },
);
```

> **Why use this?**
> Instead of manually wiring stdin reads, trimming, empty checks, and retry loops, `text` gives you a themed prompt with validation and cancellation behavior in one call.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `password` - Masked Text Input

Collect secrets without echoing the raw value. The password prompt uses the same text engine as `text`, but masks input, can optionally reveal with a hotkey, and can run a two-field verification flow.

- `password`
  `(String prompt, {required, maskChar, allowReveal, verify})`
  Opens a masked text prompt.
- `prompt` - Title displayed above the password field.
- `required` - Defaults to `true`; empty submissions are blocked.
- `maskChar` - Character repeated for each typed character. Defaults to `'•'`.
- `allowReveal` - Defaults to `true`; when enabled, Ctrl+R toggles plain-text visibility.
- `verify` - Defaults to `false`; when `true`, asks for password and confirmation in one form and blocks mismatches.
- Returns `String?` - The entered password on confirmation, or `null` on cancel.
- Controls - Type normally, Backspace deletes, Enter confirms, Ctrl+R reveals when enabled, Esc cancels.

#### Examples

```dart
final token = terminice.password('API token');

if (token == null) {
  print('Token entry cancelled.');
}
```

```dart
final pin = terminice.password(
  'Deployment PIN',
  maskChar: '*',
  allowReveal: false,
);
```

```dart
final newPassword = terminice.password(
  'New account password',
  verify: true,
);

if (newPassword != null) {
  print('Password accepted.');
}
```

> **Why use this?**
> Use `password` when the input should behave like text but render safely. Use `verify: true` when a typo would be expensive and you want the confirmation logic built in.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `confirm` - Yes/No Confirmation

Ask for a boolean decision with two labeled choices and a configurable default focus. It is ideal for destructive actions, deployment gates, and "continue?" checkpoints.

- `confirm`
  `({prompt, required message, yesLabel, noLabel, defaultYes})`
  Opens a two-option confirmation prompt.
- `prompt` - Frame title. Defaults to `'Confirm'`.
- `message` - Main question displayed inside the prompt.
- `yesLabel` - Positive option label. Defaults to `'Yes'`.
- `noLabel` - Negative option label. Defaults to `'No'`.
- `defaultYes` - Defaults to `true`; controls the initially selected option.
- Returns `bool` - `true` when the positive option is confirmed, `false` when the negative option is confirmed.
- Cancel behavior - Esc/Ctrl+C returns the default option value from `defaultYes` in the current implementation.
- Controls - Left/Right toggles the highlighted option, Enter confirms, Esc/Ctrl+C cancels to the default.

#### Examples

```dart
final shouldDeploy = terminice.confirm(
  prompt: 'Deploy',
  message: 'Ship the current build?',
);

if (shouldDeploy) {
  print('Deploying...');
}
```

```dart
final deleteFile = terminice.confirm(
  prompt: 'Delete file',
  message: 'Remove config.json permanently?',
  defaultYes: false,
);
```

```dart
final restart = terminice.fire.confirm(
  prompt: 'Restart service',
  message: 'Apply changes now?',
  yesLabel: 'Restart',
  noLabel: 'Later',
  defaultYes: false,
);
```

> **Why use this?**
> A plain `stdin.readLineSync()` can only guess what users meant. `confirm` makes the choice explicit, themeable, and keyboard driven.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `multiline` - Terminal Text Area

Capture multi-line text with cursor movement, scrolling, and a dedicated confirm shortcut. This prompt is useful for release notes, commit messages, descriptions, and small config snippets.

- `multiline`
  `(String prompt, {maxLines, visibleLines, allowEmpty})`
  Opens an editable multi-line area.
- `prompt` - Title displayed above the editor.
- `maxLines` - Maximum number of lines the editor may contain. Defaults to `200`.
- `visibleLines` - Height of the scrollable viewport. Defaults to `10`.
- `allowEmpty` - Defaults to `true`; when `false`, Ctrl+D will not confirm until at least one line contains non-whitespace text.
- Returns `String?` - The lines joined with `\n` after Ctrl+D, or `null` on Esc/Ctrl+C.
- Controls - Type normally, Enter inserts a new line, Backspace deletes or merges lines, arrows move the cursor, Ctrl+D confirms, Esc/Ctrl+C cancels.

#### Examples

```dart
final notes = terminice.multiline('Release notes');

print(notes ?? 'No notes entered.');
```

```dart
final commitMessage = terminice.multiline(
  'Commit message',
  visibleLines: 5,
  maxLines: 20,
  allowEmpty: false,
);
```

```dart
final body = terminice.matrix.multiline(
  'Issue description (Ctrl+D to save)',
  visibleLines: 8,
);

final lineCount = body?.split('\n').length ?? 0;
print('Captured $lineCount lines.');
```

> **Why use this?**
> Use `text` for a short answer. Use `multiline` when Enter should create content instead of submitting the prompt.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `slider` - Numeric Selection

Select a single numeric value within a bounded range using left/right keyboard controls. The rendered bar can show raw values, units, and optional percentage context.

- `slider`
  `(String prompt, {min, max, initial, step, width, unit, showPercent})`
  Opens a single-value slider.
- `prompt` - Title displayed above the slider.
- `min` - Lowest selectable value. Defaults to `0`.
- `max` - Highest selectable value. Defaults to `100`.
- `initial` - Starting value. Defaults to `50`; the active slider value is clamped into the range.
- `step` - Amount added/subtracted per arrow press. Defaults to `1`.
- `width` - Visual bar width in characters. Defaults to `28`.
- `unit` - Suffix appended to the displayed value, such as `'MB'`, `'s'`, or `'%'`.
- `showPercent` - When `true`, also displays the selected value as a percentage of the range.
- Returns `num` - The selected value on Enter. Esc/Ctrl+C returns the supplied `initial` value.
- Controls - Left/Right adjusts by `step`, Enter confirms, Esc/Ctrl+C cancels to `initial`.

#### Examples

```dart
final memory = terminice.slider(
  'Memory allocation',
  min: 128,
  max: 2048,
  initial: 512,
  step: 128,
  unit: 'MB',
);
```

```dart
final timeout = terminice.slider(
  'Request timeout',
  min: 0,
  max: 120,
  initial: 30,
  step: 5,
  unit: 's',
);
```

```dart
final rollout = terminice.neon.slider(
  'Rollout',
  min: 0,
  max: 100,
  initial: 25,
  step: 5,
  unit: '%',
  showPercent: true,
);
```

> **Why use this?**
> A slider is faster and safer than asking users to type a number when the valid range is known and small adjustments matter.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `range` - Dual-Handle Numeric Range

Select a start and end value inside the same bounded numeric scale. The active handle can be switched from the keyboard, and confirmed values stay ordered during interaction.

- `range`
  `(String prompt, {min, max, startInitial, endInitial, step, width, unit})`
  Opens a two-handle range prompt.
- `prompt` - Title displayed above the range bar.
- `min` - Lowest allowed value. Defaults to `0`.
- `max` - Highest allowed value. Defaults to `100`.
- `startInitial` - Starting value for the first handle. Defaults to `20`.
- `endInitial` - Starting value for the second handle. Defaults to `80`.
- `step` - Amount added/subtracted from the active handle. Defaults to `1`.
- `width` - Visual bar width in characters. Defaults to `28`; rendering also adapts to terminal width.
- `unit` - Suffix appended to both displayed values. Defaults to `'%'`.
- Returns `RangeResult` - Read values with `.start` and `.end`. Import `package:terminice_core/terminice_core.dart` only if you want to name the type explicitly.
- Cancel behavior - Esc/Ctrl+C returns a `RangeResult` built from the supplied `startInitial` and `endInitial`.
- Controls - Left/Right adjusts the active handle, Up/Down/Space switches handles, Enter confirms, Esc/Ctrl+C cancels to the initial pair.

#### Examples

```dart
final budget = terminice.range(
  'Memory budget',
  min: 0,
  max: 32,
  startInitial: 4,
  endInitial: 16,
  step: 1,
  unit: 'GB',
);

print('Allowed: ${budget.start}GB to ${budget.end}GB');
```

```dart
final quietHours = terminice.range(
  'Quiet hours',
  min: 0,
  max: 24,
  startInitial: 22,
  endInitial: 7,
  unit: 'h',
);
```

```dart
final price = terminice.ocean.range(
  'Price filter',
  min: 0,
  max: 500,
  startInitial: 50,
  endInitial: 250,
  step: 25,
  unit: r'$',
);
```

> **Why use this?**
> Use `slider` for one value. Use `range` when the user is defining a span, such as min/max price, memory budget, or an allowed operating window.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `rating` - Star Rating Input

Collect a small integer rating with stars, number-key shortcuts, and optional labels for each level. This is a compact fit for priority, satisfaction, quality, and risk scoring.

- `rating`
  `(String prompt, {maxStars, initial, labels})`
  Opens a discrete star rating prompt.
- `prompt` - Title displayed above the rating.
- `maxStars` - Maximum rating value. Defaults to `5` and must be greater than `0`.
- `initial` - Starting rating. Defaults to `3`; the active value is clamped into `1..maxStars`.
- `labels` - Optional labels displayed for each rating value when the list has at least `maxStars` entries.
- Returns `int` - The confirmed rating. Esc/Ctrl+C returns the supplied `initial` value.
- Controls - Left/Right adjusts the rating, number keys jump directly to a value, Enter confirms, Esc/Ctrl+C cancels to the initial rating.

#### 🧪 Examples

```dart
final satisfaction = terminice.rating('Satisfaction');

print('User rated this $satisfaction/5.');
```

```dart
final priority = terminice.rating(
  'Priority',
  initial: 3,
  labels: ['Lowest', 'Low', 'Medium', 'High', 'Critical'],
);
```

```dart
final risk = terminice.fire.rating(
  'Risk level',
  maxStars: 10,
  initial: 4,
);
```

> **Why use this?**
> Ratings keep bounded integer input quick. Number keys make exact selection fast, while labels let you turn numbers into meaningful domain language.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `date` - Keyboard Date Prompt

Collect a calendar date by editing day, month, and year fields directly. It renders a formatted preview so the selected date is easy to verify before confirmation.

- `date`
  `(String prompt, {initial})`
  Opens a three-field date selector.
- `prompt` - Title displayed above the selector. If an empty string is passed, the prompt uses `'Date'`.
- `initial` - Optional starting `DateTime`. When omitted, the prompt starts from `DateTime.now()`.
- Returns `DateTime?` - The selected date on Enter, or `null` on Esc/Ctrl+C.
- Controls - Left/Right switches between day/month/year, Up/Down adjusts the active field, Ctrl+E jumps to today, Enter confirms, Esc/Ctrl+C cancels.
- Behavior - The prompt edits calendar fields using Dart `DateTime`, so month/year changes follow Dart's normal date normalization.

#### Examples

```dart
final launchDate = terminice.date(
  'Launch date',
  initial: DateTime(2026, 9, 1),
);

if (launchDate != null) {
  print('Launch: ${launchDate.toIso8601String().split('T').first}');
}
```

```dart
final birthday = terminice.pastel.date('Birthday');

print(birthday == null ? 'Skipped' : 'Saved birthday');
```

```dart
final reviewDate = terminice.date(
  'Next review',
  initial: DateTime.now().add(const Duration(days: 30)),
);
```

> **Why use this?**
> Use `date` when free-form date text would be too error-prone, but a full calendar picker would be more UI than the workflow needs.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `form` - Multi-Field Input

Group several text/password-style fields inside one themed frame. Forms support per-field placeholders, masking, required checks, initial values, per-field validators, and cross-field validation on submit.

Form field and result types come from `terminice_core`, so full form examples use:

```dart
import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';
```

- `form`
  `(String prompt, {required fields, crossValidator})`
  Opens a multi-field input form.
- `prompt` - Title displayed above the form.
- `fields` - List of `FormFieldConfig` objects, rendered top-to-bottom.
- `crossValidator` - Optional `String? Function(List<String> values)`. Return `null` for valid form state, or an error message to block submission.
- Returns `FormResult?` - Confirmed, trimmed field values on success, or `null` on Esc/Ctrl+C. Access values with `result[0]`, `result[1]`, or `result.values`.
- Empty fields behavior - Passing an empty `fields` list returns `FormResult([])`.
- Controls - Type into the focused field, Tab/Down moves next, Up moves previous, Enter moves next or submits from the last field, Ctrl+R reveals the focused masked field when allowed, Esc/Ctrl+C cancels.

`FormFieldConfig` supports:

- `label` - Required label shown beside the input.
- `placeholder` - Optional hint shown when the focused field is empty.
- `masked` - Defaults to `false`; when `true`, the field displays mask characters.
- `maskChar` - Character used for masked fields. Defaults to `'•'`.
- `allowReveal` - Defaults to `false`; when `true`, Ctrl+R toggles plain text for that masked field.
- `required` - Defaults to `false`; empty trimmed values are rejected with `Required`.
- `validator` - Optional `String? Function(String)` per-field validator. Return `null` for valid input, or a non-empty error message. Returning `''` is still accepted as success for backwards compatibility.
- `initialValue` - Optional pre-filled text.

#### Examples

```dart
final login = terminice.form(
  'Login',
  fields: const [
    FormFieldConfig(
      label: 'Username',
      placeholder: 'ada',
      required: true,
    ),
    FormFieldConfig(
      label: 'Password',
      masked: true,
      allowReveal: true,
      required: true,
    ),
  ],
);

if (login != null) {
  print('Signing in ${login[0]}...');
}
```

```dart
final account = terminice.form(
  'Create account',
  fields: [
    FormFieldConfig(
      label: 'Email',
      required: true,
      validator: (value) =>
          value.contains('@') ? null : 'Enter a valid email address',
    ),
    const FormFieldConfig(
      label: 'Password',
      masked: true,
      allowReveal: true,
      required: true,
    ),
    const FormFieldConfig(
      label: 'Confirm',
      masked: true,
      allowReveal: true,
      required: true,
      placeholder: 're-enter password',
    ),
  ],
  crossValidator: (values) {
    if (values[1] != values[2]) return 'Passwords do not match';
    return null;
  },
);
```

```dart
final profile = terminice.ocean.form(
  'Profile',
  fields: const [
    FormFieldConfig(label: 'Display name', initialValue: 'Ada'),
    FormFieldConfig(label: 'Team', placeholder: 'Platform'),
    FormFieldConfig(label: 'Pager', required: false),
  ],
);

final values = profile?.values ?? const <String>[];
print('Captured ${values.length} fields.');
```

> **Why use this?**
> Use separate prompts when each answer should feel like its own step. Use `form` when the inputs belong together and should validate as one unit, such as login, signup, or connection settings.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `searchSelector` - Filterable List Selection

Pick from a vertical list that can be filtered in place. It works as a quick single-choice selector by default, or as a multi-select searchable checklist when `multiSelect` is enabled.

- `searchSelector`
  `({required options, prompt, multiSelect, showSearch, maxVisible})`
  Opens a searchable list prompt.
- `options` - `List<String>` displayed in the list. Passing an empty list returns `[]` immediately.
- `prompt` - Frame title. Defaults to `'Select an option'`.
- `multiSelect` - Defaults to `false`. When `true`, Space toggles the focused row and Enter returns all selected labels.
- `showSearch` - Defaults to `false`. When `true`, the search field starts open; otherwise `/` toggles search mode.
- `maxVisible` - Maximum list rows before scrolling. Defaults to `10`; the prompt also adapts to terminal height.
- Returns `List<String>` - Confirmed labels. Single-select returns a one-item list. Multi-select returns checked labels, or the focused label if nothing was checked.
- Cancel behavior - Esc/Ctrl+C returns `[]`. Empty options and no-match confirmation also return `[]`.
- Controls - Up/Down navigates, `/` toggles search, type filters while search is open, Space toggles in multi-select, Enter confirms, Esc/Ctrl+C cancels.

#### Examples

```dart
final language = terminice.searchSelector(
  prompt: 'Primary language',
  options: const ['Dart', 'Go', 'Rust', 'TypeScript', 'Python'],
  showSearch: true,
);

final selectedLanguage = language.isEmpty ? null : language.first;
print(selectedLanguage ?? 'No language selected.');
```

```dart
final services = terminice.searchSelector(
  prompt: 'Restart services',
  options: const ['api', 'worker', 'scheduler', 'web', 'metrics'],
  multiSelect: true,
  showSearch: true,
  maxVisible: 4,
);

if (services.isNotEmpty) {
  print('Restarting ${services.join(', ')}');
}
```

```dart
final region = terminice.ocean.compact.searchSelector(
  prompt: 'Region',
  options: const ['us-east-1', 'us-west-2', 'eu-central-1', 'ap-south-1'],
);

final selectedRegion = region.isEmpty ? 'none' : region.first;
print('Region: $selectedRegion');
```

> **Why use this?**
> Use `searchSelector` when the list may be longer than the terminal viewport, or when users know the item name and should be able to filter instead of arrowing through everything.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `choiceSelector` - Card-Based Choice Grid

Render choices as two-line cards with a label and optional subtitle. It is useful when each option needs a little context, such as actions, plans, environments, or workflows.

- `choiceSelector`
  `(String prompt, {required items, multiSelect, columns, cardWidth, maxColumns})`
  Opens a themed grid of choice cards.
- `prompt` - Frame title displayed above the grid.
- `items` - `List<ChoiceItem>`. Passing an empty list returns `[]` immediately.
- `ChoiceItem(label, {subtitle})` - Card model exported by `package:terminice/terminice.dart`; `label` is returned, `subtitle` is rendered dimmed below it.
- `multiSelect` - Defaults to `false`. When `true`, each card shows a checkbox and Space toggles the focused card.
- `columns` - Fixed column count. Defaults to `0`, which lets the selector compute columns from terminal width and item count.
- `cardWidth` - Optional card width override, clamped by the implementation to 16-44 characters.
- `maxColumns` - Optional cap used by automatic column layout.
- Returns `List<String>` - Confirmed `ChoiceItem.label` values. Single-select returns one label. Multi-select returns selected labels, or the focused label if nothing was checked.
- Cancel behavior - Esc/Ctrl+C returns `[]`.
- Controls - Arrow keys navigate across cards with wrapping, Space toggles in multi-select, Enter confirms, Esc/Ctrl+C cancels.

#### Examples

```dart
final action = terminice.choiceSelector(
  'Next action',
  items: const [
    ChoiceItem('Preview', subtitle: 'Render a local diff'),
    ChoiceItem('Publish', subtitle: 'Deploy the current build'),
    ChoiceItem('Rollback', subtitle: 'Restore previous version'),
  ],
);

final selectedAction = action.isEmpty ? 'none' : action.first;
print('Action: $selectedAction');
```

```dart
final checks = terminice.choiceSelector(
  'Run checks',
  items: const [
    ChoiceItem('Format', subtitle: 'dart format'),
    ChoiceItem('Analyze', subtitle: 'dart analyze'),
    ChoiceItem('Test', subtitle: 'dart test'),
    ChoiceItem('Build', subtitle: 'compile release artifact'),
  ],
  multiSelect: true,
  columns: 2,
);

print('Selected checks: ${checks.join(', ')}');
```

```dart
final environment = terminice.fire.choiceSelector(
  'Environment',
  items: const [
    ChoiceItem('Dev', subtitle: 'Local dependencies'),
    ChoiceItem('Stage', subtitle: 'Shared QA stack'),
    ChoiceItem('Prod', subtitle: 'Customer traffic'),
  ],
  cardWidth: 24,
  maxColumns: 3,
);
```

> **Why use this?**
> Use `searchSelector` for fast text filtering. Use `choiceSelector` when the shape of the decision matters and subtitles help users choose confidently.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `checkboxSelector` - Multi-Select Checklist

Display a vertical checklist with a live summary line and a select-all shortcut. It is the most direct selector for enabling features, choosing tasks, or collecting a small set of labels.

- `checkboxSelector`
  `(String prompt, {required options, initialSelected, maxVisible})`
  Opens a multi-select checklist.
- `prompt` - Frame title displayed above the checklist.
- `options` - `List<String>` labels displayed beside checkboxes. Passing an empty list returns `[]` immediately.
- `initialSelected` - Optional `Set<int>` of zero-based option indices that start checked. Invalid indices are ignored by the underlying prompt.
- `maxVisible` - Maximum visible rows before scrolling. Defaults to `12`; the prompt also adapts to terminal height.
- Returns `List<String>` - Confirmed labels in option order. If the user confirms while nothing is checked, the currently focused option is returned.
- Cancel behavior - Esc/Ctrl+C returns `[]`.
- Controls - Up/Down navigates, Space toggles the focused option, `A` selects all or clears all, Enter confirms, Esc/Ctrl+C cancels.

#### Examples

```dart
final features = terminice.checkboxSelector(
  'Enable features',
  options: const ['Dark mode', 'Notifications', 'Auto-save', 'Sync'],
  initialSelected: {0},
);

print('Enabled: ${features.join(', ')}');
```

```dart
final migrations = terminice.checkboxSelector(
  'Migrations',
  options: const [
    'Create users table',
    'Backfill display names',
    'Add billing index',
    'Vacuum old events',
  ],
  maxVisible: 3,
);

if (migrations.isEmpty) {
  print('No migrations selected.');
}
```

```dart
final labels = terminice.matrix.checkboxSelector(
  'Issue labels',
  options: const ['bug', 'feature', 'docs', 'good first issue'],
  initialSelected: {1, 2},
);
```

> **Why use this?**
> Use `checkboxSelector` when every option is a simple on/off inclusion. Use `choiceSelector` when each option needs a card subtitle, and `tagSelector` when a compact chip layout fits better.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `gridSelector` - Two-Dimensional Selection Grid

Arrange string options into a responsive grid with wrapping arrow-key navigation. It is a good fit for compact fixed vocabularies where scanning by rows and columns is faster than a vertical list.

- `gridSelector`
  `({required options, prompt, columns, multiSelect, cellWidth, maxColumns, initialSelection})`
  Opens a grid selector.
- `options` - `List<String>` labels rendered inside cells. Passing an empty list returns `[]`.
- `prompt` - Frame title. Defaults to `'Select'`.
- `columns` - Fixed column count. Defaults to `0`, which computes a responsive column count.
- `multiSelect` - Defaults to `false`. When `true`, cells include checkbox markers and Space toggles the focused cell.
- `cellWidth` - Optional fixed width per cell. When omitted, width is computed from item labels and clamped by the core grid prompt.
- `maxColumns` - Optional cap for automatic layout.
- `initialSelection` - Optional `Set<int>` of zero-based indices that start selected. Invalid indices are ignored.
- Returns `List<String>` - Confirmed labels in option order. Single-select returns the focused label. Multi-select returns checked labels, or the focused label if none were checked.
- Cancel behavior - Esc/Ctrl+C returns `[]`.
- Controls - Arrow keys move in two dimensions with wrapping, Space toggles in multi-select, Enter confirms, Esc/Ctrl+C cancels.

#### Examples

```dart
final color = terminice.gridSelector(
  prompt: 'Accent color',
  options: const ['Red', 'Blue', 'Green', 'Yellow'],
  columns: 2,
);

final selectedColor = color.isEmpty ? 'none' : color.first;
print('Color: $selectedColor');
```

```dart
final targets = terminice.gridSelector(
  prompt: 'Deploy targets',
  options: const ['api', 'web', 'worker', 'scheduler', 'cron', 'docs'],
  multiSelect: true,
  initialSelection: {0, 2},
  maxColumns: 3,
);

print('Targets: ${targets.join(', ')}');
```

```dart
final size = terminice.neon.gridSelector(
  prompt: 'Instance size',
  options: const ['small', 'medium', 'large', 'xlarge'],
  cellWidth: 14,
);
```

> **Why use this?**
> Use `gridSelector` when options are short and benefit from spatial scanning. Use `searchSelector` when the list is long or users need filtering.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `tagSelector` - Chip-Style Multi-Select

Render tags as compact `[ tag ]` chips in a responsive grid. The selector is always multi-select and shows a count summary while the user toggles chips.

- `tagSelector`
  `({required tags, prompt, maxContentWidth, minContentWidth, minColumnWidth, maxColumnWidth, useTerminalWidth})`
  Opens a chip-style tag selector.
- `tags` - `List<String>` labels rendered inside chips. Passing an empty list returns `[]` immediately.
- `prompt` - Frame title. Defaults to `'Select tags'`.
- `maxContentWidth` - Optional cap for the inner content width.
- `minContentWidth` - Lower bound for content width before wrapping. Defaults to `32`.
- `minColumnWidth` - Minimum chip column width. Defaults to `8`.
- `maxColumnWidth` - Maximum chip column width. Defaults to `24`.
- `useTerminalWidth` - Defaults to `true`; when enabled, layout is recomputed from the current terminal width during rendering.
- Returns `List<String>` - Confirmed tags in tag order. If Enter is pressed before any chip is toggled, the focused tag is returned.
- Cancel behavior - Esc/Ctrl+C returns `[]`.
- Controls - Arrow keys move between chips, Space toggles the focused chip, Enter confirms, Esc/Ctrl+C cancels.

#### Examples

```dart
final issueLabels = terminice.tagSelector(
  prompt: 'Issue labels',
  tags: const ['bug', 'feature', 'docs', 'chore', 'blocked'],
);

print('Labels: ${issueLabels.join(', ')}');
```

```dart
final interests = terminice.tagSelector(
  prompt: 'Interests',
  tags: const [
    'Dart',
    'CLI',
    'Automation',
    'Testing',
    'Design',
    'Docs',
  ],
  maxContentWidth: 72,
  minColumnWidth: 12,
);
```

```dart
final compactTags = terminice.pastel.compact.tagSelector(
  prompt: 'Release tags',
  tags: const ['stable', 'beta', 'internal', 'breaking', 'security'],
  maxColumnWidth: 16,
);
```

> **Why use this?**
> Use `tagSelector` when the selected values are labels and a compact chip grid is easier to scan than a tall checklist.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `toggleGroup` - Editable Boolean Switches

Edit several independent on/off states in one prompt. Unlike a radio group, `toggleGroup` is not mutually exclusive: every row has its own boolean state.

- `toggleGroup (String prompt, {required items, alignContent})`
  Opens a vertical group of switches.
- `prompt` - Frame title displayed above the switches.
- `items` - `List<ToggleItem>`. Passing an empty list returns `{}` immediately.
- `ToggleItem(label, {initialOn})` - Switch model exported by `package:terminice/terminice.dart`; `initialOn` defaults to `false`.
- `alignContent` - Present in the public API for alignment control; the current renderer pads labels into a tidy column.
- Returns `Map<String, bool>` - Confirmed switch states keyed by `ToggleItem.label`. Keep labels unique, because duplicate labels overwrite earlier entries in the returned map.
- Cancel behavior - Esc/Ctrl+C returns a map built from the initial states, not an empty map.
- Controls - Up/Down navigates rows, Left/Right/Space toggles the focused switch, `A` toggles all switches, Enter confirms, Esc/Ctrl+C cancels to the initial map.

#### Examples

```dart
final settings = terminice.toggleGroup(
  'Settings',
  items: const [
    ToggleItem('Auto deploy', initialOn: true),
    ToggleItem('Send email'),
    ToggleItem('Write audit log', initialOn: true),
  ],
);

if (settings['Auto deploy'] == true) {
  print('Auto deploy is enabled.');
}
```

```dart
final flags = terminice.toggleGroup(
  'Feature flags',
  items: const [
    ToggleItem('New checkout'),
    ToggleItem('Fast search', initialOn: true),
    ToggleItem('Verbose logs'),
  ],
);

for (final entry in flags.entries) {
  print('${entry.key}: ${entry.value ? "on" : "off"}');
}
```

```dart
final permissions = terminice.monochrome.toggleGroup(
  'Permissions',
  items: const [
    ToggleItem('Read', initialOn: true),
    ToggleItem('Write'),
    ToggleItem('Admin'),
  ],
);
```

> **Why use this?**
> Use `checkboxSelector` when you only need a list of enabled labels. Use `toggleGroup` when both enabled and disabled states matter after the prompt returns.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `commandPalette` - Fuzzy Command Launcher

Open a command palette that searches command titles and optional subtitles, ranks matches, and returns the selected command entry. It behaves like a compact launcher for CLIs with many actions.

- `commandPalette (String prompt, {required commands, maxVisible})`
  Opens a ranked command list with an always-visible search input.
- `prompt` - Frame title displayed above the palette.
- `commands` - `List<CommandEntry>`. Passing an empty list returns `null` immediately.
- `CommandEntry({required id, required title, subtitle})` - Command model exported by `package:terminice/terminice.dart`.
- `id` - Stable identifier returned with the selected entry; use it for dispatching.
- `title` - Primary searchable label shown in the list.
- `subtitle` - Optional secondary searchable text rendered dimmed beside the title.
- `maxVisible` - Maximum result rows before scrolling. Defaults to `12`; the prompt also adapts to terminal height.
- Ranking - Empty query shows all commands. Non-empty query uses fuzzy matching by default, searches title first, falls back to subtitle, and Ctrl+R toggles fuzzy vs substring mode.
- Returns `CommandEntry?` - The selected entry on Enter, or `null` when cancelled, when commands are empty, or when Enter is pressed with no matches.
- Cancel behavior - Esc/Ctrl+C returns `null`.
- Controls - Type to search, Backspace edits, Up/Down navigates matches, Ctrl+R toggles ranking mode, Enter confirms, Esc/Ctrl+C cancels.

#### Examples

```dart
final command = terminice.commandPalette(
  'Command Palette',
  commands: const [
    CommandEntry(id: 'open', title: 'Open Project', subtitle: 'Ctrl+O'),
    CommandEntry(id: 'build', title: 'Build Release', subtitle: 'compile'),
    CommandEntry(id: 'deploy', title: 'Deploy', subtitle: 'production'),
  ],
);

switch (command?.id) {
  case 'open':
    print('Opening project...');
    break;
  case 'build':
    print('Building release...');
    break;
  case 'deploy':
    print('Deploying...');
    break;
  default:
    print('No command selected.');
}
```

```dart
final selected = terminice.commandPalette(
  'Git action',
  commands: const [
    CommandEntry(id: 'status', title: 'Git: Status', subtitle: 'working tree'),
    CommandEntry(id: 'commit', title: 'Git: Commit', subtitle: 'create commit'),
    CommandEntry(id: 'push', title: 'Git: Push', subtitle: 'origin'),
    CommandEntry(id: 'pull', title: 'Git: Pull', subtitle: 'origin'),
  ],
  maxVisible: 4,
);

print('Selected command id: ${selected?.id ?? "none"}');
```

```dart
final tool = terminice.arcane.commandPalette(
  'Toolbox',
  commands: const [
    CommandEntry(id: 'format', title: 'Format Dart', subtitle: 'dart format'),
    CommandEntry(id: 'analyze', title: 'Analyze Dart', subtitle: 'dart analyze'),
    CommandEntry(id: 'test', title: 'Run Tests', subtitle: 'dart test'),
  ],
);
```

> **Why use this?**
> Use `commandPalette` when the user is choosing an action by name. It returns the whole `CommandEntry`, so display text and dispatch IDs can stay separate.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `filePicker` - Searchable File Browser

Browse the filesystem from a starting directory and return the selected file path. The picker renders each directory as an enterable row, adds a parent-directory row when possible, and uses the searchable selector UI so users can filter large folders before choosing.

- `filePicker(String prompt, {startDirectory, showHidden, foldersOnly})`
  Opens a searchable filesystem browser.
- `prompt` - Base title for the frame. The current path is appended in parentheses and shortened when it is longer than 60 visible characters.
- `startDirectory` - Optional `Directory` used as the first folder. Defaults to `Directory.current`.
- `showHidden` - Defaults to `false`. When `true`, entries whose basename starts with `.` are included.
- `foldersOnly` - Defaults to `false`. When `true`, file choices are not returned; directories remain navigation targets. Use `pathPicker` when you need a confirmed directory path.
- Returns `String?` - The selected file path when a file is confirmed, or `null` when the user cancels.
- Filesystem behavior - Entries come from `Directory.listSync(followLinks: false)`, sorted with directories first and then by case-insensitive basename. Symlinks are not followed by the listing helper. Unreadable directories can surface the underlying `FileSystemException`.
- Cancel behavior - Esc/Ctrl+C inside the embedded search selector returns `null`.
- Controls - Up/Down navigates rows, `/` toggles search, typing filters while search is open, Enter enters a directory or confirms a file, Esc/Ctrl+C cancels.

#### Examples

```dart
final configPath = terminice.filePicker(
  'Select config file',
  startDirectory: Directory.current,
  showHidden: true,
);

if (configPath == null) {
  print('No config selected.');
} else {
  final contents = File(configPath).readAsStringSync();
  print('Loaded ${contents.length} characters from $configPath');
}
```

```dart
final assetPath = terminice.ocean.compact.filePicker(
  'Select asset',
  startDirectory: Directory.current,
);

if (assetPath != null) {
  print('Asset: $assetPath');
}
```

```dart
final picked = terminice.filePicker(
  'Browse without dotfiles',
  startDirectory: Directory.systemTemp,
);

print(picked ?? 'Selection cancelled.');
```

> **Why use this?**
> Use `filePicker` when the user needs to choose an existing file from a folder tree. Use `pathPicker` when confirming the current directory is part of the workflow.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `pathPicker` - Directory and Path Browser

Choose a directory, or optionally a file, from a dynamic filesystem list. Unlike `filePicker`, this prompt includes an explicit `✓ Select this directory` row, so it is the right picker for output folders, project roots, cache locations, and other directory targets.

- `pathPicker (String prompt, {startDirectory, showHidden, allowFiles, maxVisible})`
  Opens a dynamic path browser.
- `prompt` - Frame title displayed above the picker.
- `startDirectory` - Optional `Directory` used as the starting point. Defaults to `Directory.current`.
- `showHidden` - Defaults to `false`. When enabled, dotfiles and dot directories are included.
- `allowFiles` - Defaults to `false`. When `true`, files are shown and can be confirmed; when `false`, only directories plus navigation rows are shown.
- `maxVisible` - Maximum visible rows before the list scrolls. Defaults to `18`.
- Returns `String?` - The chosen directory path from `✓ Select this directory`, the chosen file path when `allowFiles` is enabled, or `null` on cancel.
- Filesystem behavior - Entries are rebuilt as the current directory changes. Directories are sorted before files, hidden entries are filtered unless requested, and symlinks are not followed while listing. Permission errors while reading a directory are swallowed so the parent/current-directory controls can still render.
- Cancel behavior - Esc/Ctrl+C returns `null`.
- Controls - Up/Down navigates, Enter/Right enters a directory or confirms the focused action, Left moves to the parent directory when one exists, Esc/Ctrl+C cancels.

#### Examples

```dart
final projectRoot = terminice.pathPicker(
  'Select project root',
  startDirectory: Directory.current,
);

if (projectRoot != null) {
  print('Project root: $projectRoot');
}
```

```dart
final inputPath = terminice.pathPicker(
  'Select input path',
  startDirectory: Directory.current,
  allowFiles: true,
  maxVisible: 12,
);

if (inputPath != null) {
  final type = FileSystemEntity.typeSync(inputPath);
  final kind = type == FileSystemEntityType.directory ? 'directory' : 'file';
  print('Selected $kind: $inputPath');
}
```

```dart
final exportDir = terminice.neon.pathPicker(
  'Choose export folder',
  startDirectory: Directory.systemTemp,
  showHidden: true,
);

print(exportDir == null ? 'No export folder selected.' : exportDir);
```

> **Why use this?**
> Use `pathPicker` for directory-first workflows because it can confirm the current folder directly. Turn on `allowFiles` when a command accepts either a file path or a directory path.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `colorPicker` - ANSI Color Grid

Pick a terminal-friendly color from a live ANSI swatch grid. The picker maps horizontal movement to hue, vertical movement to brightness, and separate shortcuts to saturation, presets, randomization, reset, and hex entry.

- `colorPicker (String prompt, {initialHex, cols, rows})`
  Opens an interactive color grid.
- `prompt` - Frame title displayed above the grid.
- `initialHex` - Optional starting color. Accepts `#RRGGBB` or `RRGGBB`; invalid values are ignored. The picker positions the cursor near the requested color on the HSV grid.
- `cols` - Number of hue columns. Defaults to `24`; larger values give finer horizontal hue steps.
- `rows` - Number of brightness rows. Defaults to `8`; larger values give finer vertical brightness steps.
- Returns `String?` - The selected color as uppercase `#RRGGBB`, or `null` when cancelled.
- Color behavior - The return value is generated from the currently highlighted HSV grid cell. Hex entry and `initialHex` move the grid selection to the nearest represented color rather than storing a separate exact text value.
- Hex entry - Press `H` to type a hex value. Enter applies valid input and leaves invalid input unchanged; Esc exits hex entry without cancelling the picker.
- Cancel behavior - Esc/Ctrl+C outside hex entry returns `null`.
- Controls - Arrow keys move the cursor, Left/Right wrap across hue columns, `S` cycles saturation breakpoints, `[` and `]` fine-tune saturation, `-` and `=`/`+` adjust brightness, `1-0` jump to presets, `R` randomizes, `X` resets, Enter confirms.

#### Examples

```dart
final accent = terminice.colorPicker(
  'Accent color',
  initialHex: '#3B82F6',
);

print(accent == null ? 'No accent selected.' : 'Accent: $accent');
```

```dart
final brandColor = terminice.colorPicker(
  'Brand color',
  initialHex: 'ffcc00',
  cols: 36,
  rows: 10,
);

if (brandColor != null) {
  print('Use $brandColor in generated config.');
}
```

```dart
final dangerColor = terminice.arcane.colorPicker(
  'Danger color',
  cols: 16,
  rows: 6,
);

print(dangerColor ?? '#EF4444');
```

> **Why use this?**
> Use `colorPicker` when the user should see the color before committing it. It is faster than asking for raw hex, but still lets precise users jump in with `H`.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `datePicker` - Calendar Date Selection

Pick a single calendar date from a framed month view. The selected day stays highlighted as the user moves by day, week, or year, and today is accented for orientation.

- `datePicker (String prompt, {initialDate, startWeekOnMonday, allowPast, allowFuture})`
  Opens an interactive calendar.
- `prompt` - Frame title displayed above the calendar.
- `initialDate` - Optional starting date. Defaults to `DateTime.now()` and is normalized to year/month/day for the initial selection.
- `startWeekOnMonday` - Defaults to `true`. When `false`, the calendar renders Sunday as the first weekday.
- `allowPast` / `allowFuture` - Defaults to `true`. Set either to `false` to clamp the initial date and keyboard navigation at today.
- Returns `DateTime?` - The selected date on Enter, or `null` when cancelled.
- Date behavior - Left/Right move one day, Up/Down move one week, and W/S move one year while keeping the visible month synced to the selected date. Ctrl+E jumps to today.
- Normalization note - The returned selection is date-only.
- Cancel behavior - Esc/Ctrl+C returns `null`.
- Controls - Left/Right move by day, Up/Down move by week, W/S move by year, Ctrl+E jumps to today, Enter confirms, Esc/Ctrl+C cancels.

#### Examples

```dart
final releaseDate = terminice.datePicker(
  'Release date',
  initialDate: DateTime(2026, 1, 15),
);

if (releaseDate != null) {
  final yyyy = releaseDate.year.toString().padLeft(4, '0');
  final mm = releaseDate.month.toString().padLeft(2, '0');
  final dd = releaseDate.day.toString().padLeft(2, '0');
  print('Release: $yyyy-$mm-$dd');
}
```

```dart
final birthday = terminice.datePicker(
  'Birthday',
  startWeekOnMonday: false,
);

if (birthday != null && birthday.isAfter(DateTime.now())) {
  print('Birthday cannot be in the future.');
}
```

```dart
DateTime dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

final shipDate = terminice.ocean.datePicker(
  'Ship date',
  initialDate: DateTime.now(),
);

final normalizedShipDate = shipDate == null ? null : dateOnly(shipDate);
print(normalizedShipDate ?? 'No ship date selected.');
```

> **Why use this?**
> Use `datePicker` when a visual calendar prevents off-by-one mistakes. Use the simpler `date` prompt when users already know the exact date string they want to type.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### Message Primitives - Small Status Lines

Write small, synchronous terminal messages through the configured `Terminice` instance. These helpers are useful for the connective tissue around richer UI: setup notes before a prompt, final status after a task, warnings inside a flow, or quiet detail text after a command completes.

- `log(Object? message)` - Writes `message.toString()` as a plain line with no status decoration.
- `info(Object? message)` - Writes an informational status line.
- `success(Object? message)` - Writes a success status line.
- `warn(Object? message)` - Writes a warning status line.
- `error(Object? message)` - Writes an error status line.
- `err(Object? message)` - Alias for `error`.
- `detail(Object? message)` - Writes a modest detail line for secondary context.
- `newline([int count = 1])` - Writes one or more blank lines.
- Plain rendering - Fallback, noninteractive terminals, basic/legacy compatibility, no-color themes, and ASCII glyph themes render ANSI-free plain lines.
- Scope - These are CLI message primitives, not logging infrastructure. They do not manage levels, sinks, timestamps, structured records, or filtering.

#### Examples

```dart
terminice.info('Installing dependencies');
terminice.success('Project ready');
terminice.warn('Using cached config');
terminice.error('Publish failed');
terminice.err('Retry failed');
terminice.detail('Run with --verbose for more output');
terminice.log('Next: dart run');
terminice.newline();
```

```dart
final t = terminice.autoFallback;

t.info('Installing dependencies');

await t.task(
  'Resolving packages',
  run: runPubGet,
  success: 'Dependencies installed',
);

final publish = t.confirm(message: 'Publish release?');

if (publish) {
  t.success('Project ready');
} else {
  t.warn('Publish skipped');
  t.detail('Run with --verbose for more output');
}
```

> **Why use this?**
> Use message primitives when you want polished, consistent terminal-facing status lines without bringing in a logging framework. They give command output the same theme, terminal, fallback, compatibility, and test behavior as Terminice prompts and tasks.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `task` - Async Status Wrapper

Run a synchronous or asynchronous operation while `terminice` renders a small status indicator. Use it when the work is indeterminate: publishing, polling, resolving dependencies, or any operation where there is no useful total.

- `task<T>(String prompt, {required run, message, success, failure, cancel, isCanceled, interval, style, indicator, maxDots, display, finalBehavior})`
  Runs `run` and completes with its typed result.
- `prompt` - Main status label. It is also the default success message.
- `run` - A `FutureOr<T> Function()` containing the work.
- `message` - Optional detail shown beside the prompt while running.
- `success` - Optional final success text. Defaults to `prompt`.
- `failure` - Optional `String Function(Object error, StackTrace stackTrace)` for failure text. Defaults to `'$prompt failed: $error'`.
- `cancel` - Optional formatter for cancellation text. Defaults to `'$prompt canceled'`.
- `isCanceled` - Optional predicate that decides whether a thrown error should be labelled as cancellation instead of failure.
- `interval`, `style`, `indicator`, `maxDots` - Tune the running animation. `indicator` can use spinner frames or cycling dots.
- `display` - A `TaskDisplay` value: `auto`, `inline`, or `plain`. `TaskDisplay.plain`, fallback modes, non-terminal IO, and non-modern compatibility avoid ANSI cursor control and animation.
- `finalBehavior` - A `TaskFinalBehavior` value controlling whether the final status line remains visible.
- Returns `Future<T>` - The exact result from `run`.
- Error behavior - Synchronous throws and asynchronous errors render failure or cancel status, then rethrow the original error with its stack trace.

#### Examples

```dart
final result = await terminice.task('Publishing', run: publish);
```

```dart
try {
  await terminice.task(
    'Deploying',
    run: deploy,
    isCanceled: (error) => error is OperationCanceledException,
    cancel: (error, stack) => 'Deployment canceled',
  );
} catch (error) {
  // The final status was already rendered; handle or rethrow as needed.
}
```

> **Why use this?**
> Use `task` when you want async status and cleanup without manually wiring timers, cursor hiding, final status lines, or error rendering.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `progressTask` - Async Progress Wrapper

Run work with a determinate progress bar. `progressTask` passes a mutable `TaskProgress` object into your callback, so the task can update count and detail text as it advances.

- `progressTask<T>(String prompt, {required total, required run, message, success, failure, cancel, isCanceled, display, finalBehavior, interval, progressWidth})`
  Runs `run` while rendering progress.
- `prompt` - Main status label.
- `total` - Total units of work. Must be greater than `0`.
- `run` - A `FutureOr<T> Function(TaskProgress progress)` callback.
- `message` - Optional initial detail text.
- `success`, `failure`, `cancel`, `isCanceled` - Same semantics as `task`.
- `display` - A `TaskDisplay` value: `auto`, `inline`, or `plain`. Plain and fallback rendering avoid ANSI/control output.
- `finalBehavior` - Controls whether the final status line is persisted or cleared.
- `interval` - Animation refresh interval. Defaults to `80ms`.
- `progressWidth` - Width of the inline progress bar used by task rendering.
- Returns `Future<T>` - The result from `run`.
- Progress behavior - Current progress is clamped to `0..total`; invalid totals are rejected before the task starts.
- Error behavior - Errors are rendered as failure or cancel status, then rethrown.

#### Examples

```dart
await terminice.progressTask(
  'Uploading',
  total: files.length,
  run: (progress) async { ... },
);
```

```dart
await terminice.progressTask(
  'Uploading',
  total: files.length,
  run: (progress) async {
    for (final file in files) {
      progress.update(message: file.path);
      await upload(file);
      progress.increment();
    }
  },
);
```

> **Why use this?**
> Use `progressTask` when your async work has a known total and the task itself should own progress updates.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `trackStream` - Stream Progress Collector

Collect every event from a stream while advancing determinate progress once per event. The returned list preserves stream order.

- `trackStream<T>(String prompt, Stream<T> source, {required total, message, success, failure, cancel, isCanceled, display, finalBehavior, interval, progressWidth})`
  Tracks and collects `source`.
- `prompt` - Main status label.
- `source` - Stream to listen to.
- `total` - Expected number of events. Must be greater than `0`.
- `message`, `success`, `failure`, `cancel`, `isCanceled`, `display`, `finalBehavior`, `interval`, `progressWidth` - Same behavior as `progressTask`.
- Returns `Future<List<T>>` - All stream values, in order.
- Error behavior - Stream errors render failure or cancel status, then rethrow.

#### Examples

```dart
final items = await terminice.trackStream(
  'Downloading',
  stream,
  total: count,
);
```

```dart
final records = await terminice.ocean.trackStream(
  'Importing records',
  readRecords(),
  total: expectedRecords,
  success: 'Imported records',
);
```

> **Why use this?**
> Use `trackStream` when each stream event maps to one progress unit and you want the collected values back after rendering completes.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `TaskProgress` - Mutable Progress State

`TaskProgress` is the handle passed to `progressTask` callbacks and indicator `whileRunning` callbacks. Mutating it updates the rendered progress.

- `current` - Completed units, clamped to the inclusive `0..total` range.
- `total` - Total units expected for the task. Must be greater than `0`.
- `message` - Optional detail shown beside the prompt.
- `ratio` - Completion ratio between `0` and `1`.
- `isComplete` - `true` when `current >= total`.
- `update({current, total, message})` - Updates progress. Passing `null` for `message` leaves the current message unchanged.
- `increment([by = 1])` - Advances `current` by `by`, clamped to `total`.

#### Examples

```dart
await terminice.progressTask(
  'Processing',
  total: jobs.length,
  run: (progress) async {
    for (final job in jobs) {
      progress.update(message: job.name);
      await job.run();
      progress.increment();
    }
  },
);
```

> **Why use this?**
> Use `TaskProgress` as the single source of truth for count, total, and per-step detail during async progress rendering.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `TaskDisplay` - Task Rendering Mode

Choose how async task helpers render while work is running.

- `TaskDisplay.auto` - Default. Uses animated inline rendering when the current terminal and `Terminice` configuration support it; otherwise uses plain line output.
- `TaskDisplay.inline` - Requests animated inline rendering when available; falls back to plain output when animation is unavailable.
- `TaskDisplay.plain` - Uses simple final lines without ANSI cursor control, raw mode, or animation.
- Fallback behavior - Non-terminal IO, `terminice.fallback`, and non-modern compatibility modes use plain rendering. `terminice.autoFallback` uses plain rendering when fallback is needed.

#### Examples

```dart
await terminice.task(
  'Publishing',
  run: publish,
  display: TaskDisplay.plain,
);
```

> **Why use this?**
> Use `TaskDisplay.plain` for logs, CI, tests, or any output stream where control sequences would be noisy.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `TaskFinalBehavior` - Final Output Policy

Control what remains on screen after an async task finishes.

- `TaskFinalBehavior.persist` - Default. Leaves one final success, failure, or cancel status line.
- `TaskFinalBehavior.clear` - Clears the animated task display when it finishes. In plain mode, it suppresses the final status line.
- Applies to success, failure, and cancellation rendering.

#### Examples

```dart
await terminice.task(
  'Refreshing cache',
  run: refreshCache,
  finalBehavior: TaskFinalBehavior.clear,
);
```

> **Why use this?**
> Use `persist` when the task result should remain in command history. Use `clear` for transient status that should disappear after completion.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `loadingSpinner` - Framed Loading Spinner

Show a framed, theme-aware spinner for an ongoing task. This is the most expressive spinner: it has a frame title, a message line, themed spinner glyphs, and footer hints describing the active style.

- `loadingSpinner (String prompt, {message, style})`
  Creates a `LoadingSpinner` controller.
- `prompt` - Frame title displayed above the spinner.
- `message` - Text shown next to the animated glyph. Defaults to `'Loading'`.
- `style` - A `SpinnerStyle` value. Defaults to `SpinnerStyle.dots`; supported styles are `dots`, `bars`, and `arcs`.
- Returns `LoadingSpinner` - The spinner is not displayed until you call `show(...)`, advance it through `runWith(...)`, or wrap work with `whileRunning(...)`.
- `show(int frame)` - Renders one frame. The frame index wraps around the style's glyph list, so any increasing integer works.
- `runWith(void Function(void Function() tick) callback)` - Runs a synchronous callback with a `tick()` function. Each tick renders the next frame, starting at `0`. This callback is not awaited and remains for synchronous work.
- `whileRunning<T>(FutureOr<T> Function() run, {message, success, failure, cancel, isCanceled, interval, display, finalBehavior})` - Runs async or sync work with spinner task rendering and returns the typed result.
- `clear()` - Clears the current spinner frame and resets the internal render state.
- Lifecycle - There is no `start`/`stop` timer for manual rendering. Drive animation from your own loop, timer, synchronous `runWith` callback, or use `whileRunning(...)` for awaited work.
- Cleanup behavior - Manual loops should call `clear()` in `finally`. `runWith` hides the cursor while it runs and clears the spinner after the callback returns normally. `whileRunning` handles async cleanup and final status rendering.

#### Examples

```dart
void main() async {
  final spinner = terminice.loadingSpinner(
    'Installing',
    message: 'Resolving packages',
    style: SpinnerStyle.bars,
  );

  try {
    for (var frame = 0; frame < 12; frame++) {
      spinner.show(frame);
      await Future.delayed(const Duration(milliseconds: 80));
    }
  } finally {
    spinner.clear();
  }

  print('Install complete.');
}
```

```dart
void runStep(String step) {
  // Do synchronous work for this step.
}

final spinner = terminice.ocean.loadingSpinner(
  'Build',
  message: 'Compiling',
  style: SpinnerStyle.arcs,
);

spinner.runWith((tick) {
  for (final step in ['resolve', 'compile', 'package']) {
    tick();
    runStep(step);
  }
});
```

```dart
final release = await terminice.loadingSpinner(
  'Publishing',
  message: 'Uploading archive',
).whileRunning(publish);

print('Published $release.');
```

```dart
final spinner = LoadingSpinner(
  'Deploy',
  message: 'Publishing release',
  style: SpinnerStyle.dots,
  theme: PromptTheme.neon,
);

try {
  for (var frame = 0; frame < 8; frame++) {
    spinner.show(frame);
  }
} finally {
  spinner.clear();
}
```

> **Why use this?**
> Use `loadingSpinner` when the task is indeterminate but important enough to deserve its own framed status area. Use `inlineSpinner` when you want the same idea in a single log-style line.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `inlineSpinner` - One-Line Spinner

Render a compact spinner beside a status label. It is designed for log-style CLIs, CI output, polling loops, and places where a framed widget would be too much visual weight.

- `inlineSpinner (String prompt, {style})`
  Creates an `InlineSpinner` controller.
- `prompt` - Text displayed next to the spinner glyph.
- `style` - A `SpinnerStyle` value. Defaults to `SpinnerStyle.dots`; supported styles are `dots`, `bars`, and `arcs`.
- Returns `InlineSpinner` - The line is not displayed until `show(...)` is called.
- `show(int frame)` - Renders one inline frame and clears the previous inline frame if this controller already drew one.
- `clear()` - Removes the current inline spinner output and resets the controller.
- `InlineSpinner.framesForStyle(SpinnerStyle style)` - Returns the Unicode frame list used by a style, useful when you want to loop exactly one cycle.
- Lifecycle - There is no `start`, `stop`, or dedicated `runWith` helper on `InlineSpinner`. Call `show(...)` from your own loop or timer and finish with `clear()`.
- Async/timer note - If you animate with `Timer.periodic`, cancel the timer yourself before calling `clear()`.

#### Examples

```dart
void main() async {
  final spinner = terminice.inlineSpinner(
    'Waiting for deployment',
    style: SpinnerStyle.arcs,
  );

  try {
    for (var frame = 0; frame < 18; frame++) {
      spinner.show(frame);
      await Future.delayed(const Duration(milliseconds: 70));
    }
  } finally {
    spinner.clear();
  }

  print('Deployment is ready.');
}
```

```dart
final spinner = terminice.matrix.inlineSpinner(
  'Scanning files',
  style: SpinnerStyle.dots,
);

final frameCount = InlineSpinner.framesForStyle(SpinnerStyle.dots).length;

try {
  for (var frame = 0; frame < frameCount; frame++) {
    spinner.show(frame);
  }
} finally {
  spinner.clear();
}
```

```dart
final spinner = InlineSpinner(
  'Syncing cache',
  style: SpinnerStyle.bars,
  theme: PromptTheme.fire,
);

try {
  for (var frame = 0; frame < 10; frame++) {
    spinner.show(frame);
  }
} finally {
  spinner.clear();
}
```

> **Why use this?**
> Use `inlineSpinner` for short-lived or repeated status updates where you do not want a full frame. It gives users motion and context without taking over the terminal.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `progressBar` - Framed Determinate Progress

Display bounded progress in a framed widget with a themed bar, percentage, and raw count. The bar is determinate: you provide `current` and `total` on every update.

- `progressBar (String prompt)`
  Creates a themed `ProgressBar` controller with the default width.
- `prompt` - Frame title displayed above the bar.
- Returns `ProgressBar` - The bar is not displayed until you call `show(...)`, `runWith(...)`, `whileRunning(...)`, or `trackStream(...)`.
- `ProgressBar (String prompt, {width = 36, theme = PromptTheme.dark})`
  Direct constructor for custom width or explicit theme. `width` must be greater than `4`.
- `show({required int current, required int total, int shimmerPhase = 0})` - Renders the current progress state.
- `current` / `total` - Used to compute the ratio. Positive totals clamp the displayed count and percentage into range; when `total <= 0`, the display shows `0/0` and `0%`.
- `shimmerPhase` - Optional phase offset for the filled bar coloring. Increase it as you update to create motion.
- `runWith(void Function(void Function(int current, int total) update) callback)` - Runs a synchronous callback with an `update(current, total)` function. Each update increments the shimmer phase internally. This callback is not awaited and remains for synchronous work.
- `whileRunning<T>(FutureOr<T> Function(TaskProgress progress) run, {required total, message, success, failure, cancel, isCanceled, display, finalBehavior, interval})` - Runs work with a `TaskProgress` handle and returns the typed result.
- `trackStream<T>(Stream<T> source, {required total, message, success, failure, cancel, isCanceled, display, finalBehavior, interval})` - Collects stream events into a `List<T>` while advancing progress once per event.
- `clear()` - Clears the current framed progress output.
- Value behavior - The displayed count, filled width, and percentage all use normalized progress. Positive totals clamp `current` into `0..total`, and the percentage stays within `0..100%`.
- Lifecycle - There is no automatic timer for manual rendering. Use `show(...)` from your own loop, `runWith(...)` for synchronous work, or `whileRunning(...)` / `trackStream(...)` for awaited work.
- Cleanup behavior - Manual loops should call `clear()` in `finally`. `runWith` hides the cursor while it runs and clears the bar after the callback returns normally. Async wrappers handle cleanup and final status rendering.

#### Examples

```dart
void main() async {
  final bar = terminice.progressBar('Downloading SDK');
  const total = 100;

  try {
    for (var current = 0; current <= total; current += 10) {
      bar.show(
        current: current,
        total: total,
        shimmerPhase: current,
      );
      await Future.delayed(const Duration(milliseconds: 90));
    }
  } finally {
    bar.clear();
  }

  print('Download complete.');
}
```

```dart
final files = ['a.dart', 'b.dart', 'c.dart', 'd.dart'];
final bar = terminice.pastel.progressBar('Formatting files');

bar.runWith((update) {
  for (var index = 0; index < files.length; index++) {
    update(index + 1, files.length);
    // Format files[index] synchronously here.
  }
});
```

```dart
await terminice.progressBar('Uploading').whileRunning(
  (progress) async {
    for (final file in files) {
      await upload(file);
      progress.increment();
    }
  },
  total: files.length,
);
```

```dart
final downloads = await terminice.progressBar('Downloading').trackStream(
  downloadStream,
  total: expectedDownloads,
);
```

```dart
final bar = ProgressBar(
  'Uploading archive',
  width: 48,
  theme: PromptTheme.ocean,
);

try {
  bar.show(current: 32, total: 64);
  bar.show(current: 64, total: 64, shimmerPhase: 1);
} finally {
  bar.clear();
}
```

> **Why use this?**
> Use `progressBar` when you know the total amount of work and want a framed progress readout. Use `loadingSpinner` or `progressDots` when the task has no reliable total.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `inlineProgressBar` - One-Line Percent Indicator

Show a compact percentage beside a label. Despite the name, the current implementation is a one-line percent readout rather than a graphical bar, making it useful for dense logs and script output.

- `inlineProgressBar(String prompt)` - Creates an `InlineProgressBar` controller.
- `prompt` - Text displayed before the percentage.
- Returns `InlineProgressBar` - The line is not displayed until `show(...)` is called.
- `InlineProgressBar(String prompt, {theme = PromptTheme.dark})` - Direct constructor for an explicit theme.
- `show({required int current, required int total})` - Renders a normalized percentage next to the prompt.
- `current` / `total` - Provide the current count and total count. Positive totals clamp `current` into `0..total`; when `total <= 0`, the displayed percentage is `0`.
- `clear()` - Clears the current inline progress output.
- Value behavior - The displayed percentage follows the same bounded progress rules as `progressBar`, staying between `0%` and `100%` for positive totals.
- Lifecycle - There is no `start`, `stop`, or dedicated `runWith` helper. Drive it manually from your own loop or timer.
- Cleanup behavior - Repeated `show(...)` calls replace the previous line. Call `clear()` when the operation is finished or cancelled.

#### Examples

```dart
void main() async {
  final progress = terminice.inlineProgressBar('Indexing');
  const total = 50;

  try {
    for (var current = 0; current <= total; current += 5) {
      progress.show(current: current, total: total);
      await Future.delayed(const Duration(milliseconds: 50));
    }
  } finally {
    progress.clear();
  }

  print('Index ready.');
}
```

```dart
final progress = terminice.monochrome.inlineProgressBar('Processed rows');

try {
  progress.show(current: 250, total: 1000);
  progress.show(current: 1000, total: 1000);
} finally {
  progress.clear();
}
```

```dart
final progress = InlineProgressBar(
  'Uploading',
  theme: PromptTheme.arcane,
);

try {
  progress.show(current: 3, total: 12);
} finally {
  progress.clear();
}
```

> **Why use this?**
> Use `inlineProgressBar` when you want the smallest possible determinate progress signal. Use `progressBar` when the user benefits from a framed bar and raw count display.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `progressDots` - Framed Dot Progress

Show ambient progress with a title, message, and cycling dots. It is useful for work that is active but not measurable, such as waiting for a service, preparing a cache, or polling an external process.

- `progressDots(String prompt)` - Creates a themed `ProgressDots` controller.
- `prompt` - Frame title displayed above the dots.
- Returns `ProgressDots` - The indicator is not displayed until you call `show(...)`, `runWith(...)`, or `whileRunning(...)`.
- `ProgressDots(String prompt, {message = 'Working', maxDots = 3, theme = PromptTheme.dark})` - Direct constructor for custom text, dot count, or explicit theme. `maxDots` must be greater than `0`.
- `message` - Text displayed before the animated dots.
- `maxDots` - Maximum number of dots shown before the animation cycles back to zero dots.
- `show({required int phase})` - Renders the dot count for a phase. The count is `phase % (maxDots + 1)`, so `phase: 0` shows the message with no dots.
- `runWith(void Function(void Function() tick) callback)` - Runs a synchronous callback with a `tick()` function. Each tick advances the phase by one. This callback is not awaited and remains for synchronous work.
- `whileRunning<T>(FutureOr<T> Function() run, {message, success, failure, cancel, isCanceled, interval, display, finalBehavior})` - Runs async or sync work with dot task rendering and returns the typed result.
- `clear()` - Clears the current framed dot indicator.
- Lifecycle - There is no automatic timer for manual rendering. Use `show(...)` from your own loop, `runWith(...)` for synchronous work, or `whileRunning(...)` for awaited work.
- Cleanup behavior - Manual loops should call `clear()` in `finally`. `runWith` hides the cursor while it runs and clears after the callback returns normally. `whileRunning` handles async cleanup and final status rendering.

#### Examples

```dart
void main() async {
  final dots = terminice.progressDots('Starting server');

  try {
    for (var phase = 0; phase < 10; phase++) {
      dots.show(phase: phase);
      await Future.delayed(const Duration(milliseconds: 120));
    }
  } finally {
    dots.clear();
  }

  print('Server started.');
}
```

```dart
final dots = ProgressDots(
  'Migrating database',
  message: 'Applying migrations',
  maxDots: 5,
  theme: PromptTheme.fire,
);

try {
  for (var phase = 0; phase < 12; phase++) {
    dots.show(phase: phase);
  }
} finally {
  dots.clear();
}
```

```dart
void doSynchronousPoll() {
  // Check one condition or process one item here.
}

final dots = terminice.neon.progressDots('Waiting for job');

dots.runWith((tick) {
  for (var attempt = 0; attempt < 4; attempt++) {
    tick();
    doSynchronousPoll();
  }
});
```

```dart
await terminice.progressDots('Waiting for job').whileRunning(
  waitForRemoteJob,
  success: 'Job finished',
);
```

> **Why use this?**
> Use `progressDots` when you want calmer feedback than a spinner and do not have a meaningful total for a progress bar.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `flow` - Sequential Flow Composition

Compose several prompts and selectors into one synchronous, sequential flow. Use it when a CLI command needs a handful of related answers, conditional follow-up questions, or a typed result map without manually wiring each prompt together.

Flow is the primary primitive for multi-step Terminice workflows. Steps run from top to bottom, can be skipped with `when`, and can end in a review/edit loop for flow/wizard-style confirmation without introducing a separate `wizard()` API.

For one prompt, call the prompt directly. Flow starts paying for itself when a command needs several related answers, a final review screen, edit-before-submit behavior, reusable step groups, or tests that exercise the whole workflow. It keeps that glue code inside Terminice instead of spreading state, validation, cancellation, and review logic through your command handler.

- `flow`
  `(String title)`
  Creates a `FlowBuilder`.
- `run()` - Runs applicable steps in order and returns a `FlowResult`.
- Step APIs - `text`, `password`, `select`, `checkboxes`, `confirm`, `component`, and `custom`.
- Theming and fallback - Prompt and component steps run through the configured Terminice instance, so themes, compatibility modes, and line-mode fallback behavior carry through.
- Templates - `include(FlowTemplate)` lets you reuse a chunk of steps. Duplicate keys are rejected immediately, just like steps added directly to the builder.
- Review - `.review(...)` adds a final review screen after all applicable steps complete.
- Progress titles - `.progress()` decorates built-in prompt titles as `Step 1/N - Prompt`.

#### Step APIs

- `text(key, prompt, {placeholder, required, validator, validate, when, reviewLabel, summarize, includeInReview, editable})` - Stores `String`; cancel returns `null` from the prompt and cancels the flow by default.
- `password(key, prompt, {required, maskChar, allowReveal, verify, validate, when, reviewLabel, summarize, includeInReview, editable})` - Stores `String`; cancel also cancels the flow by default. Review summaries mask password values by default using eight mask characters.
- `select<T>(key, prompt, {options, labelBuilder, showSearch, maxVisible, validate, when, reviewLabel, summarize, includeInReview, editable})` - Stores the selected `T?`. No selection stores `null` and continues, so use `validate` when one option is required.
- `checkboxes<T>(key, prompt, {options, initialSelected, labelBuilder, maxVisible, validate, when, reviewLabel, summarize, includeInReview, editable})` - Stores an immutable `List<T>`.
- `confirm(key, {prompt, message, yesLabel, noLabel, defaultYes, validate, when, reviewLabel, summarize, includeInReview, editable})` - Stores `bool` and preserves the existing confirm semantics, including cancellation resolving to the default boolean.
- `custom<T>(key, label, {run, validate, when, cancelOnNull, reviewLabel, summarize, includeInReview, editable})` - Runs your own synchronous step. Returning `null` cancels by default; set `cancelOnNull: false` to store `null` and continue.
- `component<T>(key, title, {component, validate, when, nullable, reviewLabel, summarize, includeInReview, editable})` - Runs a reusable `TerminiceComponent<T>` through the flow's configured Terminice instance. `nullable: true` stores `null` and continues; otherwise `null` cancels the flow.

Prompt and component steps are included in review and editable by default. Custom steps default to hidden from review and non-editable unless you opt in with `includeInReview: true` and `editable: true`.

#### Review Workflows

`.review(...)` displays collected review items and then asks the user to choose Submit, Edit, or Cancel.

- Submit - Returns a confirmed `FlowResult` with the current values.
- Edit - Opens a searchable list of editable review items. Choosing an item reruns the flow from that step.
- Cancel - Returns a cancelled `FlowResult`, keeps the collected values, and leaves `cancelledKey` as `null`.

When an edit reruns, values from the edited step onward are removed and collected again. Conditions are evaluated again too: newly enabled conditional steps run, and values from skipped conditional steps disappear. If the user cancels during the edit rerun, the pre-edit snapshot is restored and the review screen is shown again.

Review metadata lets each step control how it appears:

- `reviewLabel` - Replaces the prompt label in the summary.
- `summarize` - Converts the raw value into display text.
- `includeInReview` - Shows or hides the value in review.
- `editable` - Controls whether the value can be selected from the Edit list.

#### Result Access

`FlowResult` keeps collected values in insertion order and preserves partial answers when the flow is cancelled.

- `confirmed` - `true` when every applicable step completed.
- `cancelled` - `true` when a cancellable step stopped the flow.
- `cancelledKey` - Key of the step that cancelled, or `null`.
- `value<T>(key)` - Reads a required typed value and throws if the key is missing or has a different type.
- `maybe<T>(key)` - Reads a typed value, returning `null` when the key is absent or stored as `null`; wrong non-null types still throw.
- `string(key)` / `maybeString(key)` - Convenience helpers for string values.
- `flag(key)` / `maybeFlag(key)` - Convenience helpers for boolean values.
- `list<T>(key)` - Reads a typed `List<T>`.
- `valueOr<T>(key, fallback)` - Reads a typed value or returns `fallback` when the key is absent or stored as `null`.
- `contains(key)` - Checks whether a step wrote that key.
- `toMap()` - Returns an insertion-ordered copy of the collected values.

#### Context, Conditions, and Validation

`FlowContext` is passed to `when`, `validate`, `summarize`, and `custom` runners. It exposes the configured `terminice` instance, `runComponent(component)`, progress-aware `promptTitle(title)`, plain `fallbackPromptTitle(title)`, and the same typed result helpers for values collected by earlier steps.

Flow validators use `String? Function(value, context)`: return `null` for success, return `''` for legacy-compatible success, or return a non-empty error string to reject the step with a `FlowValidationException`.

For `text`, `validator` and `validate` are different layers. `validator` runs inside the prompt for immediate text-input feedback; `validate` runs after the step completes and can inspect earlier flow answers through `FlowContext`.

#### Examples

```dart
void projectDetails(FlowBuilder flow) {
  flow
      .text(
        'name',
        'Project name',
        required: true,
        reviewLabel: 'Project',
      )
      .select<String>(
        'template',
        'Template',
        options: ['CLI', 'Server', 'Package'],
        summarize: (value, _) => value ?? 'CLI',
      );
}

final result = terminice.flow('Create project')
    .progress()
    .include(projectDetails)
    .checkboxes<String>(
      'features',
      'Features',
      options: ['Git', 'CI', 'Docker'],
      summarize: (values, _) => values.isEmpty ? 'none' : values.join(', '),
    )
    .password(
      'token',
      'API token',
      includeInReview: false,
      allowReveal: false,
    )
    .confirm(
      'create',
      prompt: 'Create',
      message: 'Create project?',
      reviewLabel: 'Ready',
      summarize: (value, _) => value ? 'yes' : 'no',
    )
    .review(title: 'Review project')
    .run();

if (result.confirmed && result.flag('create')) {
  final name = result.string('name');
  final template = result.valueOr<String>('template', 'CLI');
  final features = result.list<String>('features');

  print('Creating $name from $template with ${features.join(', ')}');
}
```

```dart
final result = terminice.flow('Deployment')
  .select(
    'environment',
    'Environment',
    options: ['dev', 'staging', 'prod'],
    validate: (value, _) => value == null ? 'Choose an environment' : null,
  )
  .text(
    'changeId',
    'Change request',
    required: false,
    when: (context) => context.value<String>('environment') == 'prod',
    validate: (value, context) {
      final isProd = context.value<String>('environment') == 'prod';
      if (isProd && value.isEmpty) return 'Production needs a change ID';
      return null;
    },
  )
  .custom<DateTime>(
    'startedAt',
    'Start time',
    includeInReview: true,
    editable: false,
    summarize: (value, _) => value.toIso8601String(),
    run: (_) => DateTime.now(),
  )
  .review()
  .run();

if (result.cancelled) {
  final stoppedAt = result.cancelledKey;
  if (stoppedAt == null) {
    print('Review cancelled.');
  } else {
    print('Stopped at $stoppedAt.');
  }
}
```

> **Why use this?**
> Use `flow` when several prompt results belong to one command, later steps should react to earlier answers, or users should review and edit a full answer set before submission. Use individual prompts when each question stands alone, and use `form` when multiple text/password fields should render together in one frame.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `configEditor` - Searchable Nested Settings Editor

Build a full terminal settings screen from typed `Configurable` fields. The editor renders a searchable list, opens the right prompt for each value, supports nested groups, tracks modified fields, and returns a `ConfigResult` only when the root editor is saved.

```dart
ConfigResult? configEditor(
  String prompt, {
  required List<Configurable> fields,
  int maxVisible = 18,
});
```

- `configEditor(String prompt, {required fields, maxVisible = 18})` - Opens the editor with `prompt` as the frame title.
- `fields` - A mutable list of `Configurable` objects. The editor updates the field instances in place as the user edits values.
- `maxVisible` - Upper limit for visible rows. The actual viewport is also clamped to the terminal height.
- Returns `ConfigResult?` - Returns `ConfigResult(fields: fields, confirmed: true)` when the root "Save & confirm" row is selected, or `null` when the root editor is cancelled.
- Empty behavior - If `fields` is empty, the method returns an immediate confirmed `ConfigResult`.
- Search behavior - Search is active by default. Typing filters by field `label` or `key`; `/` toggles search on and off.
- Navigation behavior - `↑` / `↓` move through rows, `Enter` opens the focused field or group, and the first row is the root save action.
- Group behavior - `GroupConfigurable` opens a nested editor with a "Back" action instead of "Save & confirm". Esc or Back in a group returns to the parent and preserves edits in place; only the root save decides whether a result is returned.
- Theme behavior - A `ThemeConfigurable` at the current editor level updates the editor theme live after a new theme is selected. The editor also starts with that field's selected theme.
- Cancellation behavior - Esc / Ctrl+C at the root returns `null`. Field-level cancellation leaves the field's existing value unchanged; fields only update their value when their `edit(...)` method accepts a new value.
- Validation behavior - `Configurable.validate()` calls the field's validator, and `GroupConfigurable.validate()` checks children. The root save action does not currently run a full validation sweep automatically, so run validation yourself if you need a final gate.

#### `Configurable<T>` Basics

Every config field stores display metadata, a typed value, serialization hooks, and its own editor.

- `key` - Stable lookup and serialization key.
- `label` - Human-readable row label.
- `description` - Optional helper text shown under the focused row.
- `hint` - Optional metadata available to field implementations.
- `value` - Current typed value.
- `defaultValue` - Captured from the initial value and used for change detection.
- `formatter` - Optional display formatter. If omitted, the field's `formatValue()` is used.
- `validator` - Optional function that returns an error string or `null`. Returning `''` is also accepted as a legacy-compatible success value.
- `icon` - Optional glyph override. Otherwise each field uses its default type icon.
- `displayValue` - Formatted row value.
- `typeIcon` - Custom icon or field default.
- `edit(Terminice terminice)` - Opens the appropriate prompt and returns `true` when the field changes.
- `toJsonValue()` / `loadJsonValue(dynamic)` - Convert to and from JSON-compatible values.
- `isModified` - `true` when `value != defaultValue`; groups recurse into children.
- `reset()` - Restores the initial value; groups reset all children.
- `validate()` - Returns an error message or `null`.

#### `ConfigResult` Behavior

- `fields` - Final top-level fields, including groups.
- `confirmed` - Always `true` for values returned by `configEditor`; cancellation is represented by `null`.
- `toMap()` - Serializes top-level fields into `{key: value}`. Groups serialize as nested maps.
- `get<T>(String key)` - Looks up a top-level field value and casts it to `T`; nested group children are not searched recursively.
- `field(String key)` - Returns a top-level `Configurable`, or `null`.
- `hasChanges` - `true` if any top-level field is modified. Group fields report child changes.
- `modified` - Top-level fields whose values differ from their defaults.
- `loadFromMap(Map<String, dynamic> map)` - Loads matching top-level keys. Group fields load matching child keys from nested maps.

#### Common Configurable Types

- `BoolConfigurable` - Uses `confirm(...)`; stores a `bool`; displays `trueLabel` or `falseLabel`; serializes to `bool`. The confirm prompt is opened with the current value as `defaultYes`, so cancelling leaves the field unchanged.
- `StringConfigurable` - Uses `text(...)` or `multiline(...)`; stores a `String`; serializes to `String`. Single-line editing shows the current value as the placeholder when no explicit placeholder is set; multiline editing starts from an empty buffer.
- `PasswordConfigurable` - Uses `password(...)`; stores a `String`; masks the list display; serializes to `String`.
- `NumberConfigurable` - Uses `text(...)` with parsing or `slider(...)`; stores `num`; serializes to `int` when `integerOnly` is true.
- `EnumConfigurable` - Uses a focused searchable selector; stores a `String`; the initial value must be in `options`.
- `RangeConfigurable` - Uses `range(...)`; stores `RangeValue(start, end)`; serializes to `{'start': start, 'end': end}`.
- `RatingConfigurable` - Uses `rating(...)`; stores an `int`; supports optional labels.
- `ThemeConfigurable` - Uses a focused selector over `Map<String, PromptTheme>`; stores the selected theme key; default options come from `builtInThemes`.
- `GroupConfigurable` - Opens a nested editor; stores a computed map of child values; serializes children under the group key.

#### Factory Helper

Use `terminice.config` when you prefer compact field declarations. It returns a `ConfigFactory` with helpers that mirror the concrete configurable classes.

- `terminice.config` - Returns `const ConfigFactory()`.
- `boolean({required key, required label, value = false, description, hint, formatter, validator, icon, trueLabel = 'Yes', falseLabel = 'No'})`
- `string({required key, required label, value = '', description, hint, formatter, validator, icon, placeholder, multiline = false, required = false, visibleLines = 10})`
- `password({required key, required label, value = '', description, hint, formatter, validator, icon, maskChar = '•', allowReveal = true, required = false, verify = false})`
- `number({required key, required label, required value, description, hint, formatter, validator, icon, min = 0, max = 100, step = 1, unit = '', sliderWidth = 28, useSlider = false, showPercent = false, integerOnly = false})`
- `select({required key, required label, required value, required options, description, hint, formatter, validator, icon})`
- `range({required key, required label, required start, required end, description, hint, formatter, validator, icon, min = 0, max = 100, step = 1, unit = '%', width = 28})`
- `rating({required key, required label, value = 3, description, hint, formatter, validator, icon, maxStars = 5, labels})`
- `theme({required key, required label, value = 'dark', description, hint, formatter, validator, icon, themes, onChanged})`
- `group({required key, required label, required children, description, hint, icon})`

#### Examples

```dart
import 'dart:convert';

import 'package:terminice/terminice.dart';

void main() {
  final result = terminice.configEditor(
    'App Settings',
    fields: [
      ThemeConfigurable(
        key: 'theme',
        label: 'Theme',
        value: 'dark',
        description: 'Changes the editor palette live.',
      ),
      BoolConfigurable(
        key: 'telemetry',
        label: 'Telemetry',
        value: false,
        trueLabel: 'Enabled',
        falseLabel: 'Disabled',
      ),
      StringConfigurable(
        key: 'appName',
        label: 'App Name',
        value: 'terminice_app',
        required: true,
        placeholder: 'my_cli',
      ),
      NumberConfigurable(
        key: 'port',
        label: 'Port',
        value: 8080,
        min: 1,
        max: 65535,
        integerOnly: true,
      ),
      GroupConfigurable(
        key: 'security',
        label: 'Security',
        children: [
          PasswordConfigurable(
            key: 'apiKey',
            label: 'API Key',
            verify: true,
          ),
          EnumConfigurable(
            key: 'authMode',
            label: 'Auth Mode',
            value: 'token',
            options: ['token', 'oauth2', 'basic', 'none'],
          ),
        ],
      ),
    ],
  );

  if (result == null) {
    print('Cancelled.');
    return;
  }

  print('Changed: ${result.hasChanges}');
  print(const JsonEncoder.withIndent('  ').convert(result.toMap()));
}
```

```dart
import 'package:terminice/terminice.dart';

void main() {
  final c = terminice.config;

  final result = terminice.matrix.configEditor(
    'Release Preferences',
    fields: [
      c.theme(
        key: 'theme',
        label: 'Theme',
        value: 'matrix',
      ),
      c.string(
        key: 'releaseName',
        label: 'Release Name',
        value: 'v1.0.0',
        required: true,
      ),
      c.number(
        key: 'parallelJobs',
        label: 'Parallel Jobs',
        value: 4,
        min: 1,
        max: 16,
        useSlider: true,
        integerOnly: true,
      ),
      c.range(
        key: 'rollout',
        label: 'Rollout Window',
        start: 10,
        end: 50,
        unit: '%',
      ),
      c.rating(
        key: 'risk',
        label: 'Risk Level',
        value: 2,
        labels: ['Tiny', 'Low', 'Medium', 'High', 'Critical'],
      ),
    ],
  );

  final jobs = result?.get<num>('parallelJobs');
  if (jobs != null) {
    print('Running with ${jobs.toInt()} parallel jobs.');
  }
}
```

```dart
import 'package:terminice/terminice.dart';

void main() {
  final c = terminice.config;
  final fields = [
    c.string(key: 'host', label: 'Host', value: 'localhost'),
    c.number(
      key: 'port',
      label: 'Port',
      value: 8080,
      min: 1,
      max: 65535,
      integerOnly: true,
    ),
    c.group(
      key: 'proxy',
      label: 'Proxy',
      children: [
        c.boolean(key: 'enabled', label: 'Enabled'),
        c.string(key: 'url', label: 'URL'),
      ],
    ),
  ];

  final saved = <String, dynamic>{
    'host': 'api.example.com',
    'port': 443,
    'proxy': {
      'enabled': true,
      'url': 'http://proxy.example.com:3128',
    },
  };

  ConfigResult(fields: fields, confirmed: true).loadFromMap(saved);

  final result = terminice.configEditor(
    'Connection',
    fields: fields,
    maxVisible: 8,
  );

  if (result != null) {
    final connection = result.toMap();
    print(connection['proxy']);
  }
}
```

```dart
import 'package:terminice/terminice.dart';

void main() {
  final fields = [
    StringConfigurable(
      key: 'packageName',
      label: 'Package Name',
      required: true,
      validator: (value) {
        final ok = RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(value);
        return ok ? null : 'Use a valid Dart package name.';
      },
    ),
    NumberConfigurable(
      key: 'timeout',
      label: 'Timeout',
      value: 30,
      min: 1,
      max: 300,
      unit: 's',
      validator: (value) =>
          value < 10 ? 'Timeout should be at least 10 seconds.' : null,
    ),
  ];

  final result = terminice.configEditor('New Project', fields: fields);
  if (result == null) return;

  final errors = <String>[];
  for (final field in result.fields) {
    final error = field.validate();
    if (error != null) {
      errors.add('${field.label}: $error');
    }
  }

  if (errors.isNotEmpty) {
    for (final error in errors) {
      print(error);
    }
    return;
  }

  print('Config accepted.');
}
```

> **Why use this?**
> Use `configEditor` when a CLI needs a durable settings workflow with typed values, nested groups, live theme selection, and JSON-friendly output. Use individual prompts when you only need one or two answers.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `cheatSheet` - Framed Reference Table

Render a themed, non-interactive reference table inside a `FrameView`. It is designed for command lists, shortcut cards, option summaries, or any small table users may want to glance at while using a CLI.

```dart
void cheatSheet(
  String prompt, {
  required List<List<String>> entries,
  List<String> columns = const ['Command', 'Shortcut', 'Usage'],
  List<ColumnAlign>? columnAlignments,
  bool zebraStripes = true,
});
```

- `cheatSheet(String prompt, {required entries, columns, columnAlignments, zebraStripes = true})` - Renders the table immediately.
- `prompt` - Frame title displayed above the table.
- `entries` - Table rows. Every row must contain the same number of cells as `columns`.
- `columns` - Header labels. Defaults to `['Command', 'Shortcut', 'Usage']` and must not be empty.
- `columnAlignments` - Optional per-column alignment list using `ColumnAlign.left`, `ColumnAlign.center`, and `ColumnAlign.right`. When omitted, all columns are left-aligned.
- `zebraStripes` - When true, alternating rows are dimmed by the table renderer.
- Return behavior - Returns `void`; it renders once and does not wait for input.
- Assertion behavior - Asserts that `columns` is non-empty, every row matches the column count, and `columnAlignments` matches the column count when provided.
- Rendering behavior - Column widths are computed from the headers and entries, and cells are padded by alignment. There is no terminal-width wrapping in `cheatSheet`, so keep row text concise.
- Import note - Basic usage only needs `package:terminice/terminice.dart`. If you use `ColumnAlign` directly, import it from `package:terminice_core/terminice_core.dart`.

#### Examples

```dart
import 'package:terminice/terminice.dart';

void main() {
  terminice.cheatSheet(
    'Navigation Shortcuts',
    columns: const ['Command', 'Shortcut', 'Usage'],
    entries: const [
      ['List files', 'ls', 'Show directory contents'],
      ['Change directory', 'cd <path>', 'Move into a folder'],
      ['Print directory', 'pwd', 'Show the current path'],
    ],
  );
}
```

```dart
import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart' show ColumnAlign;

void main() {
  terminice.ocean.cheatSheet(
    'Deployment Matrix',
    columns: const ['Env', 'Region', 'Replicas', 'Status'],
    columnAlignments: const [
      ColumnAlign.left,
      ColumnAlign.center,
      ColumnAlign.right,
      ColumnAlign.left,
    ],
    entries: const [
      ['staging', 'us-east', '2', 'ready'],
      ['production', 'eu-west', '8', 'locked'],
      ['sandbox', 'local', '1', 'open'],
    ],
  );
}
```

```dart
final rows = <List<String>>[
  for (final command in ['build', 'test', 'publish'])
    [
      'terminice $command',
      command == 'publish' ? 'Ctrl+P' : 'Enter',
      'Run the $command task',
    ],
];

terminice.fire.cheatSheet(
  'CLI Commands',
  entries: rows,
  zebraStripes: false,
);
```

> **Why use this?**
> Use `cheatSheet` when the information is static and should stay compact. Use `helpCenter` when the user needs search, preview text, and a selected document result.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `helpCenter` - Searchable Help Browser

Launch an interactive help viewer with live search, a result list, and a preview pane. It returns the selected `HelpDoc`, which makes it useful for opening follow-up docs, routing to a tutorial, or tracking which help topic the user chose.

```dart
HelpDoc? helpCenter({
  String title = 'Help Center',
  required List<HelpDoc> docs,
  int maxVisibleResults = 10,
  int maxPreviewLines = 8,
});

const HelpDoc({
  required String id,
  required String title,
  required String content,
  String? category,
});
```

- `helpCenter`
  `({title = 'Help Center', required docs, maxVisibleResults = 10, maxPreviewLines = 8})`
  Opens the interactive viewer.
- `title` - Frame title.
- `docs` - Searchable document list. If empty, `helpCenter` returns `null` immediately.
- `maxVisibleResults` - Maximum visible rows in the result list.
- `maxPreviewLines` - Maximum lines shown in the preview pane.
- Returns `HelpDoc?` - The selected document on Enter, or `null` when cancelled or no document is selected.
- `HelpDoc.id` - Stable identifier for routing, analytics, or persistence.
- `HelpDoc.title` - Main result label.
- `HelpDoc.content` - Markdown or plaintext body shown in the preview pane. It is displayed as text; Markdown is not parsed into rich terminal formatting.
- `HelpDoc.category` - Optional grouping label appended to the result row.
- Search behavior - Typing filters by title, category, and content. Title matches are ranked before content-only matches.
- Controls - `↑` / `↓` move through results, `←` / `→` scroll the preview through content lines, `Enter` confirms, and Esc / Ctrl+C cancels.
- Preview behavior - The preview resets to the top when the selected result or search query changes.

#### Examples

```dart
import 'package:terminice/terminice.dart';

void main() {
  final doc = terminice.helpCenter(
    docs: const [
      HelpDoc(
        id: 'shortcuts',
        title: 'Keyboard shortcuts',
        category: 'Basics',
        content: 'Use arrow keys to move and Enter to confirm.',
      ),
      HelpDoc(
        id: 'config',
        title: 'Configuration files',
        category: 'Advanced',
        content: 'Store settings as JSON and load them before configEditor.',
      ),
    ],
  );

  if (doc != null) {
    print('Selected help topic: ${doc.id}');
  }
}
```

```dart
final docs = [
  const HelpDoc(
    id: 'deploy',
    title: 'Deploy a service',
    category: 'Workflows',
    content: '''
1. Build the project.
2. Run the smoke tests.
3. Publish the release artifact.
4. Promote the deployment.
''',
  ),
  const HelpDoc(
    id: 'rollback',
    title: 'Rollback safely',
    category: 'Workflows',
    content: '''
Use rollback when a deployment fails health checks.
Check logs before promoting the previous artifact.
''',
  ),
];

final selected = terminice.arcane.helpCenter(
  title: 'Operator Help',
  docs: docs,
  maxVisibleResults: 6,
  maxPreviewLines: 5,
);

switch (selected?.id) {
  case 'deploy':
    print('Opening deploy runbook...');
    break;
  case 'rollback':
    print('Opening rollback runbook...');
    break;
}
```

```dart
List<HelpDoc> commandDocs(Map<String, String> commands) {
  return [
    for (final entry in commands.entries)
      HelpDoc(
        id: entry.key,
        title: entry.key,
        category: 'Command',
        content: entry.value,
      ),
  ];
}

final chosen = terminice.helpCenter(
  title: 'Command Reference',
  docs: commandDocs({
    'init': 'Create a starter project in the current directory.',
    'doctor': 'Check whether the local environment is ready.',
    'publish': 'Upload the package after validation passes.',
  }),
);

print(chosen?.title ?? 'No topic selected.');
```

> **Why use this?**
> Use `helpCenter` when documentation needs search and a meaningful return value. Use `cheatSheet` when a simple static table is enough.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `hotkeyGuide` - Interactive Shortcut Guide

Show keyboard shortcuts in a compact framed grid and wait until the user closes it. This is a good companion for complex prompts, editors, command palettes, or any CLI mode with more than a few bindings.

```dart
void hotkeyGuide({
  required List<List<String>> shortcuts,
  String title = 'Hotkeys',
  List<String> footer = const ['Esc or ? to close'],
});
```

- `hotkeyGuide`
  `({required shortcuts, title = 'Hotkeys', footer = const ['Esc or ? to close']})`
  Renders the guide and blocks until a close key is pressed.
- `shortcuts` - Rows passed to `HintFormat.grid(...)`. Each row should use the same number of columns for clean alignment.
- `title` - Frame title.
- `footer` - Hint strings rendered after the grid using comma formatting. Pass an empty list to omit the footer.
- Return behavior - Returns `void`; it does not report which close key was used.
- Controls - Esc, Enter, or `?` closes the guide. Ctrl+C is also handled by the standard cancel binding.
- Rendering behavior - The guide uses the current `Terminice` theme and `HintFormat.grid` for aligned shortcut columns.
- Data shape - A two-column row usually works well for key/action pairs; three columns are useful when you want context or notes.

#### Examples

```dart
import 'package:terminice/terminice.dart';

void main() {
  terminice.hotkeyGuide(
    title: 'Selection Shortcuts',
    shortcuts: const [
      ['↑ / ↓', 'Move focus'],
      ['Space', 'Toggle item'],
      ['Enter', 'Confirm selection'],
      ['Esc', 'Cancel'],
    ],
  );
}
```

```dart
terminice.neon.hotkeyGuide(
  title: 'Editor Hotkeys',
  shortcuts: const [
    ['Ctrl+D', 'Save multiline input', 'Editor'],
    ['Ctrl+R', 'Reveal password', 'Password fields'],
    ['/', 'Toggle search', 'Lists'],
    ['?', 'Close this guide', 'Help'],
  ],
  footer: const ['Enter to close', 'Esc to close', '? to close'],
);
```

```dart
void showPromptHelp() {
  terminice.compact.hotkeyGuide(
    title: 'Prompt Controls',
    shortcuts: const [
      ['← / →', 'Adjust sliders or buttons'],
      ['↑ / ↓', 'Navigate lists'],
      ['Type', 'Filter searchable prompts'],
      ['Ctrl+C', 'Cancel current prompt'],
    ],
    footer: const [],
  );
}
```

> **Why use this?**
> Use `hotkeyGuide` when shortcuts are part of the workflow and users need an in-terminal reminder. Use `cheatSheet` for broader reference data that is not specifically about keys.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_

---

### `themeDemo` - Interactive Theme Gallery

Preview curated `PromptTheme` presets in the terminal, then optionally open a sample selector using the highlighted theme. The method is intentionally a demo utility: it does not return the selected theme, but it is handy for screenshots, onboarding, and choosing a palette before wiring a theme into your own CLI.

```dart
void themeDemo();
```

- `themeDemo()` - Opens the theme preview gallery.
- Themes shown - `Dark`, `Matrix`, `Fire`, `Pastel`, `Ocean`, `Monochrome`, `Neon`, `Arcane`, and `Phantom`.
- Preview content - Shows theme glyphs for arrows, checkboxes, borders, highlighted text, and inverse text.
- Controls - `↑` / `↓` browse themes, `Enter` accepts the highlighted theme and opens a sample `searchSelector`, and Esc / Ctrl+C exits without launching the sample prompt.
- Return behavior - Returns `void`; the chosen theme name is not returned to your code.
- Preview prompt behavior - Pressing Enter launches a multi-select `searchSelector` over sample fruit names using the selected theme.
- Theming note - The gallery uses its own curated theme map rather than the caller's `defaultTheme`, so `terminice.fire.themeDemo()` still starts from the built-in gallery.
- Selection note - If you need a user-selectable theme in a real settings flow, use `ThemeConfigurable` inside `configEditor` instead.

#### Examples

```dart
import 'package:terminice/terminice.dart';

void main() {
  terminice.themeDemo();
}
```

```dart
import 'package:terminice/terminice.dart';

void main() {
  terminice.themeDemo();

  final theme = terminice.searchSelector(
    prompt: 'Use which theme?',
    options: const [
      'dark',
      'matrix',
      'fire',
      'pastel',
      'ocean',
      'monochrome',
      'neon',
      'arcane',
      'phantom',
    ],
  );

  print('Theme choice: ${theme.isEmpty ? 'none' : theme.first}');
}
```

```dart
import 'package:terminice/terminice.dart';

void main() {
  final result = terminice.configEditor(
    'Theme Settings',
    fields: [
      ThemeConfigurable(
        key: 'theme',
        label: 'Theme',
        value: 'ocean',
        description: 'Pick a PromptTheme for the rest of the app.',
      ),
      BoolConfigurable(
        key: 'compactMode',
        label: 'Compact Mode',
        value: false,
      ),
    ],
  );

  print(result?.toMap() ?? 'cancelled');
}
```

> **Why use this?**
> Use `themeDemo` to inspect the visual language of Terminice themes quickly. Use `ThemeConfigurable` when your application needs to save the chosen theme.

_[⤴️ Back](#-the-terminice-catalogue) → The `terminice` Catalogue_
