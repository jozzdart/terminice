import 'package:terminice/terminice.dart';

/// Base class for all configurable fields in a config editor.
///
/// Each subclass represents a specific value type (bool, string, number, etc.)
/// and knows how to display, validate, serialize, and edit itself using the
/// appropriate terminice prompt.
///
/// Type parameters:
/// - [T] - The Dart type of the value this configurable holds.
///
/// Example:
/// ```dart
/// final field = StringConfigurable(
///   key: 'name',
///   label: 'App Name',
///   value: 'My App',
///   validator: (v) => v.isEmpty ? 'Required' : null,
/// );
/// ```
abstract class Configurable<T> {
  /// Unique key used for serialization and lookup.
  final String key;

  /// Human-readable label shown in the editor list.
  final String label;

  /// Optional longer description shown as context when editing.
  final String? description;

  /// Optional hint text shown alongside the field.
  final String? hint;

  /// The current value of this configurable.
  T value;

  /// The original value before any edits.
  final T defaultValue;

  /// Optional display formatter. When provided, [displayValue] uses this
  /// instead of the default `toString()` representation.
  final String Function(T value)? formatter;

  /// Optional validator. Returns an error message on failure, `null` on success.
  final String? Function(T value)? validator;

  Configurable({
    required this.key,
    required this.label,
    required this.value,
    this.description,
    this.hint,
    this.formatter,
    this.validator,
  }) : defaultValue = value;

  /// Formatted string representation of [value] for display in the list.
  String get displayValue {
    if (formatter != null) return formatter!(value);
    return formatValue();
  }

  /// Override in subclasses to provide type-specific formatting.
  ///
  /// Only called when no custom [formatter] is set.
  String formatValue() => value.toString();

  /// Glyph prefix identifying the field type in the list view.
  String get typeIcon;

  /// Runs the appropriate terminice prompt to edit this field's value.
  ///
  /// Returns `true` if the value was changed, `false` if cancelled.
  bool edit(Terminice terminice);

  /// Serializes the current value into a JSON-compatible map entry.
  dynamic toJsonValue();

  /// Deserializes and applies a value from a JSON-compatible source.
  void loadJsonValue(dynamic jsonValue);

  /// Whether the current value differs from [defaultValue].
  bool get isModified => value != defaultValue;

  /// Resets [value] back to [defaultValue].
  void reset() => value = defaultValue;

  /// Validates the current value. Returns `null` if valid, error message otherwise.
  String? validate() => validator?.call(value);
}

/// Result returned by the config editor after the user confirms.
///
/// Provides typed access to field values, change detection, and
/// serialization to a flat `Map<String, dynamic>`.
class ConfigResult {
  /// The list of all configurable fields with their final values.
  final List<Configurable> fields;

  /// Whether the user confirmed (true) or cancelled (false).
  final bool confirmed;

  const ConfigResult({required this.fields, required this.confirmed});

  /// Serializes all field values into a `{key: value}` map.
  Map<String, dynamic> toMap() {
    return {for (final f in fields) f.key: f.toJsonValue()};
  }

  /// Looks up a field's value by [key], cast to [T].
  ///
  /// Returns `null` if the key is not found.
  T? get<T>(String key) {
    for (final f in fields) {
      if (f.key == key) return f.value as T;
    }
    return null;
  }

  /// Returns the [Configurable] with the given [key], or `null`.
  Configurable? field(String key) {
    for (final f in fields) {
      if (f.key == key) return f;
    }
    return null;
  }

  /// Whether any field has been modified from its default.
  bool get hasChanges => fields.any((f) => f.isModified);

  /// Only the fields whose values differ from their defaults.
  List<Configurable> get modified => fields.where((f) => f.isModified).toList();

  /// Loads values from a previously serialized map into the fields.
  ///
  /// Keys not present in [map] are left unchanged.
  void loadFromMap(Map<String, dynamic> map) {
    for (final f in fields) {
      if (map.containsKey(f.key)) {
        f.loadJsonValue(map[f.key]);
      }
    }
  }
}
