part of 'flow.dart';

/// Read-only view of values collected by earlier flow steps.
class FlowContext {
  final Terminice _terminice;
  final Map<String, Object?> _values;

  FlowContext._({
    required Terminice terminice,
    required Map<String, Object?> values,
  })  : _terminice = terminice,
        _values = Map<String, Object?>.unmodifiable(_orderedCopy(values));

  /// Terminice instance configured for the current flow.
  Terminice get terminice => _terminice;

  /// Returns the value stored for [key] as [T].
  ///
  /// Throws a [StateError] when [key] is missing or the stored value is not
  /// assignable to [T].
  T value<T>(String key) => _value<T>(_values, key);

  /// Returns the value stored for [key] as [T], or `null` when absent or null.
  ///
  /// Throws a [StateError] when [key] exists with a non-null value that is not
  /// assignable to [T].
  T? maybe<T>(String key) => _maybe<T>(_values, key);

  /// Whether [key] has been written by an earlier flow step.
  bool contains(String key) => _values.containsKey(key);

  /// Returns an insertion-ordered copy of the values visible to this step.
  Map<String, Object?> toMap() => _orderedCopy(_values);
}

/// Result returned after a flow confirms or cancels.
class FlowResult {
  final Map<String, Object?> _values;

  FlowResult._confirmed(Map<String, Object?> values)
      : confirmed = true,
        cancelledKey = null,
        _values = Map<String, Object?>.unmodifiable(_orderedCopy(values));

  FlowResult._cancelled(
    Map<String, Object?> values, {
    required this.cancelledKey,
  })  : confirmed = false,
        _values = Map<String, Object?>.unmodifiable(_orderedCopy(values));

  /// Whether the flow ran all applicable steps without cancellation.
  final bool confirmed;

  /// Whether the flow stopped because a step cancelled.
  bool get cancelled => !confirmed;

  /// Key of the step that cancelled the flow, if any.
  final String? cancelledKey;

  /// Returns the value stored for [key] as [T].
  ///
  /// Throws a [StateError] when [key] is missing or the stored value is not
  /// assignable to [T].
  T value<T>(String key) => _value<T>(_values, key);

  /// Returns the value stored for [key] as [T], or `null` when absent or null.
  ///
  /// Throws a [StateError] when [key] exists with a non-null value that is not
  /// assignable to [T].
  T? maybe<T>(String key) => _maybe<T>(_values, key);

  /// Whether [key] was written by the flow.
  bool contains(String key) => _values.containsKey(key);

  /// Returns an insertion-ordered copy of the collected values.
  Map<String, Object?> toMap() => _orderedCopy(_values);
}

Map<String, Object?> _orderedCopy(Map<String, Object?> values) {
  return LinkedHashMap<String, Object?>.of(values);
}

T _value<T>(Map<String, Object?> values, String key) {
  if (!values.containsKey(key)) {
    throw StateError(
      "Flow value '$key' is missing. ${_availableKeys(values)}",
    );
  }

  final value = values[key];
  if (value is! T) {
    throw StateError(
      "Flow value '$key' has type ${_typeName(value)}, "
      'which cannot be read as $T.',
    );
  }
  return value;
}

T? _maybe<T>(Map<String, Object?> values, String key) {
  if (!values.containsKey(key)) return null;

  final value = values[key];
  if (value == null) return null;
  if (value is! T) {
    throw StateError(
      "Flow value '$key' has type ${_typeName(value)}, "
      'which cannot be read as $T.',
    );
  }
  return value as T;
}

String _availableKeys(Map<String, Object?> values) {
  if (values.isEmpty) return 'No flow values are available.';
  return 'Available keys: ${values.keys.join(', ')}.';
}

String _typeName(Object? value) {
  if (value == null) return 'Null';
  return value.runtimeType.toString();
}
