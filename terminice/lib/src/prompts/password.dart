import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Password prompt with masking, optional reveal toggle, and theme-aware
/// status hints.
///
/// Controls:
/// - Type to enter characters (displayed as `maskChar`)
/// - Backspace deletes
/// - Enter confirms
/// - Esc cancels (returns `null`)
/// - Optional reveal hotkey (when `allowReveal` is `true`)
///
/// ```dart
/// final apiKey = terminice.password(
///   prompt: 'API key',
///   maskChar: '*',
///   allowReveal: false,
/// );
/// ```
extension PasswordPromptExtensions on Terminice {
  /// Password input prompt with masking options and a required flag.
  ///
  /// Returns the entered password, or `null` if canceled.
  ///
  /// **Example:**
  /// ```dart
  /// final secret = terminice.arcane.password(prompt: 'Vault passphrase');
  /// ```
  String? password({
    required String prompt,
    bool required = true,
    String maskChar = '•',
    bool allowReveal = true,
  }) {
    return TextPromptSync(
      title: prompt,
      theme: defaultTheme,
      required: required,
      masked: true,
      maskChar: maskChar,
      allowReveal: allowReveal,
    ).run();
  }
}
