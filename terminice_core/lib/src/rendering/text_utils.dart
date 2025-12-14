/// Centralized text utilities for terminal view/prompt rendering.
///
/// This module provides reusable functions for common text operations:
/// - Padding and truncating strings
/// - ANSI escape code handling
/// - Value clamping and collection utilities
///
/// Import and use these instead of duplicating private helpers in views.
library;

// ============================================================================
// STRING MANIPULATION
// ============================================================================

/// Pads [text] to [width] with trailing spaces.
///
/// If [text] is already at or longer than [width], returns [text] unchanged.
///
/// Example:
/// ```dart
/// padRight('Hi', 5); // 'Hi   '
/// padRight('Hello', 3); // 'Hello'
/// ```
String padRight(String text, int width) {
  if (text.length >= width) return text;
  return text + ' ' * (width - text.length);
}

/// Pads [text] to [width] with leading spaces.
///
/// If [text] is already at or longer than [width], returns [text] unchanged.
///
/// Example:
/// ```dart
/// padLeft('42', 5); // '   42'
/// ```
String padLeft(String text, int width) {
  if (text.length >= width) return text;
  return ' ' * (width - text.length) + text;
}

/// Truncates [text] to [width] characters, adding an ellipsis if clipped.
///
/// If [text] fits within [width], it's returned unchanged.
/// If truncation is needed, the last character becomes '…'.
///
/// Example:
/// ```dart
/// truncate('Hello World', 8); // 'Hello W…'
/// truncate('Hi', 10); // 'Hi'
/// ```
String truncate(String text, int width) {
  if (text.length <= width) return text;
  if (width <= 1) return text.substring(0, width);
  return '${text.substring(0, width - 1)}…';
}

/// Truncates [text] to [width] and pads to fill remaining space.
///
/// Combines truncation and padding for fixed-width column rendering.
///
/// Example:
/// ```dart
/// truncatePad('Hello World', 8); // 'Hello W…'
/// truncatePad('Hi', 8); // 'Hi      '
/// ```
String truncatePad(String text, int width) {
  if (text.length <= width) return padRight(text, width);
  if (width <= 1) return text.substring(0, width);
  return '${text.substring(0, width - 1)}…';
}

// ============================================================================
// ANSI ESCAPE CODE HANDLING
// ============================================================================

/// Regular expression matching ANSI escape sequences.
final _ansiPattern = RegExp(r'\x1B\[[0-9;]*m');

/// Removes ANSI escape codes from [input].
///
/// Useful for calculating visible character length of styled strings.
///
/// Example:
/// ```dart
/// stripAnsi('\x1B[32mGreen\x1B[0m'); // 'Green'
/// ```
String stripAnsi(String input) {
  return input.replaceAll(_ansiPattern, '');
}

/// Returns the visible (printable) character count of [text] after stripping ANSI.
///
/// Use this when calculating column widths for styled text.
///
/// Example:
/// ```dart
/// visibleLength('\x1B[32mHi\x1B[0m'); // 2
/// ```
int visibleLength(String text) {
  return stripAnsi(text).runes.length;
}

/// Pads styled [text] to [width] based on visible character length.
///
/// Unlike [padRight], this accounts for ANSI escape codes when calculating
/// how much padding is needed.
///
/// Example:
/// ```dart
/// padVisibleRight('\x1B[32mHi\x1B[0m', 5); // '\x1B[32mHi\x1B[0m   '
/// ```
String padVisibleRight(String text, int width) {
  final visible = visibleLength(text);
  if (visible >= width) return text;
  return text + ' ' * (width - visible);
}

/// Pads styled [text] to [width] based on visible character length, left-aligned.
String padVisibleLeft(String text, int width) {
  final visible = visibleLength(text);
  if (visible >= width) return text;
  return ' ' * (width - visible) + text;
}

/// Centers styled [text] within [width] based on visible character length.
String padVisibleCenter(String text, int width) {
  final visible = visibleLength(text);
  if (visible >= width) return text;
  final total = width - visible;
  final left = total ~/ 2;
  final right = total - left;
  return ' ' * left + text + ' ' * right;
}

// ============================================================================
// NUMERIC UTILITIES
// ============================================================================

/// Clamps [value] between [min] and [max] (inclusive).
///
/// Example:
/// ```dart
/// clampInt(5, 1, 10); // 5
/// clampInt(15, 1, 10); // 10
/// clampInt(-5, 1, 10); // 1
/// ```
int clampInt(int value, int min, int max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

/// Finds the maximum value in an iterable of integers.
///
/// Returns 0 for empty iterables.
///
/// Example:
/// ```dart
/// maxOf([3, 7, 2, 9]); // 9
/// maxOf([]); // 0
/// ```
int maxOf(Iterable<int> values) {
  var max = 0;
  for (final v in values) {
    if (v > max) max = v;
  }
  return max;
}

/// Finds the minimum value in an iterable of integers.
///
/// Returns 0 for empty iterables.
int minOf(Iterable<int> values) {
  if (values.isEmpty) return 0;
  var min = values.first;
  for (final v in values) {
    if (v < min) min = v;
  }
  return min;
}

// ============================================================================
// COLUMN WIDTH HELPERS
// ============================================================================

/// Computes optimal column width from content lengths, clamped to bounds.
///
/// Useful for auto-sizing table/list columns based on content.
///
/// Example:
/// ```dart
/// columnWidth(['Name', 'Alice', 'Bob'], min: 4, max: 20); // 5
/// columnWidth(['VeryLongName'], min: 4, max: 8); // 8
/// ```
int columnWidth(Iterable<String> values, {int min = 0, int max = 999}) {
  final maxLen = maxOf(values.map((s) => s.length));
  return clampInt(maxLen, min, max);
}

/// Computes optimal column width from styled content (ANSI-aware).
int columnWidthVisible(Iterable<String> values, {int min = 0, int max = 999}) {
  final maxLen = maxOf(values.map(visibleLength));
  return clampInt(maxLen, min, max);
}
