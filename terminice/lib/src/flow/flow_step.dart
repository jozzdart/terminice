part of 'flow.dart';

/// Adds reusable steps to a [FlowBuilder].
typedef FlowTemplate = void Function(FlowBuilder flow);

/// Builds a review summary string for a completed flow step value.
typedef FlowSummary<T> = String Function(T value, FlowContext context);

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

abstract class _FlowStep<T> {
  String get key;
  String get label;
  String? get reviewLabel;
  bool get includeInReview;
  bool get editable;
  FlowCondition? get when;
  bool get cancelOnNull;

  bool shouldRun(FlowContext context) => when?.call(context) ?? true;

  Object? run(FlowContext context);

  String? validationErrorFor(Object? value, FlowContext context);

  String? reviewSummaryFor(Object? value, FlowContext context);
}

typedef _FlowValueValidator = String? Function(
  Object? value,
  FlowContext context,
);

typedef _FlowValueSummary = String Function(
  Object? value,
  FlowContext context,
);

class _CustomFlowStep<T> extends _FlowStep<T> {
  _CustomFlowStep({
    required this.key,
    required this.label,
    required FlowStepRunner<T> run,
    required FlowValidator<T>? validate,
    required this.when,
    required this.cancelOnNull,
    required this.reviewLabel,
    required FlowSummary<T>? summarize,
    required this.includeInReview,
    required this.editable,
  })  : _run = run,
        _summarize = _flowSummaryFor<T>(key, label, summarize),
        _validate = _flowValidatorFor<T>(key, label, validate);

  @override
  final String key;

  @override
  final String label;

  @override
  final String? reviewLabel;

  final FlowStepRunner<T> _run;

  final _FlowValueSummary? _summarize;

  final _FlowValueValidator? _validate;

  @override
  final bool includeInReview;

  @override
  final bool editable;

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

  @override
  String? reviewSummaryFor(Object? value, FlowContext context) {
    final summarize = _summarize;
    if (summarize == null) return null;
    return summarize(value, context);
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

_FlowValueSummary? _flowSummaryFor<T>(
  String key,
  String label,
  FlowSummary<T>? summarize,
) {
  if (summarize == null) return null;

  return (Object? value, FlowContext context) {
    if (value is! T) {
      throw StateError(
        "Flow step '$key' ($label) returned ${_typeName(value)}, "
        'which cannot be summarized as $T.',
      );
    }
    return summarize(value, context);
  };
}
