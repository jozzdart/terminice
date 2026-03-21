import 'package:terminice/terminice.dart';

import '../focused_select.dart';

/// A configurable field that selects from a fixed set of string options.
///
/// Opens a searchable list selector when edited, allowing the user to
/// pick from the available [options]. The cursor starts on the currently
/// selected value.
///
/// ```dart
/// EnumConfigurable(
///   key: 'theme',
///   label: 'Theme',
///   value: 'dark',
///   options: ['dark', 'light', 'auto'],
/// )
/// ```
class EnumConfigurable extends Configurable<String> {
  /// The allowed values to choose from.
  final List<String> options;

  EnumConfigurable({
    required super.key,
    required super.label,
    required String value,
    required this.options,
    super.description,
    super.hint,
    super.formatter,
    super.validator,
    super.icon,
  }) : super(value: value) {
    assert(options.contains(value), 'Initial value must be in options');
  }

  @override
  String get defaultTypeIcon => '▾';

  @override
  bool edit(Terminice terminice) {
    final selected = focusedSelect(
      theme: terminice.defaultTheme,
      options: options,
      title: label,
      initialIndex: options.indexOf(value).clamp(0, options.length - 1),
      showSearch: options.length > 5,
      maxVisible: 10,
    );
    if (selected == null || selected == value) return false;
    if (validator != null) {
      final error = validator!(selected);
      if (error != null) return false;
    }
    value = selected;
    return true;
  }

  @override
  dynamic toJsonValue() => value;

  @override
  void loadJsonValue(dynamic jsonValue) {
    if (jsonValue is String && options.contains(jsonValue)) {
      value = jsonValue;
    }
  }
}
