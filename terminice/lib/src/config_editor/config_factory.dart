import 'package:terminice/terminice.dart';

/// Shorthand factory for creating [Configurable] fields.
///
/// Accessible via `terminice.config` or constructed directly:
///
/// ```dart
/// final c = terminice.config;
///
/// final fields = [
///   c.boolean(key: 'dark', label: 'Dark Mode', value: true),
///   c.string(key: 'name', label: 'Name', value: 'App'),
///   c.number(key: 'port', label: 'Port', value: 8080),
///   c.select(key: 'env', label: 'Env', value: 'dev', options: ['dev', 'prod']),
///   c.group(key: 'net', label: 'Network', children: [...]),
/// ];
/// ```
class ConfigFactory {
  const ConfigFactory();

  BoolConfigurable boolean({
    required String key,
    required String label,
    bool value = false,
    String? description,
    String? hint,
    String Function(bool)? formatter,
    String? Function(bool)? validator,
    String trueLabel = 'Yes',
    String falseLabel = 'No',
  }) =>
      BoolConfigurable(
        key: key,
        label: label,
        value: value,
        description: description,
        hint: hint,
        formatter: formatter,
        validator: validator,
        trueLabel: trueLabel,
        falseLabel: falseLabel,
      );

  StringConfigurable string({
    required String key,
    required String label,
    String value = '',
    String? description,
    String? hint,
    String Function(String)? formatter,
    String? Function(String)? validator,
    String? placeholder,
    bool multiline = false,
    bool required = false,
    int visibleLines = 10,
  }) =>
      StringConfigurable(
        key: key,
        label: label,
        value: value,
        description: description,
        hint: hint,
        formatter: formatter,
        validator: validator,
        placeholder: placeholder,
        multiline: multiline,
        required: required,
        visibleLines: visibleLines,
      );

  PasswordConfigurable password({
    required String key,
    required String label,
    String value = '',
    String? description,
    String? hint,
    String Function(String)? formatter,
    String? Function(String)? validator,
    String maskChar = '•',
    bool allowReveal = true,
    bool required = false,
  }) =>
      PasswordConfigurable(
        key: key,
        label: label,
        value: value,
        description: description,
        hint: hint,
        formatter: formatter,
        validator: validator,
        maskChar: maskChar,
        allowReveal: allowReveal,
        required: required,
      );

  NumberConfigurable number({
    required String key,
    required String label,
    required num value,
    String? description,
    String? hint,
    String Function(num)? formatter,
    String? Function(num)? validator,
    num min = 0,
    num max = 100,
    num step = 1,
    String unit = '',
    int sliderWidth = 28,
    bool useSlider = false,
    bool integerOnly = false,
  }) =>
      NumberConfigurable(
        key: key,
        label: label,
        value: value,
        description: description,
        hint: hint,
        formatter: formatter,
        validator: validator,
        min: min,
        max: max,
        step: step,
        unit: unit,
        sliderWidth: sliderWidth,
        useSlider: useSlider,
        integerOnly: integerOnly,
      );

  /// Creates an enum (fixed-option) configurable.
  ///
  /// Named `select` because `enum` is a Dart reserved word.
  EnumConfigurable select({
    required String key,
    required String label,
    required String value,
    required List<String> options,
    String? description,
    String? hint,
    String Function(String)? formatter,
    String? Function(String)? validator,
  }) =>
      EnumConfigurable(
        key: key,
        label: label,
        value: value,
        options: options,
        description: description,
        hint: hint,
        formatter: formatter,
        validator: validator,
      );

  RangeConfigurable range({
    required String key,
    required String label,
    required num start,
    required num end,
    String? description,
    String? hint,
    String Function(RangeValue)? formatter,
    String? Function(RangeValue)? validator,
    num min = 0,
    num max = 100,
    num step = 1,
    String unit = '%',
    int width = 28,
  }) =>
      RangeConfigurable(
        key: key,
        label: label,
        start: start,
        end: end,
        description: description,
        hint: hint,
        formatter: formatter,
        validator: validator,
        min: min,
        max: max,
        step: step,
        unit: unit,
        width: width,
      );

  RatingConfigurable rating({
    required String key,
    required String label,
    int value = 3,
    String? description,
    String? hint,
    String Function(int)? formatter,
    String? Function(int)? validator,
    int maxStars = 5,
    List<String>? labels,
  }) =>
      RatingConfigurable(
        key: key,
        label: label,
        value: value,
        description: description,
        hint: hint,
        formatter: formatter,
        validator: validator,
        maxStars: maxStars,
        labels: labels,
      );

  ThemeConfigurable theme({
    required String key,
    required String label,
    String value = 'dark',
    String? description,
    String? hint,
    String Function(String)? formatter,
    String? Function(String)? validator,
    Map<String, PromptTheme>? themes,
    void Function(PromptTheme)? onChanged,
  }) =>
      ThemeConfigurable(
        key: key,
        label: label,
        value: value,
        description: description,
        hint: hint,
        formatter: formatter,
        validator: validator,
        themes: themes,
        onChanged: onChanged,
      );

  GroupConfigurable group({
    required String key,
    required String label,
    required List<Configurable> children,
    String? description,
    String? hint,
  }) =>
      GroupConfigurable(
        key: key,
        label: label,
        children: children,
        description: description,
        hint: hint,
      );
}

/// Provides [config] as a shorthand factory for creating configurables.
///
/// ```dart
/// final c = terminice.config;
/// final fields = [
///   c.boolean(key: 'flag', label: 'Flag', value: true),
///   c.string(key: 'name', label: 'Name'),
/// ];
/// ```
extension ConfigFactoryExtension on Terminice {
  ConfigFactory get config => const ConfigFactory();
}
