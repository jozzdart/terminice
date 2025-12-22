import 'package:terminice/terminice.dart';

/// Fluent theme-aware builder that exposes every prompt as an extension method.
///
/// Create custom palettes with [themed] or grab one of the built-in presets:
/// `terminice.matrix`, `terminice.fire`, `terminice.arcane`, and more.
extension ThemeExtensions on Terminice {
  /// Terminice client pinned to [PromptTheme.dark].
  Terminice get dark => themed(PromptTheme.dark);

  /// Terminice client pinned to [PromptTheme.matrix].
  Terminice get matrix => themed(PromptTheme.matrix);

  /// Terminice client pinned to [PromptTheme.fire].
  Terminice get fire => themed(PromptTheme.fire);

  /// Terminice client pinned to [PromptTheme.pastel].
  Terminice get pastel => themed(PromptTheme.pastel);

  /// Terminice client pinned to [PromptTheme.ocean].
  Terminice get ocean => themed(PromptTheme.ocean);

  /// Terminice client pinned to [PromptTheme.monochrome].
  Terminice get monochrome => themed(PromptTheme.monochrome);

  /// Terminice client pinned to [PromptTheme.neon].
  Terminice get neon => themed(PromptTheme.neon);

  /// Terminice client pinned to [PromptTheme.arcane].
  Terminice get arcane => themed(PromptTheme.arcane);

  /// Terminice client pinned to [PromptTheme.phantom].
  Terminice get phantom => themed(PromptTheme.phantom);
}
