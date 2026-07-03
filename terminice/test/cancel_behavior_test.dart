import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';
import 'package:test/test.dart';

import 'mock_terminal.dart';

void main() {
  setUp(TerminalContext.reset);
  tearDown(TerminalContext.reset);

  group('cancel behavior', () {
    test('fallback value prompts return exact supplied initial values', () {
      final sliderTerminal = MockTerminal();
      final sliderResult = terminice.fallback
          .withTerminal(sliderTerminal)
          .slider('Volume', min: 0, max: 10, initial: 42);

      final rangeTerminal = MockTerminal();
      final rangeResult = terminice.fallback.withTerminal(rangeTerminal).range(
            'Window',
            min: 0,
            max: 10,
            startInitial: 20,
            endInitial: -5,
          );

      final ratingTerminal = MockTerminal();
      final ratingResult = terminice.fallback
          .withTerminal(ratingTerminal)
          .rating('Risk', maxStars: 5, initial: 0);

      expect(sliderResult, 42);
      expect(rangeResult.start, 20);
      expect(rangeResult.end, -5);
      expect(ratingResult, 0);
    });

    test('interactive rating Esc returns the exact supplied initial value', () {
      final mock = MockTerminal();
      mock.mockInput.queueKey(KeyEventType.esc);

      final result = Terminice(terminal: mock).rating(
        'Risk',
        maxStars: 5,
        initial: 0,
      );

      expect(result, 0);
    });

    test('config field-level fallback cancel leaves values unchanged', () {
      final rating = RatingConfigurable(
        key: 'risk',
        label: 'Risk',
        value: 0,
        maxStars: 5,
      );
      final ratingEdited = rating.edit(
        terminice.fallback.withTerminal(MockTerminal()),
      );

      final range = RangeConfigurable(
        key: 'window',
        label: 'Window',
        start: 20,
        end: -5,
        min: 0,
        max: 10,
      );
      final rangeEdited = range.edit(
        terminice.fallback.withTerminal(MockTerminal()),
      );

      final slider = NumberConfigurable(
        key: 'volume',
        label: 'Volume',
        value: 42,
        min: 0,
        max: 10,
        useSlider: true,
      );
      final sliderEdited = slider.edit(
        terminice.fallback.withTerminal(MockTerminal()),
      );

      expect(ratingEdited, isFalse);
      expect(rating.value, 0);
      expect(rangeEdited, isFalse);
      expect(range.value.start, 20);
      expect(range.value.end, -5);
      expect(sliderEdited, isFalse);
      expect(slider.value, 42);
    });
  });
}
