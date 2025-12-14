import 'prompt_theme.dart';

/// Opt-in mixin for components that expose a configurable [PromptTheme].
///
/// Applying `Themeable` keeps theming consistent across prompts without forcing
/// each widget to hand-roll builder helpers or copyWith boilerplate.
///
/// ### Usage
/// 1. Add `with Themeable` to your component class.
/// 2. Store the active [PromptTheme] (defaulting to `PromptTheme.dark`).
/// 3. Implement [copyWithTheme] so the builder helpers can produce variants.
///
/// ```dart
/// class MyView with Themeable {
///   final String label;
///   @override
///   final PromptTheme theme;
///
///   const MyView(this.label, {this.theme = PromptTheme.dark});
///
///   @override
///   MyView copyWithTheme(PromptTheme theme) {
///     return MyView(label, theme: theme);
///   }
/// }
///
/// // Builder helpers come from ThemeableBuilder below.
/// final matrixView = const MyView('Test').withMatrixTheme();
/// ```
mixin Themeable {
  /// The current theme for styling.
  PromptTheme get theme;

  /// Creates a copy with a different theme.
  Themeable copyWithTheme(PromptTheme theme);
}

/// Fluent builder extensions for [Themeable] components.
///
/// Each helper returns a cloned instance with the requested preset, keeping
/// your APIs tidy and ergonomic for downstream packages.
extension ThemeableBuilder<T extends Themeable> on T {
  /// Creates a copy with a custom theme.
  T withTheme(PromptTheme theme) {
    return copyWithTheme(theme) as T;
  }

  /// Creates a copy with the dark theme (default).
  T withDarkTheme() => withTheme(PromptTheme.dark);

  /// Creates a copy with the matrix theme (green, terminal-style).
  T withMatrixTheme() => withTheme(PromptTheme.matrix);

  /// Creates a copy with the fire theme (red/orange, bold).
  T withFireTheme() => withTheme(PromptTheme.fire);

  /// Creates a copy with the pastel theme (soft, gentle colors).
  T withPastelTheme() => withTheme(PromptTheme.pastel);

  /// Creates a copy with the ocean theme (calming blue/cyan).
  T withOceanTheme() => withTheme(PromptTheme.ocean);

  /// Creates a copy with the monochrome theme (high-contrast ASCII).
  T withMonochromeTheme() => withTheme(PromptTheme.monochrome);

  /// Creates a copy with the neon theme (vibrant synthwave).
  T withNeonTheme() => withTheme(PromptTheme.neon);

  /// Creates a copy with the arcane theme (mystical ancient tome).
  T withArcaneTheme() => withTheme(PromptTheme.arcane);

  /// Creates a copy with the phantom theme (ghostly apparition).
  T withPhantomTheme() => withTheme(PromptTheme.phantom);
}
