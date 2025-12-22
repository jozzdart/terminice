/// Abstract terminal interface for I/O operations.
///
/// This abstraction allows external users to provide their own stdin/stdout
/// for testing, alternative terminal implementations, or custom environments.
///
/// **Usage:**
/// ```dart
/// // Implement Terminal for custom behavior
/// class MyTerminal implements Terminal {
///   @override
///   TerminalInput get input => MyTerminalInput();
///
///   @override
///   TerminalOutput get output => MyTerminalOutput();
/// }
///
/// // Set as the current terminal
/// TerminalContext.current = MyTerminal();
/// ```
///
/// **Design principles:**
/// - Separation of input and output for partial customization
/// - Mirror dart:io stdin/stdout APIs for easy implementation
/// - No behavior changes from existing code
abstract class Terminal {
  /// The input stream for reading key events and managing terminal modes.
  TerminalInput get input;

  /// The output stream for writing content and querying terminal dimensions.
  TerminalOutput get output;
}

/// Abstract input interface for terminal operations.
///
/// Mirrors the relevant parts of dart:io's `Stdin` class.
/// Implementations should handle:
/// - Terminal mode management (echo, line mode)
/// - Synchronous byte reading for key events
/// - Terminal availability checking
abstract class TerminalInput {
  /// Whether a terminal is attached to stdin.
  bool get hasTerminal;

  /// Whether input characters are echoed to output.
  ///
  /// In raw mode, this should be `false` to prevent double-printing.
  bool get echoMode;

  /// Sets the echo mode.
  set echoMode(bool value);

  /// Whether input is line-buffered.
  ///
  /// In raw mode, this should be `false` for immediate character access.
  bool get lineMode;

  /// Sets the line mode.
  set lineMode(bool value);

  /// Reads a single byte synchronously from input.
  ///
  /// This is the primary method used for key event reading.
  /// Blocks until a byte is available.
  int readByteSync();
}

/// Abstract output interface for terminal operations.
///
/// Mirrors the relevant parts of dart:io's `Stdout` class.
/// Implementations should handle:
/// - Text output (with and without newlines)
/// - Terminal dimension queries
/// - Terminal availability checking
abstract class TerminalOutput {
  /// Whether a terminal is attached to stdout.
  bool get hasTerminal;

  /// The number of columns in the terminal.
  ///
  /// Returns a default value if terminal is not available.
  int get terminalColumns;

  /// The number of lines (rows) in the terminal.
  ///
  /// Returns a default value if terminal is not available.
  int get terminalLines;

  /// Writes an object to the output without a trailing newline.
  ///
  /// Used for ANSI escape sequences and inline content.
  void write(Object? object);

  /// Writes an object to the output followed by a newline.
  ///
  /// Used for complete lines of content.
  void writeln([Object? object = '']);
}
