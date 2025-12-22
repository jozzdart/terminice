import 'dart:io' show sleep;

import 'terminal_context.dart';

/// Terminal utilities used across components and prompts to manage raw mode and input.
class TerminalControl {
  /// Puts stdin into raw mode (no echo, no line buffering) and returns
  /// a [TerminalModeState] that can be used to restore the original settings.
  static TerminalModeState enterRaw() {
    final input = TerminalContext.input;
    final origEcho = input.echoMode;
    final origLineMode = input.lineMode;
    input.echoMode = false;
    input.lineMode = false;
    return TerminalModeState(origEcho: origEcho, origLineMode: origLineMode);
  }

  /// Attempts to read the next byte for multi-byte escape sequences.
  ///
  /// The optional [delay] gives the terminal a moment to deliver additional
  /// bytes (default 2ms). Returns null if no byte is available.
  static int? tryReadNextByte(
      {Duration delay = const Duration(milliseconds: 2)}) {
    try {
      sleep(delay);
      if (TerminalContext.input.hasTerminal) {
        return TerminalContext.input.readByteSync();
      }
    } catch (_) {}
    return null;
  }

  /// Clears the screen and moves cursor to home position.
  static void clearAndHome() {
    final output = TerminalContext.output;
    output.write('\x1B[2J');
    output.write('\x1B[H');
  }

  /// Hides the cursor.
  static void hideCursor() {
    TerminalContext.output.write('\x1B[?25l');
  }

  /// Shows the cursor.
  static void showCursor() {
    TerminalContext.output.write('\x1B[?25h');
  }
}

/// Captures original terminal state and restores it on [restore].
class TerminalModeState {
  final bool origEcho;
  final bool origLineMode;

  TerminalModeState({required this.origEcho, required this.origLineMode});

  /// Restores the terminal's echo and line mode flags to their original values.
  ///
  /// Safe to call multiple times; best-effort guards prevent throwing if the
  /// terminal becomes unavailable between enter/restore calls.
  void restore() {
    try {
      if (!TerminalContext.input.hasTerminal) return;
    } catch (_) {
      return;
    }
    try {
      TerminalContext.input.echoMode = origEcho;
    } catch (_) {}
    try {
      TerminalContext.input.lineMode = origLineMode;
    } catch (_) {}
  }
}
