# terminice

**terminice** is a production-grade Dart library for building beautiful, interactive command-line interfaces with zero boilerplate. Unlike other CLI prompt packages that require verbose configuration or complex state management, terminice provides a fluent, highly ergonomic API that makes gathering user input—from simple text and passwords to complex multiline editors and sliders—effortless. It ships with a rich catalog of built-in prompts, out-of-the-box theming, and a modular architecture that lets you easily drop down to its core primitives when you need complete control.

<p align="center">
  <img src="assets/showcase.gif" alt="terminice interactive showcase" width="1000"/>
</p>

```dart
import 'package:terminice/terminice.dart';

void main() {
  // 1. Text prompt with default theme
  final name = terminice.text(prompt: 'Project name');

  // 2. Password prompt with Arcane theme
  final secret = terminice.arcane.password(prompt: 'Vault passphrase', maskChar: '✦');

  // 3. Slider with Ocean theme
  final memory = terminice.ocean.slider('Memory allocation', min: 128, max: 2048, step: 128);

  // 4. Searchable list with Fire theme
  final language = terminice.fire.searchSelector(
    prompt: 'Primary language',
    options: ['Dart', 'Go', 'Rust', 'TypeScript', 'Python'],
    showSearch: true,
  );

  // 5. Multiline editor with Matrix theme
  final notes = terminice.matrix.multiline(label: 'Release notes (Ctrl+D to save)');

  // 6. Confirm with Neon theme
  final confirmed = terminice.neon.confirm(message: 'Ship $name to production?');
}
```
