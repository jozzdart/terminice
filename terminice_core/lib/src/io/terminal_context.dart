import 'dart:async';

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

  /// Whether the terminal context currently holds an initialized terminal.
  ///
  /// This is `false` before [current] is first accessed or after [reset]. It is
  /// `true` after either setting [current] directly or reading [current], which
  /// lazily creates the default [DartTerminal].
  static bool get hasInitializedTerminal => _instance != null;

  /// Whether the terminal context currently holds an initialized terminal.
  ///
  /// This historical name is kept for compatibility. It does not distinguish a
  /// caller-provided terminal from the lazily-created default [DartTerminal];
  /// use [hasInitializedTerminal] when you need the precise meaning.
  static bool get hasCustomTerminal => hasInitializedTerminal;

  /// Captures the current initialized/uninitialized terminal context.
  ///
  /// Unlike reading [current], capture does not create a default [DartTerminal]
  /// when the context is uninitialized.
  static TerminalContextSnapshot capture() {
    return TerminalContextSnapshot._(_instance);
  }

  /// Runs [body] with [terminal] installed as [current].
  ///
  /// The previous context is restored when [body] returns or throws. If the
  /// context was uninitialized before this call, it is restored to that same
  /// uninitialized state.
  static T runWith<T>(Terminal terminal, T Function() body) {
    final previous = capture();
    current = terminal;
    try {
      return body();
    } finally {
      previous.restore();
    }
  }

  /// Runs asynchronous [body] with [terminal] installed as [current].
  ///
  /// The previous context is restored after [body]'s result completes, whether
  /// it succeeds or fails. Synchronous throws are captured and still restore the
  /// previous context before the returned future completes with the error.
  static Future<T> runWithAsync<T>(
    Terminal terminal,
    FutureOr<T> Function() body,
  ) async {
    final previous = capture();
    current = terminal;
    try {
      return await Future<T>.sync(body);
    } finally {
      previous.restore();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CONVENIENCE ACCESSORS
  // ──────────────────────────────────────────────────────────────────────────

  /// Shortcut to the current terminal's input.
  static TerminalInput get input => current.input;

  /// Shortcut to the current terminal's output.
  static TerminalOutput get output => current.output;
}

/// A restorable snapshot of [TerminalContext]'s terminal slot.
///
/// Snapshots record whether the context had an initialized terminal at capture
/// time. Restoring a snapshot captured before [TerminalContext.current] was
/// first accessed resets the context back to the same uninitialized state.
class TerminalContextSnapshot {
  /// Whether [TerminalContext] held an initialized terminal at capture time.
  final bool hadInitializedTerminal;

  /// The terminal that was active at capture time, or `null` if uninitialized.
  final Terminal? terminal;

  TerminalContextSnapshot._(Terminal? capturedTerminal)
      : hadInitializedTerminal = capturedTerminal != null,
        terminal = capturedTerminal;

  /// Restores the captured terminal context.
  void restore() {
    if (hadInitializedTerminal) {
      TerminalContext.current = terminal;
    } else {
      TerminalContext.reset();
    }
  }
}
