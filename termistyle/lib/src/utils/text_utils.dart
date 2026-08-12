/// Centralized text utilities for terminal view/prompt rendering.
///
/// This module provides reusable functions for common text operations:
/// - Padding and truncating strings
/// - ANSI escape code handling
/// - Value clamping and collection utilities
///
/// Import and use these instead of duplicating private helpers in views.
library text_utils;

import 'terminal_text.dart';

// ============================================================================
// STRING MANIPULATION
// ============================================================================

/// Pads [text] to [width] terminal cells with trailing spaces.
///
/// If [text] is already at or longer than [width], returns [text] unchanged.
///
/// Example:
/// ```dart
/// padRight('Hi', 5); // 'Hi   '
/// padRight('Hello', 3); // 'Hello'
/// ```
String padRight(String text, int width) {
  final visible = TerminalText(text).width;
  if (visible >= width) return text;
  return text + ' ' * (width - visible);
}

/// Pads [text] to [width] terminal cells with leading spaces.
///
/// If [text] is already at or longer than [width], returns [text] unchanged.
///
/// Example:
/// ```dart
/// padLeft('42', 5); // '   42'
/// ```
String padLeft(String text, int width) {
  final visible = TerminalText(text).width;
  if (visible >= width) return text;
  return ' ' * (width - visible) + text;
}

/// Truncates [text] to [width] terminal cells, adding an ellipsis if clipped.
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
  return TerminalText(text).truncate(width);
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
  return padRight(truncate(text, width), width);
}

// ============================================================================
// ANSI ESCAPE CODE HANDLING
// ============================================================================

/// Removes ANSI escape codes from [input].
///
/// Useful for calculating visible character length of styled strings.
///
/// Example:
/// ```dart
/// stripAnsi('\x1B[32mGreen\x1B[0m'); // 'Green'
/// ```
String stripAnsi(String input) {
  return TerminalText(input).plainText;
}

/// Returns the visible terminal-cell width of [text].
///
/// Use this when calculating column widths for styled text.
///
/// Example:
/// ```dart
/// visibleLength('\x1B[32mHi\x1B[0m'); // 2
/// ```
int visibleLength(String text) {
  return TerminalText(text).width;
}

/// Pads styled [text] to [width] based on visible terminal-cell width.
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
  final maxLen = maxOf(values.map((s) => TerminalText(s).width));
  return clampInt(maxLen, min, max);
}

/// Computes optimal column width from styled content (ANSI-aware).
int columnWidthVisible(Iterable<String> values, {int min = 0, int max = 999}) {
  final maxLen = maxOf(values.map(visibleLength));
  return clampInt(maxLen, min, max);
}
