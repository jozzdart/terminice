import 'package:terminice_core/terminice_core.dart';

/// Global entry point for the default Terminice client using
/// [PromptTheme.dark].
final Terminice terminice = Terminice();

/// Fluent theme-aware builder that exposes every prompt as an extension method.
///
/// Create custom palettes with [themed] or grab one of the built-in presets:
/// `terminice.matrix`, `terminice.fire`, `terminice.arcane`, and more.
class Terminice {
  /// Theme that will be forwarded to every prompt invocation.
  final PromptTheme defaultTheme;

  /// Creates a new Terminice client configured with [defaultTheme].
  const Terminice({
    this.defaultTheme = PromptTheme.dark,
  });

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

  /// Returns a new client using the provided [theme].
  Terminice themed(PromptTheme theme) {
    return Terminice(defaultTheme: theme);
  }
}
