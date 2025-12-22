import 'dart_terminal.dart';
import 'terminal.dart';

/// Global context for accessing the current Terminal instance.
///
/// Provides a centralized access point for terminal I/O operations,
/// allowing external users to replace the default implementation with
/// their own for testing or alternative environments.
///
/// **Usage:**
/// ```dart
/// // Get the current terminal (creates default DartTerminal on first access)
/// final terminal = TerminalContext.current;
///
/// // Write output
/// TerminalContext.current.output.writeln('Hello');
///
/// // Read input
/// final byte = TerminalContext.current.input.readByteSync();
///
/// // Set a custom terminal (for testing)
/// TerminalContext.current = MyCustomTerminal();
///
/// // Reset to default dart:io terminal
/// TerminalContext.reset();
/// ```
///
/// **Testing example:**
/// ```dart
/// class TestTerminal implements Terminal {
///   final outputBuffer = StringBuffer();
///   final inputQueue = <int>[];
///
///   @override
///   TerminalInput get input => TestInput(inputQueue);
///
///   @override
///   TerminalOutput get output => TestOutput(outputBuffer);
/// }
///
/// void main() {
///   final testTerminal = TestTerminal();
///   TerminalContext.current = testTerminal;
///
///   // Run prompts - all output goes to testTerminal.outputBuffer
///   // All input reads from testTerminal.inputQueue
///
///   TerminalContext.reset(); // Restore default
/// }
/// ```
///
/// **Design notes:**
/// - Lazy initialization: Default DartTerminal created on first access
/// - Thread-safe: Single static instance (Dart is single-threaded)
/// - No breaking changes: Existing code continues to work unchanged
class TerminalContext {
  static Terminal? _instance;

  // Private constructor to prevent instantiation
  TerminalContext._();

  /// The current terminal instance.
  ///
  /// Returns the custom terminal if one has been set via the setter,
  /// otherwise returns a lazily-created [DartTerminal].
  static Terminal get current => _instance ??= DartTerminal();

  /// Sets a custom terminal instance.
  ///
  /// Use this to inject a test terminal or alternative implementation.
  /// Pass `null` to reset to default (equivalent to calling [reset]).
  static set current(Terminal? terminal) => _instance = terminal;

  /// Resets to the default dart:io terminal.
  ///
  /// The next access to [current] will create a new [DartTerminal].
  static void reset() => _instance = null;

  /// Whether a custom terminal has been set.
  ///
  /// Returns `false` if using the default DartTerminal or if
  /// the terminal hasn't been accessed yet.
  static bool get hasCustomTerminal => _instance != null;

  // ──────────────────────────────────────────────────────────────────────────
  // CONVENIENCE ACCESSORS
  // ──────────────────────────────────────────────────────────────────────────

  /// Shortcut to the current terminal's input.
  static TerminalInput get input => current.input;

  /// Shortcut to the current terminal's output.
  static TerminalOutput get output => current.output;
}

