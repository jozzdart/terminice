import 'package:terminice/terminice.dart';

/// A configurable star-rating field.
///
/// Opens a discrete rating prompt with 1–[maxStars] stars.
/// Optional [labels] map each star level to a human-readable label.
///
/// ```dart
/// RatingConfigurable(
///   key: 'priority',
///   label: 'Priority',
///   value: 3,
///   maxStars: 5,
///   labels: ['Lowest', 'Low', 'Medium', 'High', 'Critical'],
/// )
/// ```
class RatingConfigurable extends Configurable<int> {
  /// Maximum number of stars (1-based).
  final int maxStars;

  /// Optional labels for each star level (index 0 = 1 star, etc.).
  final List<String>? labels;

  RatingConfigurable({
    required super.key,
    required super.label,
    super.value = 3,
    super.description,
    super.hint,
    super.formatter,
    super.validator,
    super.icon,
    this.maxStars = 5,
    this.labels,
  }) {
    assert(maxStars > 0, 'maxStars must be greater than 0');
    assert(value >= 0 && value <= maxStars, 'value must be in [0, maxStars]');
  }

  @override
  String get defaultTypeIcon => '★';

  @override
  String formatValue() {
    final filled = '★' * value;
    final empty = '☆' * (maxStars - value);
    if (labels != null && labels!.length >= maxStars && value > 0) {
      return '$filled$empty (${labels![(value - 1).clamp(0, maxStars - 1)]})';
    }
    return '$filled$empty';
  }

  @override
  bool edit(Terminice terminice) {
    final result = terminice.rating(
      label,
      maxStars: maxStars,
      initial: value,
      labels: labels,
    );
    if (result != value) {
      value = result;
      return true;
    }
    return false;
  }

  @override
  dynamic toJsonValue() => value;

  @override
  void loadJsonValue(dynamic jsonValue) {
    if (jsonValue is int && jsonValue >= 0 && jsonValue <= maxStars) {
      value = jsonValue;
    }
  }
}
