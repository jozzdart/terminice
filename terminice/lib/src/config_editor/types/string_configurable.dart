import 'package:terminice/terminice.dart';

/// A configurable string field using a text or multiline prompt.
///
/// When [multiline] is `true`, opens a multiline text area editor.
/// Otherwise uses a single-line text input with optional placeholder
/// and validation.
///
/// ```dart
/// StringConfigurable(
///   key: 'appName',
///   label: 'App Name',
///   value: 'My App',
///   placeholder: 'Enter name...',
///   validator: (v) => v.trim().isEmpty ? 'Required' : null,
/// )
/// ```
class StringConfigurable extends Configurable<String> {
  /// Placeholder text shown when the input is empty.
  final String? placeholder;

  /// When `true`, uses the multiline editor instead of single-line text.
  final bool multiline;

  /// Whether the field is required (non-empty).
  final bool required;

  /// Maximum visible lines for the multiline editor.
  final int visibleLines;

  StringConfigurable({
    required super.key,
    required super.label,
    super.value = '',
    super.description,
    super.hint,
    super.formatter,
    super.validator,
    super.icon,
    this.placeholder,
    this.multiline = false,
    this.required = false,
    this.visibleLines = 10,
  });

  @override
  String get defaultTypeIcon => multiline ? '≡' : '✎';

  @override
  String formatValue() {
    if (value.isEmpty) return '(empty)';
    if (multiline && value.contains('\n')) {
      final lineCount = value.split('\n').length;
      final firstLine = value.split('\n').first;
      final preview =
          firstLine.length > 30 ? '${firstLine.substring(0, 30)}…' : firstLine;
      return '$preview (+${lineCount - 1} lines)';
    }
    return value.length > 40 ? '${value.substring(0, 40)}…' : value;
  }

  @override
  bool edit(Terminice terminice) {
    if (multiline) {
      return _editMultiline(terminice);
    }
    return _editSingleLine(terminice);
  }

  bool _editSingleLine(Terminice terminice) {
    final result = terminice.text(
      label,
      placeholder: placeholder ?? value,
      validator: validator != null ? (v) => validator!(v) ?? '' : null,
      required: required,
    );
    if (result != null) {
      value = result;
      return true;
    }
    return false;
  }

  bool _editMultiline(Terminice terminice) {
    final result = terminice.multiline(
      label,
      visibleLines: visibleLines,
      allowEmpty: !required,
    );
    if (result != null) {
      value = result;
      return true;
    }
    return false;
  }

  @override
  dynamic toJsonValue() => value;

  @override
  void loadJsonValue(dynamic jsonValue) {
    if (jsonValue is String) value = jsonValue;
  }
}
