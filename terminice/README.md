# terminice

[![Pub Version](https://img.shields.io/pub/v/terminice.svg)](https://pub.dev/packages/terminice)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](../LICENSE)

## Install

Add `terminice` to your `pubspec.yaml`:

```yaml
dependencies:
  terminice: ^0.0.2
```

Import the package and keep a single global instance around:

```dart
import 'package:terminice/terminice.dart';

void main() {
  final name = terminice.text(prompt: 'Display name');
  final confirmed = terminice.confirm(
    label: 'Deploy build',
    message: 'Ship the current release to production?',
  );
  if (confirmed == true) {
    deploy(name);
  }
}
```

## Prompt catalog

Each prompt ships with a synchronous `run()` implementation and detailed dartdoc that renders into the official docs. Highlights:

### Text prompt

- Placeholder text, optional validation, and `required` flag.
- Returns `String?` so `null` indicates cancellation.

```dart
final title = terminice.text(
  prompt: 'Project title',
  placeholder: 'terminice',
  validator: (value) =>
      value.trim().isEmpty ? 'Please enter a value' : null,
);
```

### Password prompt

- Masked characters with configurable glyphs and optional reveal toggle.
- Built on the same validation/required plumbing as the text prompt.

```dart
final secret = terminice.arcane.password(
  prompt: 'Vault passphrase',
  allowReveal: false,
);
```

### Confirm prompt

- Accessible buttons with keyboard hints (`Left/Right`, `Enter`, `Esc`).
- Customize the yes/no labels and default focus state.

```dart
final shouldDelete = terminice.confirm(
  label: 'Delete branch',
  message: 'Remove feature/login from origin?',
  yesLabel: 'Delete',
  noLabel: 'Keep',
);
```

### Multiline editor

- Pseudo text area with scrolling viewport, cursor highlighting, and `Ctrl+D` submit.
- Fluent theming via `terminice.matrix.multiline(...)` or `.themed(customTheme)`.

```dart
final notes = terminice.multiline(
  label: 'Release notes',
  visibleLines: 8,
);
```

### Slider & range prompts

- Continuous slider for numeric values and a dual-handle range selector for `(start, end)` tuples.
- Handles window resizing and renders labeled bars with the active caret.

```dart
final ratio = terminice.slider('CPU share', min: 0, max: 200, step: 5);
final (from, to) = terminice.range('Quiet hours', startInitial: 22, endInitial: 6);
```

### Rating prompt

- Star-based discrete selector with optional label overrides (`['Meh', 'Okay', ...]`).
- Users can type numbers or use horizontal navigation to pick a value.

```dart
final rating = terminice.rating(
  'Satisfaction',
  labels: ['Nope', 'Meh', 'Okay', 'Great', 'Amazing'],
);
```

## Theming cheat sheet

`terminice` is just a thin facade over `PromptTheme`. Use the fluent getters to swap palettes:

```dart
terminice.dark.text(prompt: 'Default theme');
terminice.matrix.slider('Matrix slider');
terminice.arcane.password(prompt: 'Spell word');
```

Need something bespoke? Create your own theme in `terminice_core` and feed it through `.themed()`:

```dart
final cyber = terminice.themed(
  PromptTheme.dark.copyWith(accent: '[38;5;199m'),
);
cyber.rating('Cyber rating');
```

## Relationship with `terminice_core`

- `terminice` focuses on end-user prompts and tiny ergonomic helpers.
- `terminice_core` exposes the underlying navigation, rendering, IO, and selection primitives.
- When you outgrow the stock prompts, import `terminice_core` directly and compose `PromptRunner`, `FrameView`, `KeyBindings`, and the navigators yourself.

Check the [`terminice_core` README](../terminice_core/README.md) for a deep dive into those internals.

## License

MIT ? terminice contributors
