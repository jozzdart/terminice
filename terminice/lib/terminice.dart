/// **terminice** gives you **30+ ready-to-use terminal components**—from simple
/// prompts to complex searchable menus and config editors.
///
/// **Universal theming out of the box.** Every single prompt, selector, picker,
/// and indicator automatically adapts to your chosen theme. Pick from **11 built-in themes**
/// or customize your own via a fluent API.
///
/// **Zero boilerplate.** No widget trees or manual state management. Just call a method
/// and get a polished, keyboard-driven UI instantly.
///
/// ### Quick Start
///
/// Everything starts with the global `terminice` instance. All prompts, selectors,
/// and indicators are exposed as extension methods on this single object.
///
/// ```dart
/// import 'package:terminice/terminice.dart';
///
/// void main() {
///   // Use the global instance directly
///   final name = terminice.text('What is your name?');
///   
///   // Chain a theme and a display mode directly
///   final choice = terminice.ocean.compact.confirm(message: 'Save changes?');
/// }
/// ```
library terminice;

export 'src/src.dart';
