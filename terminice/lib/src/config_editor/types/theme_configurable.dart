import 'package:terminice/terminice.dart';

import '../focused_select.dart';

/// Built-in theme presets mapped by name.
const Map<String, PromptTheme> builtInThemes = {
  'dark': PromptTheme.dark,
  'matrix': PromptTheme.matrix,
  'fire': PromptTheme.fire,
  'pastel': PromptTheme.pastel,
  'ocean': PromptTheme.ocean,
  'monochrome': PromptTheme.monochrome,
  'neon': PromptTheme.neon,
  'arcane': PromptTheme.arcane,
  'phantom': PromptTheme.phantom,
  'minimal': PromptTheme.minimal,
  'compact': PromptTheme.compact,
};

/// A configurable that lets the user pick a [PromptTheme] from a list.
///
/// When used inside a config editor, changing the theme takes effect
/// immediately on the next render cycle -- the editor re-renders with
/// the newly selected theme.
///
/// Provides an [onChanged] callback so the config editor (or any
/// consumer) can react to theme switches in real time.
///
/// ```dart
/// ThemeConfigurable(
///   key: 'theme',
///   label: 'Theme',
///   value: 'dark',
///   description: 'Color scheme for the editor',
/// )
/// ```
///
/// Custom themes can be supplied via [themes]:
/// ```dart
/// ThemeConfigurable(
///   key: 'theme',
///   label: 'Theme',
///   value: 'brand',
///   themes: {
///     ...builtInThemes,
///     'brand': myBrandTheme,
///   },
/// )
/// ```
class ThemeConfigurable extends Configurable<String> {
  /// Map of theme name -> PromptTheme.
  final Map<String, PromptTheme> themes;

  /// Called whenever the user picks a new theme.
  /// The config editor hooks into this to apply the theme live.
  void Function(PromptTheme theme)? onChanged;

  /// Creates a theme configurable field.
  ///
  /// The [key] and [label] are required. The [value] defaults to `'dark'`.
  /// If [themes] is not provided, [builtInThemes] is used.
  ThemeConfigurable({
    required super.key,
    required super.label,
    super.value = 'dark',
    super.description,
    super.hint,
    super.formatter,
    super.validator,
    super.icon,
    Map<String, PromptTheme>? themes,
    this.onChanged,
  }) : themes = themes ?? builtInThemes {
    assert(
      (themes ?? builtInThemes).containsKey(value),
      'Initial value "$value" must be a key in themes',
    );
  }

  @override
  String get defaultTypeIcon => '◐';

  /// The currently selected [PromptTheme].
  PromptTheme get selectedTheme => themes[value] ?? PromptTheme.dark;

  @override
  bool edit(Terminice terminice) {
    final keys = themes.keys.toList();
    final selected = focusedSelect(
      theme: terminice.defaultTheme,
      options: keys,
      title: label,
      initialIndex: keys.indexOf(value).clamp(0, keys.length - 1),
      showSearch: keys.length > 5,
      maxVisible: 10,
    );
    if (selected == null || selected == value) return false;
    value = selected;
    onChanged?.call(selectedTheme);
    return true;
  }

  @override
  dynamic toJsonValue() => value;

  @override
  void loadJsonValue(dynamic jsonValue) {
    if (jsonValue is String && themes.containsKey(jsonValue)) {
      value = jsonValue;
    }
  }
}
