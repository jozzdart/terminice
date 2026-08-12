import 'package:terminice_core/terminice_core.dart';

/// Truncates terminal text while preserving legacy three-dot output.
///
/// Cell measurement, grapheme boundaries, and ANSI closure are delegated to
/// the centralized terminal text helper.
String truncateWithDots(String text, int width) {
  if (width < 0) return truncate(text, width);
  if (visibleLength(text) <= width) return truncate(text, width);
  if (width <= 3) return _clipWithoutEllipsis(text, width);

  final clipped = truncate(text, width - 2);
  return _replaceGeneratedEllipsis(clipped, '...');
}

String _clipWithoutEllipsis(String text, int width) {
  if (width == 0) return '';

  // The extra printable cell guarantees truncation even when [text] is only
  // one cell wider than the requested width. The centralized helper therefore
  // emits a terminal-cell-safe prefix, its ellipsis, and any required ANSI/OSC
  // closures. Removing only that generated ellipsis leaves the safe prefix and
  // closures intact.
  final clipped = truncate('$text ', width + 1);
  return _replaceGeneratedEllipsis(clipped, '');
}

String _replaceGeneratedEllipsis(String clipped, String replacement) {
  final ellipsis = clipped.lastIndexOf('…');
  if (ellipsis < 0) return clipped;
  return clipped.replaceRange(ellipsis, ellipsis + 1, replacement);
}
