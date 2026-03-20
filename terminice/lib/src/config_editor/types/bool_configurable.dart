import 'package:terminice/terminice.dart';

/// A configurable boolean field rendered as a confirm prompt.
///
/// In the editor list, shows the current state as `true` / `false`.
/// When selected, opens a yes/no confirm prompt to toggle the value.
///
/// ```dart
/// BoolConfigurable(
///   key: 'darkMode',
///   label: 'Dark Mode',
///   value: true,
/// )
/// ```
class BoolConfigurable extends Configurable<bool> {
  /// Label shown for the "true" option in the confirm prompt.
  final String trueLabel;

  /// Label shown for the "false" option in the confirm prompt.
  final String falseLabel;

  BoolConfigurable({
    required super.key,
    required super.label,
    super.value = false,
    super.description,
    super.hint,
    super.formatter,
    super.validator,
    this.trueLabel = 'Yes',
    this.falseLabel = 'No',
  });

  @override
  String get typeIcon => '◉';

  @override
  String formatValue() => value ? trueLabel : falseLabel;

  @override
  bool edit(Terminice terminice) {
    final result = terminice.confirm(
      label: label,
      message: description ?? 'Toggle $label',
      yesLabel: trueLabel,
      noLabel: falseLabel,
      defaultYes: value,
    );
    if (result != value) {
      value = result;
      return true;
    }
    return false;
  }

  @override
  dynamic toJsonValue() => value;

  @override
  void loadJsonValue(dynamic jsonValue) {
    if (jsonValue is bool) value = jsonValue;
  }
}
