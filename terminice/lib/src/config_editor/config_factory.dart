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
  /// Creates a new [ConfigFactory] instance.
  const ConfigFactory();

  /// Creates a boolean configurable field.
  ///
  /// The [key] and [label] are required. The [value] defaults to `false`.
  /// The [trueLabel] and [falseLabel] customize the confirm prompt options.
  BoolConfigurable boolean({
    required String key,
    required String label,
    bool value = false,
    String? description,
    String? hint,
    String Function(bool)? formatter,
    String? Function(bool)? validator,
    String? icon,
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
        icon: icon,
        trueLabel: trueLabel,
        falseLabel: falseLabel,
      );

  /// Creates a string configurable field.
  ///
  /// The [key] and [label] are required. The [value] defaults to an empty string.
  /// If [multiline] is `true`, a multiline text editor is used.
  StringConfigurable string({
    required String key,
    required String label,
    String value = '',
    String? description,
    String? hint,
    String Function(String)? formatter,
    String? Function(String)? validator,
    String? icon,
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
        icon: icon,
        placeholder: placeholder,
        multiline: multiline,
        required: required,
        visibleLines: visibleLines,
      );

  /// Creates a password configurable field.
  ///
  /// The [key] and [label] are required. The [value] defaults to an empty string.
  /// The [maskChar] is used to hide the input.
  PasswordConfigurable password({
    required String key,
    required String label,
    String value = '',
    String? description,
    String? hint,
    String Function(String)? formatter,
    String? Function(String)? validator,
    String? icon,
    String maskChar = '•',
    bool allowReveal = true,
    bool required = false,
    bool verify = false,
  }) =>
      PasswordConfigurable(
        key: key,
        label: label,
        value: value,
        description: description,
        hint: hint,
        formatter: formatter,
        validator: validator,
        icon: icon,
        maskChar: maskChar,
        allowReveal: allowReveal,
        required: required,
        verify: verify,
      );

  /// Creates a number configurable field.
  ///
  /// The [key], [label], and [value] are required.
  /// Set [useSlider] to `true` to display a slider instead of a text input.
  NumberConfigurable number({
    required String key,
    required String label,
    required num value,
    String? description,
    String? hint,
    String Function(num)? formatter,
    String? Function(num)? validator,
    String? icon,
    num min = 0,
    num max = 100,
    num step = 1,
    String unit = '',
    int sliderWidth = 28,
    bool useSlider = false,
    bool showPercent = false,
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
        icon: icon,
        min: min,
        max: max,
        step: step,
        unit: unit,
        sliderWidth: sliderWidth,
        useSlider: useSlider,
        showPercent: showPercent,
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
    String? icon,
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
        icon: icon,
      );

  /// Creates a range configurable field.
  ///
  /// The [key], [label], [start], and [end] are required.
  /// The range is bounded by [min] and [max].
  RangeConfigurable range({
    required String key,
    required String label,
    required num start,
    required num end,
    String? description,
    String? hint,
    String Function(RangeValue)? formatter,
    String? Function(RangeValue)? validator,
    String? icon,
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
        icon: icon,
        min: min,
        max: max,
        step: step,
        unit: unit,
        width: width,
      );

  /// Creates a rating configurable field.
  ///
  /// The [key] and [label] are required. The [value] defaults to 3.
  /// The [maxStars] defaults to 5.
  RatingConfigurable rating({
    required String key,
    required String label,
    int value = 3,
    String? description,
    String? hint,
    String Function(int)? formatter,
    String? Function(int)? validator,
    String? icon,
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
        icon: icon,
        maxStars: maxStars,
        labels: labels,
      );

  /// Creates a theme configurable field.
  ///
  /// The [key] and [label] are required. The [value] defaults to `'dark'`.
  /// If [themes] is not provided, [builtInThemes] is used.
  ThemeConfigurable theme({
    required String key,
    required String label,
    String value = 'dark',
    String? description,
    String? hint,
    String Function(String)? formatter,
    String? Function(String)? validator,
    String? icon,
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
        icon: icon,
        themes: themes,
        onChanged: onChanged,
      );

  /// Creates a group configurable field.
  ///
  /// The [key], [label], and [children] are required.
  /// The group itself has no direct value; its value is a map of its children's values.
  GroupConfigurable group({
    required String key,
    required String label,
    required List<Configurable> children,
    String? description,
    String? hint,
    String? icon,
  }) =>
      GroupConfigurable(
        key: key,
        label: label,
        children: children,
        description: description,
        hint: hint,
        icon: icon,
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
  /// Returns a [ConfigFactory] instance for creating configurables.
  ConfigFactory get config => const ConfigFactory();
}
