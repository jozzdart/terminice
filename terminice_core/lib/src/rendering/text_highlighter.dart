import 'package:terminice_core/terminice_core.dart';

/// Highlights the first case-insensitive occurrence of [query] in [text]
/// using the theme's highlight color, preserving the rest of the string.
/// If [enabled] is false or [query] is empty/missing, returns [text] unchanged.
String highlightSubstring(
  String text,
  String query,
  PromptTheme theme, {
  bool enabled = true,
}) {
  if (!enabled || query.isEmpty) return text;
  final lower = text.toLowerCase();
  final q = query.toLowerCase();
  final idx = lower.indexOf(q);
  if (idx == -1) return text;
  final before = text.substring(0, idx);
  final match = text.substring(idx, idx + q.length);
  final after = text.substring(idx + q.length);
  return '$before${theme.highlight}$match${theme.reset}$after';
}
