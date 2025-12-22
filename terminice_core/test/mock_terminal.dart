import 'package:terminice_core/terminice_core.dart';

/// A mock terminal implementation for testing.
///
/// Captures all output and allows queuing input bytes/lines for testing
/// interactive prompts without a real terminal.
class MockTerminal implements Terminal {
  late final MockTerminalInput _input;
  late final MockTerminalOutput _output;

  MockTerminal() {
    _input = MockTerminalInput();
    _output = MockTerminalOutput();
  }

  @override
  TerminalInput get input => _input;

  @override
  TerminalOutput get output => _output;

  /// Access to the mock input for test setup.
  MockTerminalInput get mockInput => _input;

  /// Access to the mock output for assertions.
  MockTerminalOutput get mockOutput => _output;

  /// Resets both input queue and output buffer.
  void reset() {
    _input.reset();
    _output.reset();
  }
}

/// Mock input that allows queuing bytes and lines for testing.
class MockTerminalInput implements TerminalInput {
  final List<int> _byteQueue = [];
  final List<String> _lineQueue = [];
  bool _echoMode = true;
  bool _lineMode = true;
  bool _hasTerminal = true;

  /// Queue bytes to be returned by [readByteSync].
  void queueBytes(List<int> bytes) {
    _byteQueue.addAll(bytes);
  }

  /// Queue a single byte.
  void queueByte(int byte) {
    _byteQueue.add(byte);
  }

  /// Queue a string as bytes (UTF-8).
  void queueString(String str) {
    _byteQueue.addAll(str.codeUnits);
  }

  /// Queue key events by type.
  void queueKey(KeyEventType type, [String? char]) {
    switch (type) {
      case KeyEventType.enter:
        queueByte(13);
        break;
      case KeyEventType.esc:
        queueByte(27);
        break;
      case KeyEventType.ctrlC:
        queueByte(3);
        break;
      case KeyEventType.ctrlR:
        queueByte(18);
        break;
      case KeyEventType.ctrlD:
        queueByte(4);
        break;
      case KeyEventType.ctrlE:
        queueByte(5);
        break;
      case KeyEventType.tab:
        queueByte(9);
        break;
      case KeyEventType.arrowUp:
        queueBytes([27, 91, 65]);
        break;
      case KeyEventType.arrowDown:
        queueBytes([27, 91, 66]);
        break;
      case KeyEventType.arrowRight:
        queueBytes([27, 91, 67]);
        break;
      case KeyEventType.arrowLeft:
        queueBytes([27, 91, 68]);
        break;
      case KeyEventType.backspace:
        queueByte(127);
        break;
      case KeyEventType.space:
        queueByte(32);
        break;
      case KeyEventType.slash:
        queueByte(47);
        break;
      case KeyEventType.char:
        if (char != null && char.isNotEmpty) {
          queueByte(char.codeUnitAt(0));
        }
        break;
      case KeyEventType.ctrlGeneric:
        if (char != null && char.isNotEmpty) {
          final code = char.toLowerCase().codeUnitAt(0) - 96;
          queueByte(code);
        }
        break;
      case KeyEventType.unknown:
        queueByte(0);
        break;
    }
  }

  /// Queue a line to be returned by [readLineSync].
  void queueLine(String line) {
    _lineQueue.add(line);
  }

  /// Queue multiple lines.
  void queueLines(List<String> lines) {
    _lineQueue.addAll(lines);
  }

  /// Set whether terminal is available.
  void setHasTerminal(bool value) {
    _hasTerminal = value;
  }

  /// Reset the input state.
  void reset() {
    _byteQueue.clear();
    _lineQueue.clear();
    _echoMode = true;
    _lineMode = true;
    _hasTerminal = true;
  }

  /// Number of bytes remaining in queue.
  int get bytesRemaining => _byteQueue.length;

  /// Number of lines remaining in queue.
  int get linesRemaining => _lineQueue.length;

  @override
  bool get hasTerminal => _hasTerminal;

  @override
  bool get echoMode => _echoMode;

  @override
  set echoMode(bool value) => _echoMode = value;

  @override
  bool get lineMode => _lineMode;

  @override
  set lineMode(bool value) => _lineMode = value;

  @override
  int readByteSync() {
    if (_byteQueue.isEmpty) {
      throw StateError('MockTerminalInput: No bytes queued for readByteSync');
    }
    return _byteQueue.removeAt(0);
  }

  @override
  String? readLineSync() {
    if (_lineQueue.isEmpty) {
      return null;
    }
    return _lineQueue.removeAt(0);
  }
}

/// Mock output that captures all written content for assertions.
class MockTerminalOutput implements TerminalOutput {
  final StringBuffer _buffer = StringBuffer();
  final List<String> _lines = [];
  final List<String> _writes = [];
  bool _hasTerminal = true;
  int _columns = 80;
  int _rows = 24;

  /// All output as a single string.
  String get allOutput => _buffer.toString();

  /// All individual write() calls.
  List<String> get writes => List.unmodifiable(_writes);

  /// All individual writeln() calls (including the content).
  List<String> get lines => List.unmodifiable(_lines);

  /// Number of write() calls made.
  int get writeCount => _writes.length;

  /// Number of writeln() calls made.
  int get lineCount => _lines.length;

  /// Check if output contains a string.
  bool contains(String text) => _buffer.toString().contains(text);

  /// Check if output contains a pattern.
  bool containsPattern(Pattern pattern) =>
      pattern.allMatches(_buffer.toString()).isNotEmpty;

  /// Set terminal dimensions.
  void setDimensions({int? columns, int? rows}) {
    if (columns != null) _columns = columns;
    if (rows != null) _rows = rows;
  }

  /// Set whether terminal is available.
  void setHasTerminal(bool value) {
    _hasTerminal = value;
  }

  /// Reset all output.
  void reset() {
    _buffer.clear();
    _lines.clear();
    _writes.clear();
    _hasTerminal = true;
    _columns = 80;
    _rows = 24;
  }

  @override
  bool get hasTerminal => _hasTerminal;

  @override
  int get terminalColumns => _columns;

  @override
  int get terminalLines => _rows;

  @override
  void write(Object? object) {
    final str = object?.toString() ?? '';
    _buffer.write(str);
    _writes.add(str);
  }

  @override
  void writeln([Object? object = '']) {
    final str = object?.toString() ?? '';
    _buffer.writeln(str);
    _lines.add(str);
  }
}

/// A terminal that tracks method calls for verification.
class SpyTerminal implements Terminal {
  final List<String> _calls = [];
  late final SpyTerminalInput _input;
  late final SpyTerminalOutput _output;

  SpyTerminal() {
    _input = SpyTerminalInput(_calls);
    _output = SpyTerminalOutput(_calls);
  }

  @override
  TerminalInput get input => _input;

  @override
  TerminalOutput get output => _output;

  /// All method calls made to this terminal.
  List<String> get calls => List.unmodifiable(_calls);

  /// Check if a method was called.
  bool wasCalled(String method) => _calls.contains(method);

  /// Count how many times a method was called.
  int callCount(String method) => _calls.where((c) => c == method).length;

  /// Reset call history.
  void reset() {
    _calls.clear();
  }
}

class SpyTerminalInput implements TerminalInput {
  final List<String> _calls;
  bool _echoMode = true;
  bool _lineMode = true;

  SpyTerminalInput(this._calls);

  @override
  bool get hasTerminal {
    _calls.add('input.hasTerminal');
    return true;
  }

  @override
  bool get echoMode {
    _calls.add('input.echoMode.get');
    return _echoMode;
  }

  @override
  set echoMode(bool value) {
    _calls.add('input.echoMode.set');
    _echoMode = value;
  }

  @override
  bool get lineMode {
    _calls.add('input.lineMode.get');
    return _lineMode;
  }

  @override
  set lineMode(bool value) {
    _calls.add('input.lineMode.set');
    _lineMode = value;
  }

  @override
  int readByteSync() {
    _calls.add('input.readByteSync');
    return 13; // Enter key
  }

  @override
  String? readLineSync() {
    _calls.add('input.readLineSync');
    return 'test';
  }
}

class SpyTerminalOutput implements TerminalOutput {
  final List<String> _calls;

  SpyTerminalOutput(this._calls);

  @override
  bool get hasTerminal {
    _calls.add('output.hasTerminal');
    return true;
  }

  @override
  int get terminalColumns {
    _calls.add('output.terminalColumns');
    return 80;
  }

  @override
  int get terminalLines {
    _calls.add('output.terminalLines');
    return 24;
  }

  @override
  void write(Object? object) {
    _calls.add('output.write');
  }

  @override
  void writeln([Object? object = '']) {
    _calls.add('output.writeln');
  }
}

/// A terminal that always throws to test error handling.
class ErrorTerminal implements Terminal {
  @override
  TerminalInput get input => ErrorTerminalInput();

  @override
  TerminalOutput get output => ErrorTerminalOutput();
}

class ErrorTerminalInput implements TerminalInput {
  @override
  bool get hasTerminal => throw Exception('ErrorTerminal: hasTerminal');

  @override
  bool get echoMode => throw Exception('ErrorTerminal: echoMode get');

  @override
  set echoMode(bool value) => throw Exception('ErrorTerminal: echoMode set');

  @override
  bool get lineMode => throw Exception('ErrorTerminal: lineMode get');

  @override
  set lineMode(bool value) => throw Exception('ErrorTerminal: lineMode set');

  @override
  int readByteSync() => throw Exception('ErrorTerminal: readByteSync');

  @override
  String? readLineSync() => throw Exception('ErrorTerminal: readLineSync');
}

class ErrorTerminalOutput implements TerminalOutput {
  @override
  bool get hasTerminal => throw Exception('ErrorTerminal: hasTerminal');

  @override
  int get terminalColumns => throw Exception('ErrorTerminal: terminalColumns');

  @override
  int get terminalLines => throw Exception('ErrorTerminal: terminalLines');

  @override
  void write(Object? object) => throw Exception('ErrorTerminal: write');

  @override
  void writeln([Object? object = '']) =>
      throw Exception('ErrorTerminal: writeln');
}

