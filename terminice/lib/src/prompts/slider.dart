import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Interactive slider prompt for continuous value selection with a
/// theme-aware bar renderer.
///
/// Controls:
/// - ← / → adjust value by `step`
/// - Enter confirms the selection
/// - Esc / Ctrl+C cancel (returns the original value)
///
/// ```dart
/// final percent = terminice.slider(
///   'CPU allocation',
///   min: 0,
///   max: 200,
///   initial: 150,
/// );
///
/// final timeout = terminice.slider(
///   'Timeout',
///   min: 0,
///   max: 120,
///   initial: 30,
///   unit: 's',
///   showPercent: false,
/// );
/// ```
extension SliderPromptExtensions on Terminice {
  /// Slider prompt for selecting a numeric value within `[min, max]`.
  ///
  /// Returns the selected value as `num`.
  ///
  /// **Example**
  /// ```dart
  /// final volume = terminice.slider(
  ///   'Volume',
  ///   initial: 50,
  ///   step: 5,
  /// );
  /// ```
  num slider(
    String prompt, {
    num min = 0,
    num max = 100,
    num initial = 50,
    num step = 1,
    int width = 28,
    String unit = '',
    bool showPercent = false,
  }) {
    final promptObj = ValuePrompt(
      title: prompt,
      min: min,
      max: max,
      initial: initial,
      step: step,
      theme: defaultTheme,
    );

    return promptObj.run(
      render: (ctx, value, ratio) {
        ctx.sliderBar(
          ratio,
          width: width,
          showPercent: showPercent,
          value: value,
          unit: unit,
        );
      },
    );
  }
}
