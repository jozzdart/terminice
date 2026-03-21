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
/// When [verify] is `true`, a second "Verify password" field is shown
/// alongside the main field inside a single frame. Both must match to
/// confirm.
///
/// ```dart
/// final apiKey = terminice.password(
///   'API key',
///   maskChar: '*',
///   allowReveal: false,
/// );
///
/// final secret = terminice.password(
///   'New password',
///   verify: true,
/// );
/// ```
extension PasswordPromptExtensions on Terminice {
  /// Password input prompt with masking options and a required flag.
  ///
  /// - [prompt] is the main text displayed to the user.
  /// - [required] ensures the user cannot submit an empty string (defaults to `true`).
  /// - [maskChar] is the character used to hide the input (defaults to '•').
  /// - [allowReveal] allows the user to toggle visibility using a hotkey (defaults to `true`).
  /// - [verify] when `true`, shows a second confirmation field.
  ///
  /// Returns the entered password, or `null` if canceled.
  ///
  /// When [verify] is `true`, a second confirmation field is shown.
  /// The user must enter the same password in both fields to confirm.
  String? password(
    String prompt, {
    bool required = true,
    String maskChar = '•',
    bool allowReveal = true,
    bool verify = false,
  }) {
    if (!verify) {
      return TextPromptSync(
        title: prompt,
        theme: defaultTheme,
        required: required,
        masked: true,
        maskChar: maskChar,
        allowReveal: allowReveal,
      ).run();
    }

    final result = FormPrompt(
      title: prompt,
      theme: defaultTheme,
      fields: [
        FormFieldConfig(
          label: 'Password',
          masked: true,
          maskChar: maskChar,
          allowReveal: allowReveal,
          required: required,
        ),
        FormFieldConfig(
          label: 'Verify password',
          masked: true,
          maskChar: maskChar,
          allowReveal: allowReveal,
          required: required,
          placeholder: 're-enter to confirm',
        ),
      ],
      crossValidator: (values) =>
          values[0] != values[1] ? 'Passwords do not match' : null,
    ).run();

    return result?[0];
  }
}
