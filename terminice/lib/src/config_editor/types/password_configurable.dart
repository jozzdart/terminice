import 'package:terminice/terminice.dart';

/// A configurable password/secret field with masked display.
///
/// The list view shows the value as mask characters. When selected,
/// opens a password prompt with optional reveal toggle.
///
/// ```dart
/// PasswordConfigurable(
///   key: 'apiKey',
///   label: 'API Key',
///   value: '',
///   maskChar: '*',
/// )
/// ```
class PasswordConfigurable extends Configurable<String> {
  /// Character used to mask the value in both the list and the editor.
  final String maskChar;

  /// Whether the user can press Ctrl+R to reveal the password while editing.
  final bool allowReveal;

  /// Whether the field is required (non-empty).
  final bool required;

  PasswordConfigurable({
    required super.key,
    required super.label,
    super.value = '',
    super.description,
    super.hint,
    super.formatter,
    super.validator,
    this.maskChar = '•',
    this.allowReveal = true,
    this.required = false,
  });

  @override
  String get typeIcon => '●';

  @override
  String formatValue() {
    if (value.isEmpty) return '(not set)';
    final visibleLen = value.length.clamp(1, 12);
    return maskChar * visibleLen;
  }

  @override
  bool edit(Terminice terminice) {
    final result = terminice.password(
      prompt: label,
      maskChar: maskChar,
      allowReveal: allowReveal,
      required: required,
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
