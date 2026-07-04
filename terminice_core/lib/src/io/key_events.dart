import 'dart:convert';
import 'dart:io' show sleep;

import 'terminal.dart';
import 'terminal_context.dart';
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
/// Wraps `TerminalContext.input.readByteSync`, interprets multi-byte escape sequences, and
/// emits normalized [KeyEvent] instances. Works in tandem with
/// [TerminalControl.enterRaw] / [TerminalModeState] so prompts can switch in
/// and out of raw mode safely.
class KeyEventReader {
  static int? _pendingByte;
  static Terminal? _pendingTerminal;

  /// Reads the next key event from stdin.
  ///
  /// Expects stdin to be in raw mode. For ESC-based sequences, briefly peeks
  /// ahead to differentiate a lone ESC from arrow keys or other CSI sequences.
  static KeyEvent read() {
    final terminal = TerminalContext.current;
    final byte = _readByte(terminal);

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
    final ch = _readUtf8Character(terminal, byte);
    if (ch != null && _isPrintableCharacter(ch)) {
      return KeyEvent(KeyEventType.char, ch);
    }

    return const KeyEvent(KeyEventType.unknown);
  }

  static int _readByte(Terminal terminal) {
    final pendingByte = _pendingByte;
    if (pendingByte != null) {
      if (identical(_pendingTerminal, terminal)) {
        _pendingByte = null;
        _pendingTerminal = null;
        return pendingByte;
      }
      _pendingByte = null;
      _pendingTerminal = null;
    }

    return terminal.input.readByteSync();
  }

  static void _replayByte(Terminal terminal, int byte) {
    _pendingByte = byte;
    _pendingTerminal = terminal;
  }

  static String? _readUtf8Character(Terminal terminal, int firstByte) {
    if (firstByte < 0 || firstByte > 0xFF) return null;

    if (firstByte < 0x80) {
      return String.fromCharCode(firstByte);
    }

    final sequenceLength = _utf8SequenceLength(firstByte);
    if (sequenceLength == null) return null;

    final bytes = <int>[firstByte];
    try {
      for (var i = 1; i < sequenceLength; i++) {
        final nextByte = terminal.input.readByteSync();
        if (!_isUtf8ContinuationByte(nextByte)) {
          _replayByte(terminal, nextByte);
          return null;
        }
        bytes.add(nextByte);
      }
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }

  static int? _utf8SequenceLength(int firstByte) {
    if (firstByte >= 0xC2 && firstByte <= 0xDF) return 2;
    if (firstByte >= 0xE0 && firstByte <= 0xEF) return 3;
    if (firstByte >= 0xF0 && firstByte <= 0xF4) return 4;
    return null;
  }

  static bool _isUtf8ContinuationByte(int byte) {
    return byte >= 0x80 && byte <= 0xBF;
  }

  static bool _isPrintableCharacter(String char) {
    if (char.isEmpty) return false;

    for (final rune in char.runes) {
      if (rune < 0x20 || (rune >= 0x7F && rune <= 0x9F)) {
        return false;
      }
    }

    return true;
  }
}
