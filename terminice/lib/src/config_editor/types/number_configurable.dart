import 'package:terminice/terminice.dart';

/// A configurable numeric field with optional slider mode.
///
/// When [useSlider] is `true`, opens a slider prompt bounded by
/// [min] and [max]. Otherwise opens a text input that parses
/// and validates the entered number.
///
/// ```dart
/// NumberConfigurable(
///   key: 'port',
///   label: 'Port',
///   value: 8080,
///   min: 1,
///   max: 65535,
/// )
///
/// NumberConfigurable(
///   key: 'volume',
///   label: 'Volume',
///   value: 50,
///   min: 0,
///   max: 100,
///   useSlider: true,
///   unit: '%',
/// )
/// ```
class NumberConfigurable extends Configurable<num> {
  /// The minimum allowed value.
  final num min;

  /// The maximum allowed value.
  final num max;

  /// The increment step size for the slider.
  final num step;

  /// Unit label shown alongside the slider (e.g. '%', 'GB', 'ms').
  final String unit;

  /// Width of the slider bar in characters.
  final int sliderWidth;

  /// When `true`, uses a slider prompt. Otherwise uses text input.
  final bool useSlider;

  /// When `true`, shows a percentage label on the slider bar.
  final bool showPercent;

  /// When `true`, restricts the value to integers.
  final bool integerOnly;

  /// Creates a number configurable field.
  ///
  /// The [key], [label], and [value] are required.
  /// Set [useSlider] to `true` to display a slider instead of a text input.
  NumberConfigurable({
    required super.key,
    required super.label,
    required super.value,
    super.validator,
    super.description,
    super.hint,
    super.formatter,
    super.icon,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.unit = '',
    this.sliderWidth = 28,
    this.useSlider = false,
    this.showPercent = false,
    this.integerOnly = false,
  });

  @override
  String get defaultTypeIcon => useSlider ? '═' : '#';

  @override
  String formatValue() {
    final display = integerOnly ? value.toInt().toString() : value.toString();
    return unit.isNotEmpty ? '$display$unit' : display;
  }

  @override
  bool edit(Terminice terminice) {
    if (useSlider) {
      return _editSlider(terminice);
    }
    return _editText(terminice);
  }

  bool _editSlider(Terminice terminice) {
    final result = terminice.slider(
      label,
      min: min,
      max: max,
      initial: value,
      step: step,
      width: sliderWidth,
      unit: unit,
      showPercent: showPercent,
    );
    if (result != value) {
      value = integerOnly ? result.toInt() : result;
      return true;
    }
    return false;
  }

  bool _editText(Terminice terminice) {
    final result = terminice.text(
      '$label ($min–$max)',
      placeholder: value.toString(),
      validator: (input) {
        final parsed = num.tryParse(input);
        if (parsed == null) return 'Enter a valid number';
        if (integerOnly && parsed != parsed.toInt()) {
          return 'Must be an integer';
        }
        if (parsed < min || parsed > max) {
          return 'Must be between $min and $max';
        }
        if (validator != null) return validator!(parsed) ?? '';
        return '';
      },
      required: true,
    );
    if (result != null) {
      final parsed = num.parse(result);
      value = integerOnly ? parsed.toInt() : parsed;
      return true;
    }
    return false;
  }

  @override
  dynamic toJsonValue() => integerOnly ? value.toInt() : value;

  @override
  void loadJsonValue(dynamic jsonValue) {
    if (jsonValue is num) {
      value = integerOnly ? jsonValue.toInt() : jsonValue;
    }
  }
}
