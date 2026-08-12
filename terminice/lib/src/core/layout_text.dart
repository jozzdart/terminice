import 'package:terminice_core/terminice_core.dart';

/// Truncates terminal text while preserving legacy three-dot output.
///
/// Cell measurement, grapheme boundaries, and ANSI closure are delegated to
/// the centralized terminal text helper.
String truncateWithDots(String text, int width) {
  if (width < 0) return truncate(text, width);
  if (visibleLength(text) <= width) return truncate(text, width);
  if (width <= 3) return clipWithoutEllipsis(text, width);

  final clipped = truncate(text, width - 2);
  return _replaceGeneratedEllipsis(clipped, '...');
}

/// Clips to [width] terminal cells without adding an ellipsis.
///
/// This is package-internal and deliberately delegates grapheme selection and
/// ANSI/OSC closure to the centralized terminal text implementation.
String clipWithoutEllipsis(String text, int width) {
  if (width == 0) return '';

  // The extra printable cell guarantees truncation even when [text] is only
  // one cell wider than the requested width. The centralized helper therefore
  // emits a terminal-cell-safe prefix, its ellipsis, and any required ANSI/OSC
  // closures. Removing only that generated ellipsis leaves the safe prefix and
  // closures intact.
  final clipped = truncate('$text ', width + 1);
  return _replaceGeneratedEllipsis(clipped, '');
}

/// Keeps at most [contentWidth] cells and appends an ellipsis when clipped.
///
/// Unlike [truncate], the ellipsis is outside the content budget. This
/// preserves legacy previews that kept N ASCII characters and then appended
/// an ellipsis.
String truncateAfter(String text, int contentWidth) {
  if (visibleLength(text) <= contentWidth) return truncate(text, contentWidth);
  return truncate('$text ', contentWidth + 1);
}

String _replaceGeneratedEllipsis(String clipped, String replacement) {
  final ellipsis = clipped.lastIndexOf('…');
  if (ellipsis < 0) return clipped;
  return clipped.replaceRange(ellipsis, ellipsis + 1, replacement);
}
