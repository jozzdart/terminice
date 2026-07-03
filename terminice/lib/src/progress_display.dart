/// Normalized determinate progress values used for rendering.
class ProgressDisplay {
  /// Completed units clamped to the inclusive `0..total` range.
  final int current;

  /// Total units used for display, or `0` when the input total is invalid.
  final int total;

  /// Completion ratio clamped to the inclusive `0..1` range.
  final double ratio;

  const ProgressDisplay._({
    required this.current,
    required this.total,
    required this.ratio,
  });

  /// Rounded percentage clamped to the inclusive `0..100` range.
  int get percent => (ratio * 100).round().clamp(0, 100).toInt();

  /// Number of filled cells for a bar of [width] cells.
  int filledUnits(int width) {
    if (width <= 0) return 0;
    return (ratio * width).round().clamp(0, width).toInt();
  }
}

/// Builds normalized display values for determinate progress.
///
/// Positive totals clamp [current] into the inclusive `0..total` range.
/// Nonpositive totals render as empty progress to avoid division errors.
ProgressDisplay progressDisplay({
  required int current,
  required int total,
}) {
  if (total <= 0) {
    return const ProgressDisplay._(current: 0, total: 0, ratio: 0);
  }

  final clampedCurrent = current.clamp(0, total).toInt();
  return ProgressDisplay._(
    current: clampedCurrent,
    total: total,
    ratio: clampedCurrent / total,
  );
}
