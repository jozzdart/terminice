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
- **Progress indicators** — Loading spinners, inline spinners, progress bars, inline progress bars, and progress dots, all theme-integrated.
- **Zero boilerplate** — One import, one global instance, chainable theme accessors. No setup, no context objects, no widget trees.
- **Cross-platform** — Works on Linux, macOS, and Windows. Backed by a testable terminal abstraction you can swap for custom I/O.
- **Modular architecture** — Built on `terminice_core`, which exposes navigation primitives, prompt scaffolds, and rendering utilities for when you need full control.

#### Table of Contents

- [**Features**](#features)
- [**Quick Start**](#-quick-start)
- [**How to use `terminice`**](#-how-to-use-terminice)
- [**The Terminice Catalogue**](#-the-terminice-catalogue)
- [**Theming & Display Modes**](#-theming--display-modes)

### 🚀 Quick Start

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

### 📖 How to use `terminice`

`terminice` is designed to be as frictionless as possible. There are no widget trees, no state management classes, and no complex setup.

#### The Global Instance

Everything starts with the global `terminice` instance. All prompts, selectors, and indicators are exposed as extension methods on this single object.

```dart
import 'package:terminice/terminice.dart';

void main() {
  // Use the global instance directly
  terminice.text('What is your name?');
}
```

#### Synchronous Execution

Unlike many Dart libraries, **`terminice` is fully synchronous**. You do not need to `await` any prompt. When you call a method, it blocks execution until the user provides input or cancels, returning the result directly.

```dart
// No async/await required!
final name = terminice.text('Name');
final age = terminice.slider('Age', min: 0, max: 100);

print('Hello $name, you are $age years old.');
```

_(Note: Indicators like `loadingSpinner` return an object that you control asynchronously, but user-input prompts are synchronous)._

#### Shared API Design

Most tools in the library share a consistent set of parameters to keep the API predictable:

- `prompt` or `label`: The main text displayed to the user.
- `initial` or `defaultValue`: The starting value or selection.
- `required`: (On text/password prompts) Prevents the user from submitting an empty value.
- `validator`: A function that returns a `String?` error message if the input is invalid.

#### Validation

Validating input is built directly into the prompts. Simply provide a `validator` function that returns a `String` error message if the input is invalid, or `null` if it passes.

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

For a complete list of available tools, check out [**The Terminice Catalogue**](#-the-terminice-catalogue) below.

### 📚 The `terminice` Catalogue

Explore the complete collection of tools available in `terminice`. Every tool is fully themeable and ready to use with zero setup.

#### 📝 Prompts

Standard input controls for gathering user data.

- `text` — Single-line text input.
- `password` — Secure, masked text input.
- `confirm` — Yes/No boolean confirmation.
- `multiline` — Multi-line text editor.
- `slider` — Numeric selection along a single axis.
- `range` — Dual-thumb slider for selecting a min/max range.
- `rating` — Star-based rating input.
- `date` — Simple date text entry.
- `form` — Group multiple prompts into a single cohesive form.

#### 🎯 Selectors

Interactive menus for choosing from predefined options.

- `searchSelector` — Filterable list of options.
- `choiceSelector` — Simple single-choice list.
- `checkboxSelector` — Multi-select list with checkboxes.
- `gridSelector` — 2D grid selection.
- `tagSelector` — Select and manage multiple tags.
- `toggleGroup` — Segmented control for mutually exclusive options.
- `commandPalette` — Global command launcher with fuzzy search.

#### 🗂️ Pickers

Specialized components for selecting complex data types.

- `filePicker` — Browse and select files from the filesystem.
- `pathPicker` — Browse and select directories.
- `colorPicker` — Interactive color selection.
- `datePicker` — Calendar-based date selection.

#### ⏳ Indicators

Visual feedback for long-running tasks.

- `loadingSpinner` — Full-featured loading animation.
- `inlineSpinner` — Compact loading animation for inline use.
- `progressBar` — Standard progress bar with percentage.
- `inlineProgressBar` — Compact progress bar.
- `progressDots` — Minimalist dot-based progress indicator.

#### ⚙️ Configuration & Utilities

Advanced tools for building full CLI applications.

- `configEditor` — A searchable, nested settings editor for complex configurations.
- `cheatSheet` — Display a quick reference guide.
- `helpCenter` — Interactive help documentation viewer.
- `hotkeyGuide` — Display available keyboard shortcuts.
- `themeDemo` — Showcase all available themes and colors.

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

#### ⌨ Example

```dart
// Combine theme and display mode
final name = terminice.ocean.compact.text('Name');

// Store a themed instance for consistency
final t = terminice.fire.minimal;
final age = t.text('Age');
final role = t.searchSelector(prompt: 'Role', options: ['Admin', 'User']);
```
