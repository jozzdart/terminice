import 'dart:io' as io;

import 'terminal.dart';

/// Default Terminal implementation using dart:io stdin/stdout.
///
/// This is the standard implementation used when running in a real terminal.
/// It delegates directly to dart:io's `stdin` and `stdout` objects.
///
/// **Usage:**
/// ```dart
/// // This is the default - you typically don't need to create it manually
/// final terminal = DartTerminal();
///
/// // Access input/output
/// terminal.output.writeln('Hello');
/// final byte = terminal.input.readByteSync();
/// ```
class DartTerminal implements Terminal {
  late final DartTerminalInput _input;
  late final DartTerminalOutput _output;

  /// Creates a new DartTerminal using dart:io stdin/stdout.
  DartTerminal() {
    _input = DartTerminalInput();
    _output = DartTerminalOutput();
  }

  @override
  TerminalInput get input => _input;

  @override
  TerminalOutput get output => _output;
}

/// Default TerminalInput implementation using dart:io stdin.
class DartTerminalInput implements TerminalInput {
  @override
  bool get hasTerminal {
    try {
      return io.stdin.hasTerminal;
    } catch (_) {
      return false;
    }
  }

  @override
  bool get echoMode {
    try {
      return io.stdin.echoMode;
    } catch (_) {
      return true;
    }
  }

  @override
  set echoMode(bool value) {
    try {
      io.stdin.echoMode = value;
    } catch (_) {
      // Ignore if terminal is unavailable
    }
  }

  @override
  bool get lineMode {
    try {
      return io.stdin.lineMode;
    } catch (_) {
      return true;
    }
  }

  @override
  set lineMode(bool value) {
    try {
      io.stdin.lineMode = value;
    } catch (_) {
      // Ignore if terminal is unavailable
    }
  }

  @override
  int readByteSync() {
    return io.stdin.readByteSync();
  }
}

/// Default TerminalOutput implementation using dart:io stdout.
class DartTerminalOutput implements TerminalOutput {
  /// Default fallback width when terminal is unavailable.
  static const int defaultColumns = 80;

  /// Default fallback height when terminal is unavailable.
  static const int defaultLines = 24;

  @override
  bool get hasTerminal {
    try {
      return io.stdout.hasTerminal;
    } catch (_) {
      return false;
    }
  }

  @override
  int get terminalColumns {
    try {
      if (io.stdout.hasTerminal) {
        return io.stdout.terminalColumns;
      }
    } catch (_) {}
    return defaultColumns;
  }

  @override
  int get terminalLines {
    try {
      if (io.stdout.hasTerminal) {
        return io.stdout.terminalLines;
      }
    } catch (_) {}
    return defaultLines;
  }

  @override
  void write(Object? object) {
    io.stdout.write(object);
  }

  @override
  void writeln([Object? object = '']) {
    io.stdout.writeln(object);
  }
}
