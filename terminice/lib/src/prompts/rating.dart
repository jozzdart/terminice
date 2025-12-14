import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Star rating prompt with gradient stars, optional labels, and numeric
/// shortcuts.
///
/// Controls:
/// - ← / → adjust the selection
/// - Number keys jump directly to a value
/// - Enter confirms
/// - Esc cancels (restores the initial rating)
///
/// ```dart
/// final rating = terminice.rating(
///   'Rate this product',
///   labels: ['Nope', 'Meh', 'Okay', 'Great', 'Amazing'],
/// );
/// ```
extension RatingPromptExtensions on Terminice {
  /// Rating prompt (default 1-5 stars) with optional label overrides.
  ///
  /// Returns the selected rating.
  ///
  /// **Example:**
  /// ```dart
  /// final review = terminice.rating('Satisfaction');
  /// ```
  int rating(
    String prompt, {
    int maxStars = 5,
    int initial = 3,
    List<String>? labels,
  }) {
    assert(maxStars > 0, 'maxStars must be greater than 0');
    assert(initial >= 0, 'initial must be greater than or equal to 0');

    final theme = defaultTheme;
    void renderLabel(FrameContext ctx, int value, int max) {
      final effectiveLabels = labels;
      if (effectiveLabels != null && effectiveLabels.length >= max) {
        final label = effectiveLabels[(value - 1).clamp(0, max - 1)];
        ctx.labeledAccent('Rating', label);
      } else {
        ctx.numericScale(value, max);
      }
    }

    final valuePrompt = DiscreteValuePrompt(
      title: prompt,
      maxValue: maxStars,
      initial: initial,
      theme: theme,
    );

    return valuePrompt.run(
      render: (ctx, value, max) {
        ctx.starsDisplay(value, max);
        renderLabel(ctx, value, max);
      },
    );
  }
}
