part of 'flow.dart';

/// Decides whether a flow step should run.
typedef FlowCondition = bool Function(FlowContext context);

/// Validates a value returned by a flow step.
///
/// Return `null` for success. Returning an empty string is also treated as
/// success for compatibility with older Terminice validators. Steps that can
/// store `null` expose a nullable value type to validators so callers can
/// decide whether `null` is acceptable.
typedef FlowValidator<T> = String? Function(T value, FlowContext context);

/// Runs a custom flow step and returns its value.
///
/// Returning `null` cancels the flow unless the step was configured with
/// `cancelOnNull: false`.
typedef FlowStepRunner<T> = T? Function(FlowContext context);

/// Exception thrown when a flow step returns a value that fails validation.
class FlowValidationException implements Exception {
  /// Creates a validation exception for [key].
  const FlowValidationException({
    required this.key,
    required this.label,
    required this.message,
  });

  /// Key of the step that failed validation.
  final String key;

  /// Human-readable label of the step that failed validation.
  final String label;

  /// Normalized validation error message.
  final String message;

  @override
  String toString() {
    return "FlowValidationException: step '$key' ($label) failed validation: "
        '$message';
  }
}

abstract class _FlowStep {
  String get key;
  String get label;
  FlowCondition? get when;
  bool get cancelOnNull;

  bool shouldRun(FlowContext context) => when?.call(context) ?? true;

  Object? run(FlowContext context);

  String? validationErrorFor(Object? value, FlowContext context);
}

typedef _FlowValueValidator = String? Function(
  Object? value,
  FlowContext context,
);

class _CustomFlowStep<T> extends _FlowStep {
  _CustomFlowStep({
    required this.key,
    required this.label,
    required FlowStepRunner<T> run,
    required FlowValidator<T>? validate,
    required this.when,
    required this.cancelOnNull,
  })  : _run = run,
        _validate = _flowValidatorFor<T>(key, label, validate);

  @override
  final String key;

  @override
  final String label;

  final FlowStepRunner<T> _run;

  final _FlowValueValidator? _validate;

  @override
  final FlowCondition? when;

  @override
  final bool cancelOnNull;

  @override
  Object? run(FlowContext context) => _run(context);

  @override
  String? validationErrorFor(Object? value, FlowContext context) {
    final validator = _validate;
    if (validator == null) return null;
    return validator(value, context);
  }
}

_FlowValueValidator? _flowValidatorFor<T>(
  String key,
  String label,
  FlowValidator<T>? validate,
) {
  if (validate == null) return null;

  return (Object? value, FlowContext context) {
    if (value is! T) {
      throw StateError(
        "Flow step '$key' ($label) returned ${_typeName(value)}, "
        'which cannot be validated as $T.',
      );
    }
    return normalizeValidationError(validate(value, context));
  };
}
