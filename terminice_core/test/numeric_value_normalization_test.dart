import 'package:terminice_core/terminice_core.dart';
import 'package:terminice_core/testing.dart' show MockTerminal;
import 'package:test/test.dart';

void main() {
  setUp(TerminalContext.reset);
  tearDown(TerminalContext.reset);

  group('numeric value normalization', () {
    test('clamps to in-bounds step points anchored at min', () {
      expect(normalizeSteppedValue(-4, min: 1, max: 9, step: 3), 1);
      expect(normalizeSteppedValue(99, min: 1, max: 9, step: 3), 7);
    });

    test('snaps ties to the higher step', () {
      expect(normalizeSteppedValue(3, min: 0, max: 10, step: 2), 4);
    });

    test('chooses the truly nearest step around a half boundary', () {
      expect(normalizeSteppedValue(0.4999999995, step: 1), 0);
      expect(normalizeSteppedValue(0.5, step: 1), 1);
      expect(normalizeSteppedValue(0.5000000005, step: 1), 1);
    });

    test('chooses the nearest decimal step around a half boundary', () {
      expect(
        normalizeSteppedValue(0.3999999999, min: 0.1, step: 0.2),
        closeTo(0.3, 1e-12),
      );
      expect(
        normalizeSteppedValue(0.4, min: 0.1, step: 0.2),
        closeTo(0.5, 1e-12),
      );
      expect(
        normalizeSteppedValue(0.4000000001, min: 0.1, step: 0.2),
        closeTo(0.5, 1e-12),
      );
    });

    test('does not bias large representable step indices upward', () {
      const exactInteger = 4503599627370496.0; // 2^52
      const exactQuarter = 1125899906842624.25; // 2^50 + 0.25

      expect(normalizeSteppedValue(exactInteger, step: 1), exactInteger);
      expect(
        normalizeSteppedValue(exactQuarter, step: 1),
        1125899906842624.0,
      );
    });

    test('retains decimal maxima that are mathematically on the step grid', () {
      expect(
        normalizeSteppedValue(0.7, min: 0.1, max: 0.7, step: 0.2),
        closeTo(0.7, 1e-12),
      );
      expect(
        normalizeSteppedValue(0.3, min: 0, max: 0.3, step: 0.1),
        closeTo(0.3, 1e-12),
      );
    });

    test('keeps a genuinely off-grid maximum on the lower step', () {
      expect(
        normalizeSteppedValue(0.69, min: 0.1, max: 0.69, step: 0.2),
        closeTo(0.5, 1e-12),
      );
      expect(
        normalizeSteppedValue(
          1125899906842624.75,
          max: 1125899906842624.75,
          step: 1,
        ),
        1125899906842624.0,
      );
    });

    test('handles decimal step precision', () {
      expect(
        normalizeSteppedValue(0.3, min: 0.1, max: 0.9, step: 0.2),
        closeTo(0.3, 1e-12),
      );
      expect(
        normalizeSteppedValue(0.4, min: 0.1, max: 0.9, step: 0.2),
        closeTo(0.5, 1e-12),
      );
    });

    test('normalizes and orders reversed range endpoints', () {
      final range = normalizeSteppedRange(
        10,
        2,
        min: 0,
        max: 9,
        step: 2,
      );

      expect(range.start, 2);
      expect(range.end, 8);
    });

    test('preserves the established invalid-step contract', () {
      expect(
        () => normalizeSteppedValue(1, step: 0),
        throwsArgumentError,
      );
      expect(
        () => normalizeSteppedRange(1, 2, step: double.nan),
        throwsArgumentError,
      );
    });

    test('rejects every non-finite value and bound', () {
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity
      ]) {
        expect(
          () => normalizeSteppedValue(value),
          throwsArgumentError,
          reason: 'value: $value',
        );
        expect(
          () => normalizeSteppedValue(1, min: value),
          throwsArgumentError,
          reason: 'min: $value',
        );
        expect(
          () => normalizeSteppedValue(1, max: value),
          throwsArgumentError,
          reason: 'max: $value',
        );
      }
    });

    test('range rejects non-finite endpoints before normalization', () {
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity
      ]) {
        expect(
          () => normalizeSteppedRange(value, 1),
          throwsArgumentError,
          reason: 'start: $value',
        );
        expect(
          () => normalizeSteppedRange(1, value),
          throwsArgumentError,
          reason: 'end: $value',
        );
      }
    });

    test('rejects reversed bounds', () {
      expect(
        () => normalizeSteppedValue(5, min: 10, max: 0),
        throwsArgumentError,
      );
    });

    test('preserves finite values when no step or bounds are supplied', () {
      expect(normalizeSteppedValue(-12.5), -12.5);
      expect(normalizeSteppedValue(1 << 80), 1 << 80);
    });

    test('rejects a step grid whose intermediate arithmetic overflows', () {
      const largestFinite = 1.7976931348623157e308;

      expect(
        () => normalizeSteppedValue(
          largestFinite,
          min: -largestFinite,
          max: largestFinite,
          step: 0.1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('rich value prompts', () {
    test('ValuePrompt normalizes confirm but preserves exact cancel value', () {
      final confirmTerminal = MockTerminal()
        ..mockInput.queueKey(KeyEventType.enter);
      TerminalContext.current = confirmTerminal;
      final confirmed = ValuePrompt(
        title: 'Value',
        min: 0,
        max: 10,
        initial: 3,
        step: 2,
      ).run(render: (_, __, ___) {});

      final cancelTerminal = MockTerminal()
        ..mockInput.queueKey(KeyEventType.esc);
      TerminalContext.current = cancelTerminal;
      final cancelled = ValuePrompt(
        title: 'Value',
        min: 0,
        max: 10,
        initial: 3,
        step: 2,
      ).run(render: (_, __, ___) {});

      expect(confirmed, 4);
      expect(cancelled, 3);
    });

    test('RangeValuePrompt normalizes confirm but preserves exact cancel range',
        () {
      final confirmTerminal = MockTerminal()
        ..mockInput.queueKey(KeyEventType.enter);
      TerminalContext.current = confirmTerminal;
      final confirmed = RangeValuePrompt(
        title: 'Range',
        min: 0,
        max: 9,
        startInitial: 10,
        endInitial: 2,
        step: 2,
      ).run(render: (_, __, ___, ____) {});

      final cancelTerminal = MockTerminal()
        ..mockInput.queueKey(KeyEventType.esc);
      TerminalContext.current = cancelTerminal;
      final cancelled = RangeValuePrompt(
        title: 'Range',
        min: 0,
        max: 9,
        startInitial: 10,
        endInitial: 2,
        step: 2,
      ).run(render: (_, __, ___, ____) {});

      expect(confirmed.start, 2);
      expect(confirmed.end, 8);
      expect(cancelled.start, 10);
      expect(cancelled.end, 2);
    });
  });
}
