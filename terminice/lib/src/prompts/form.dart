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
  /// - [prompt] is the title of the form.
  /// - [fields] is a list of [FormFieldConfig] objects defining the inputs.
  /// - [crossValidator] is an optional function to validate the entire form state.
  ///
  /// Returns a [FormResult] on confirmation, or `null` if cancelled.
  /// Access field values by index: `result[0]`, `result[1]`, etc.
  ///
  /// **Example:**
  /// ```dart
  /// final result = terminice.form(
  ///   'Login',
  ///   fields: [
  ///     FormFieldConfig(label: 'Username', required: true),
  ///     FormFieldConfig(label: 'Password', masked: true, required: true),
  ///   ],
  /// );
  /// ```
  FormResult? form(
    String prompt, {
    required List<FormFieldConfig> fields,
    String? Function(List<String> values)? crossValidator,
  }) {
    return runWithExecutionMode<FormResult?>(
      rich: () => FormPrompt(
        title: prompt,
        theme: defaultTheme,
        fields: fields,
        crossValidator: crossValidator,
      ).run(),
      line: () => _fallbackForm(
        fields,
        crossValidator: crossValidator,
      ),
      unattended: () => _unattendedForm(fields, crossValidator),
    );
  }
}

FormResult? _unattendedForm(
  List<FormFieldConfig> fields,
  String? Function(List<String> values)? crossValidator,
) {
  final values = <String>[];
  for (final field in fields) {
    final value = field.initialValue ?? '';
    if (field.required && value.isEmpty) return null;
    final error = field.validator?.call(value);
    if (error != null && error.isNotEmpty) return null;
    values.add(value);
  }
  final error = crossValidator?.call(values);
  return error == null || error.isEmpty ? FormResult(values) : null;
}

FormResult? _fallbackForm(
  List<FormFieldConfig> fields, {
  String? Function(List<String> values)? crossValidator,
}) {
  final result = FallbackPrompt.form(
    fields: fields.map(_toFallbackField).toList(),
    crossValidator: crossValidator,
    returnDefaultOnEndOfInput: false,
  );
  return result == null ? null : FormResult(result.values);
}

FallbackFormField _toFallbackField(FormFieldConfig field) {
  return FallbackFormField(
    label: field.label,
    placeholder: field.placeholder,
    masked: field.masked,
    maskChar: field.maskChar,
    allowReveal: field.allowReveal,
    required: field.required,
    validator: field.validator,
    initialValue: field.initialValue,
  );
}
