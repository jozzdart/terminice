import 'package:terminice/terminice.dart';

/// Internal pair to hold the two endpoints of a range.
class RangeValue {
  num start;
  num end;

  RangeValue(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      other is RangeValue && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '$start – $end';
}

/// A configurable dual-handle range field.
///
/// Opens a range prompt with start/end handles bounded by [min] and [max].
///
/// ```dart
/// RangeConfigurable(
///   key: 'budget',
///   label: 'Budget Range',
///   start: 20,
///   end: 80,
///   unit: '%',
/// )
/// ```
class RangeConfigurable extends Configurable<RangeValue> {
  final num min;
  final num max;
  final num step;
  final String unit;
  final int width;

  RangeConfigurable({
    required super.key,
    required super.label,
    required num start,
    required num end,
    super.description,
    super.hint,
    super.formatter,
    super.validator,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.unit = '%',
    this.width = 28,
  }) : super(value: RangeValue(start, end));

  @override
  String get typeIcon => '↔';

  @override
  String formatValue() {
    final s = _formatNum(value.start);
    final e = _formatNum(value.end);
    return unit.isNotEmpty ? '$s$unit – $e$unit' : '$s – $e';
  }

  String _formatNum(num v) {
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  @override
  bool edit(Terminice terminice) {
    final result = terminice.range(
      label,
      min: min,
      max: max,
      startInitial: value.start,
      endInitial: value.end,
      step: step,
      width: width,
      unit: unit,
    );
    final newValue = RangeValue(result.start, result.end);
    if (newValue != value) {
      value = newValue;
      return true;
    }
    return false;
  }

  @override
  dynamic toJsonValue() => {'start': value.start, 'end': value.end};

  @override
  void loadJsonValue(dynamic jsonValue) {
    if (jsonValue is Map) {
      final s = jsonValue['start'];
      final e = jsonValue['end'];
      if (s is num && e is num) {
        value = RangeValue(s, e);
      }
    }
  }
}
