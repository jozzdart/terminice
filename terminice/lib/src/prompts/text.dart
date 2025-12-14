import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Text input prompt with placeholder support, inline validation, and clear
/// control hints that render cleanly on pub.dev.
///
/// Controls:
/// - Type to enter text
/// - Backspace to delete
/// - Enter to confirm
/// - Esc cancels (returns `null`)
///
/// ```dart
/// final name = terminice.text(
///   prompt: 'Display name',
///   placeholder: 'Ada Lovelace',
///   validator: (value) =>
///       value.trim().isEmpty ? 'Please enter something' : null,
/// );
/// ```
extension TextPromptExtensions on Terminice {
  /// Text input prompt with optional validation, placeholder text, and a
  /// required flag for quick enforcement.
  ///
  /// Returns the entered text, or `null` if the user cancels.
  ///
  /// **Example:**
  /// ```dart
  /// final handle = terminice.text(
  ///   prompt: 'Handle',
  ///   placeholder: '@terminice',
  ///   required: true,
  /// );
  /// ```
  String? text({
    required String prompt,
    String? placeholder,
    String Function(String)? validator,
    bool required = true,
  }) {
    return TextPromptSync(
      title: prompt,
      theme: defaultTheme,
      placeholder: placeholder,
      validator: validator,
      required: required,
    ).run();
  }
}
