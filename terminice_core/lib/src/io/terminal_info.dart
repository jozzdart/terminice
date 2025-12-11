import 'dart:io';

/// Provides safe, cached access to terminal dimensions with sensible defaults.
///
/// Instead of duplicating terminal size queries across components, use this
/// centralized utility:
///
/// ```dart
/// final cols = TerminalInfo.columns;
/// final rows = TerminalInfo.rows;
/// final size = TerminalInfo.size;
/// ```
///
/// **Why centralize?**
/// - Consistent fallback defaults (80×24)
/// - Single point for error handling
/// - Easy to test/mock
/// - Reduces boilerplate in views and prompts
class TerminalInfo {
  /// Default fallback width when terminal is unavailable.
  static const int defaultColumns = 80;

  /// Default fallback height when terminal is unavailable.
  static const int defaultRows = 24;

  /// Returns the current terminal width in columns.
  ///
  /// Falls back to [defaultColumns] if:
  /// - No terminal is attached
  /// - An error occurs querying the terminal
  static int get columns {
    try {
      if (stdout.hasTerminal) return stdout.terminalColumns;
    } catch (_) {}
    return defaultColumns;
  }

  /// Returns the current terminal height in rows.
  ///
  /// Falls back to [defaultRows] if:
  /// - No terminal is attached
  /// - An error occurs querying the terminal
  static int get rows {
    try {
      if (stdout.hasTerminal) return stdout.terminalLines;
    } catch (_) {}
    return defaultRows;
  }

  /// Returns both dimensions as a record.
  ///
  /// Usage:
  /// ```dart
  /// final (:columns, :rows) = TerminalInfo.size;
  /// ```
  static ({int columns, int rows}) get size => (columns: columns, rows: rows);

  /// Whether a terminal is available.
  static bool get hasTerminal {
    try {
      return stdout.hasTerminal;
    } catch (_) {
      return false;
    }
  }
}
