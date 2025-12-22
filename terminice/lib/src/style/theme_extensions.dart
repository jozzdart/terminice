import 'package:terminice/terminice.dart';

/// Fluent theme-aware builder that exposes every prompt as an extension method.
///
/// Create custom palettes with [themed] or grab one of the built-in presets:
/// `terminice.matrix`, `terminice.fire`, `terminice.arcane`, and more.
///
/// **Display modes:**
/// - `terminice.minimal` - No borders, inline hints
/// - `terminice.compact` - Borders but no hints
/// - `terminice.verbose` - Full borders with grid hints
///
/// **Color themes:**
/// - `terminice.matrix`, `terminice.fire`, `terminice.ocean`, etc.
///
/// **Combination:**
/// ```dart
/// // Ocean colors with minimal display
/// terminice.ocean.withFeatures(DisplayFeatures.minimal)
/// ```
extension ThemeExtensions on Terminice {
  // ════════════════════════════════════════════════════════════════════════════
  // DISPLAY MODE PRESETS
  // ════════════════════════════════════════════════════════════════════════════

  /// Minimal display mode - no borders, inline hints.
  /// Uses current colors with minimal features.
  Terminice get minimal => themed(PromptTheme.minimal);

  /// Compact display mode - borders but no hints.
  Terminice get compact => themed(PromptTheme.compact);

  /// Verbose display mode - full borders with grid hints.
  Terminice get verbose => themed(defaultTheme.copyWith(
        features: DisplayFeatures.verbose,
      ));

  // ════════════════════════════════════════════════════════════════════════════
  // COLOR THEME PRESETS
  // ════════════════════════════════════════════════════════════════════════════

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

  // ════════════════════════════════════════════════════════════════════════════
  // COMPONENT CUSTOMIZATION
  // ════════════════════════════════════════════════════════════════════════════

  /// Returns a new client with custom colors, preserving glyphs and features.
  Terminice withColors(TerminalColors colors) {
    return themed(defaultTheme.copyWith(colors: colors));
  }

  /// Returns a new client with custom glyphs, preserving colors and features.
  Terminice withGlyphs(TerminalGlyphs glyphs) {
    return themed(defaultTheme.copyWith(glyphs: glyphs));
  }

  /// Returns a new client with custom display features, preserving colors and glyphs.
  Terminice withFeatures(DisplayFeatures features) {
    return themed(defaultTheme.copyWith(features: features));
  }
}
