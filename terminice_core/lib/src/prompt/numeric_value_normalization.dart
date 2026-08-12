/// An ordered pair produced by [normalizeSteppedRange].
class NormalizedNumericRange {
  /// The normalized lower endpoint.
  final num start;

  /// The normalized upper endpoint.
  final num end;

  /// Creates an ordered normalized range.
  const NormalizedNumericRange({
    required this.start,
    required this.end,
  });
}

/// Clamps [value] to the optional bounds and snaps it to the nearest [step].
///
/// Step alignment is anchored at [min], or at zero when [min] is absent.
/// Exact ties choose the higher step. When a bound falls between steps, the
/// returned value stays on the nearest valid step inside that bound.
/// Configurations whose step grid cannot be represented finitely throw
/// [ArgumentError] instead of returning an off-grid value.
num normalizeSteppedValue(
  num value, {
  num? min,
  num? max,
  num? step,
}) {
  validateNumericConstraints(min: min, max: max, step: step);
  _validateFinite(value, 'value');

  return _normalizeValidatedValue(value, min: min, max: max, step: step);
}

/// Validates the shared bounds and step contract for numeric prompts.
///
/// Optional bounds must be finite and ordered. An optional [step] must be
/// finite and greater than zero. A bounded step grid must also have a finite
/// representable span. Invalid constraints throw [ArgumentError].
/// This is exposed so prompt implementations can validate their configuration
/// even when they do not have an initial value to normalize.
void validateNumericConstraints({
  num? min,
  num? max,
  num? step,
}) {
  _validateFinite(min, 'min');
  _validateFinite(max, 'max');
  _validateFinite(step, 'step');
  if (min != null && max != null && min > max) {
    throw ArgumentError.value(
      max,
      'max',
      'must be greater than or equal to min',
    );
  }
  if (step != null && step <= 0) {
    throw ArgumentError.value(
      step,
      'step',
      'must be finite and greater than 0',
    );
  }
  if (step != null && max != null) {
    final anchor = min ?? 0;
    final maxUnits = (max - anchor) / step;
    if (!maxUnits.isFinite) {
      throw ArgumentError.value(
        step,
        'step',
        'produces an unrepresentable step grid for the supplied bounds',
      );
    }
  }
}

num _normalizeValidatedValue(
  num value, {
  num? min,
  num? max,
  num? step,
}) {
  var normalized = value;
  if (min != null && normalized < min) normalized = min;
  if (max != null && normalized > max) normalized = max;
  if (step == null) return normalized;

  final anchor = min ?? 0;
  final units = (normalized - anchor) / step;
  if (!units.isFinite) {
    throw ArgumentError.value(
      step,
      'step',
      'produces an unrepresentable step grid for the supplied value',
    );
  }

  var stepIndex = _nearestStepIndex(units);
  if (min != null && stepIndex < 0) stepIndex = 0;
  if (max != null) {
    final maxUnits = (max - anchor) / step;
    final maxStepIndex = _maximumInBoundsStepIndex(
      maxUnits,
      anchor: anchor,
      max: max,
      step: step,
    );
    if (stepIndex > maxStepIndex) stepIndex = maxStepIndex;
  }

  final result = anchor + stepIndex * step;
  if (!result.isFinite) {
    throw ArgumentError.value(
      step,
      'step',
      'produces a non-finite normalized value',
    );
  }
  return result;
}

int _nearestStepIndex(num units) {
  final lower = units.floor();
  final fraction = units - lower;
  return fraction < 0.5 ? lower : lower + 1;
}

int _maximumInBoundsStepIndex(
  num maxUnits, {
  required num anchor,
  required num max,
  required num step,
}) {
  final lower = maxUnits.floor();
  final nearest = maxUnits.round();
  if (nearest <= lower) return lower;

  final reconstructed = anchor + nearest * step;
  if (!reconstructed.isFinite) return lower;

  const machineEpsilon = 2.220446049250313e-16;
  final maxMagnitude = max.abs().toDouble();
  final reconstructedMagnitude = reconstructed.abs().toDouble();
  final scale = maxMagnitude > reconstructedMagnitude
      ? maxMagnitude
      : reconstructedMagnitude;
  final scaleTolerance = 8 * machineEpsilon * (scale < 1 ? 1 : scale);
  final stepTolerance = 8 * machineEpsilon * step.abs().toDouble();
  final tolerance =
      scaleTolerance < stepTolerance ? scaleTolerance : stepTolerance;
  final difference = (reconstructed - max).abs().toDouble();

  return difference <= tolerance ? nearest : lower;
}

/// Normalizes two values using [normalizeSteppedValue] and orders them.
NormalizedNumericRange normalizeSteppedRange(
  num start,
  num end, {
  num? min,
  num? max,
  num? step,
}) {
  validateNumericConstraints(min: min, max: max, step: step);
  _validateFinite(start, 'start');
  _validateFinite(end, 'end');
  final normalizedStart =
      _normalizeValidatedValue(start, min: min, max: max, step: step);
  final normalizedEnd =
      _normalizeValidatedValue(end, min: min, max: max, step: step);
  if (normalizedStart <= normalizedEnd) {
    return NormalizedNumericRange(
      start: normalizedStart,
      end: normalizedEnd,
    );
  }
  return NormalizedNumericRange(
    start: normalizedEnd,
    end: normalizedStart,
  );
}

void _validateFinite(num? value, String name) {
  if (value != null && !value.isFinite) {
    throw ArgumentError.value(value, name, 'must be finite');
  }
}
