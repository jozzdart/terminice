import 'dart:convert';
import 'dart:io';

import 'terminal_control.dart';

/// Normalized terminal key event types.
///
/// These cover common control keys, arrows, printable characters, and
/// unknown bytes. Use with `KeyEvent` for prompt and view input handling.
enum KeyEventType {
  enter,
  esc,
  ctrlC,
  ctrlR,
  ctrlD,
  ctrlE,
  ctrlGeneric,
  tab,
  arrowUp,
  arrowDown,
  arrowLeft,
  arrowRight,
  backspace,
  space,
  slash,
  char,
  unknown,
}

/// Normalized key event captured from terminal input.
///
/// The representation intentionally stays tiny—just an event [type] plus an
/// optional [char] payload for printable or generic control keys. This keeps
/// serialization trivial and ergonomic when piping events between isolates.
class KeyEvent {
  /// Parsed event classification.
  final KeyEventType type;

  /// Printable character, or the lowercase letter that was combined with Ctrl
  /// for `ctrlGeneric` events (e.g. `^A` → `a`). Null for keys without a
  /// character payload.
  final String? char;

  const KeyEvent(this.type, [this.char]);
}

/// Synchronous key event reader for raw terminal input.
///
/// Wraps `stdin.readByteSync`, interprets multi-byte escape sequences, and
/// emits normalized [KeyEvent] instances. Works in tandem with
/// [TerminalControl.enterRaw] / [TerminalModeState] so prompts can switch in
/// and out of raw mode safely.
class KeyEventReader {
  /// Reads the next key event from stdin.
  ///
  /// Expects stdin to be in raw mode. For ESC-based sequences, briefly peeks
  /// ahead to differentiate a lone ESC from arrow keys or other CSI sequences.
  static KeyEvent read() {
    final byte = stdin.readByteSync();

    // Enter
    if (byte == 10 || byte == 13) return const KeyEvent(KeyEventType.enter);

    // Ctrl+C
    if (byte == 3) return const KeyEvent(KeyEventType.ctrlC);

    // Ctrl+R
    if (byte == 18) return const KeyEvent(KeyEventType.ctrlR);

    // Ctrl+D
    if (byte == 4) return const KeyEvent(KeyEventType.ctrlD);

    // Ctrl+E
    if (byte == 5) return const KeyEvent(KeyEventType.ctrlE);

    // Tab
    if (byte == 9) return const KeyEvent(KeyEventType.tab);

    // Generic Ctrl+[A-Z]
    if (byte >= 1 && byte <= 26) {
      final char = String.fromCharCode(byte + 96);
      return KeyEvent(KeyEventType.ctrlGeneric, char);
    }

    // Space
    if (byte == 32) return const KeyEvent(KeyEventType.space);

    // Slash
    if (byte == 47) return const KeyEvent(KeyEventType.slash);

    // Backspace
    if (byte == 127 || byte == 8) return const KeyEvent(KeyEventType.backspace);

    // ESC or Arrow Sequences
    if (byte == 27) {
      // Wait briefly to see if this is an escape sequence
      sleep(const Duration(milliseconds: 30));
      final next1 = TerminalControl.tryReadNextByte();
      final next2 = TerminalControl.tryReadNextByte();

      if (next1 == 91 && next2 != null) {
        switch (next2) {
          case 65:
            return const KeyEvent(KeyEventType.arrowUp);
          case 66:
            return const KeyEvent(KeyEventType.arrowDown);
          case 67:
            return const KeyEvent(KeyEventType.arrowRight);
          case 68:
            return const KeyEvent(KeyEventType.arrowLeft);
        }
      }

      // No following bytes → real ESC key
      return const KeyEvent(KeyEventType.esc);
    }

    // Printable char
    final ch = utf8.decode([byte], allowMalformed: true);
    if (RegExp(r'^[ -~]$').hasMatch(ch)) {
      return KeyEvent(KeyEventType.char, ch);
    }

    return const KeyEvent(KeyEventType.unknown);
  }
}
