import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Multi-field text input form rendered inside a single themed frame.
///
/// Each field gets its own label, optional placeholder, masking, and
/// validation. Navigate between fields with Tab/↑/↓, submit with Enter
/// on the last field, cancel with Esc.
///
/// ```dart
/// final result = terminice.form(
///   'Login',
///   fields: [
///     FormFieldConfig(label: 'Username', required: true),
///     FormFieldConfig(label: 'Password', masked: true, required: true),
///   ],
/// );
/// if (result != null) {
///   print('User: ${result[0]}, Pass: ${result[1]}');
/// }
/// ```
///
/// Use [crossValidator] for multi-field validation:
/// ```dart
/// final result = terminice.form(
///   'New Password',
///   fields: [
///     FormFieldConfig(label: 'Password', masked: true, required: true),
///     FormFieldConfig(label: 'Confirm', masked: true, required: true),
///   ],
///   crossValidator: (v) =>
///     v[0] != v[1] ? 'Passwords do not match' : null,
/// );
/// ```
extension FormPromptExtensions on Terminice {
  /// Runs a multi-field text input form.
  ///
  /// Returns a [FormResult] on confirmation, or `null` if cancelled.
  /// Access field values by index: `result[0]`, `result[1]`, etc.
  FormResult? form(
    String prompt, {
    required List<FormFieldConfig> fields,
    String? Function(List<String> values)? crossValidator,
  }) {
    return FormPrompt(
      title: prompt,
      theme: defaultTheme,
      fields: fields,
      crossValidator: crossValidator,
    ).run();
  }
}
