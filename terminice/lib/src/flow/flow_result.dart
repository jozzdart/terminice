part of 'flow.dart';

/// Read-only view of values collected by earlier flow steps.
class FlowContext with _FlowValueAccess {
  final Terminice _terminice;
  final _FlowProgressFormatter? _progress;
  final int? _stepIndex;
  final int? _stepCount;

  @override
  final Map<String, Object?> _values;

  FlowContext._({
    required Terminice terminice,
    required Map<String, Object?> values,
    _FlowProgressFormatter? progress,
    int? stepIndex,
    int? stepCount,
  })  : _terminice = terminice,
        _progress = progress,
        _stepIndex = stepIndex,
        _stepCount = stepCount,
        _values = Map<String, Object?>.unmodifiable(_orderedCopy(values));

  /// Terminice instance configured for the current flow.
  Terminice get terminice => _terminice;

  String _promptTitle(String title) {
    final progress = _progress;
    final stepIndex = _stepIndex;
    final stepCount = _stepCount;
    if (progress == null || stepIndex == null || stepCount == null) {
      return title;
    }
    return progress.titleFor(title, index: stepIndex, total: stepCount);
  }

  String _fallbackPromptTitle(String title) {
    if (!_terminice.shouldUseFallback) return title;
    return _promptTitle(title);
  }
}

/// Summary metadata for a collected flow value.
class FlowSummaryItem {
  /// Creates an immutable summary item for a flow value.
  const FlowSummaryItem({
    required this.key,
    required this.label,
    required this.value,
    this.summary,
    this.editable = false,
  });

  /// Key of the flow step that produced [value].
  final String key;

  /// Human-readable label to show for this item.
  final String label;

  /// Raw value collected by the flow step.
  final Object? value;

  /// Optional display summary for [value].
  final String? summary;

  /// Whether future review UIs may allow editing this item.
  final bool editable;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FlowSummaryItem &&
            other.key == key &&
            other.label == label &&
            other.value == value &&
            other.summary == summary &&
            other.editable == editable;
  }

  @override
  int get hashCode => Object.hash(key, label, value, summary, editable);

  @override
  String toString() {
    return 'FlowSummaryItem('
        'key: $key, '
        'label: $label, '
        'value: $value, '
        'summary: $summary, '
        'editable: $editable'
        ')';
  }
}

/// Result returned after a flow confirms or cancels.
class FlowResult with _FlowValueAccess {
  @override
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
}

mixin _FlowValueAccess {
  Map<String, Object?> get _values;

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

  /// Returns the string stored for [key].
  ///
  /// Throws a [StateError] when [key] is missing or is not a [String].
  String string(String key) => value<String>(key);

  /// Returns the string stored for [key], or `null` when absent or null.
  ///
  /// Throws a [StateError] when [key] exists with a non-null value that is not
  /// a [String].
  String? maybeString(String key) => maybe<String>(key);

  /// Returns the boolean flag stored for [key].
  ///
  /// Throws a [StateError] when [key] is missing or is not a [bool].
  bool flag(String key) => value<bool>(key);

  /// Returns the boolean flag stored for [key], or `null` when absent or null.
  ///
  /// Throws a [StateError] when [key] exists with a non-null value that is not
  /// a [bool].
  bool? maybeFlag(String key) => maybe<bool>(key);

  /// Returns the list stored for [key] as `List<T>`.
  ///
  /// Throws a [StateError] when [key] is missing or is not a `List<T>`.
  List<T> list<T>(String key) => value<List<T>>(key);

  /// Returns the value stored for [key] as [T], or [fallback] when absent/null.
  ///
  /// Throws a [StateError] when [key] exists with a non-null value that is not
  /// assignable to [T].
  T valueOr<T>(String key, T fallback) => maybe<T>(key) ?? fallback;

  /// Whether [key] has been written by the flow.
  bool contains(String key) => _values.containsKey(key);

  /// Returns an insertion-ordered copy of the visible values.
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
