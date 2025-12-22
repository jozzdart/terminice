import 'package:test/test.dart';
import 'package:terminice_core/terminice_core.dart';

import 'mock_terminal.dart';

void main() {
  group('Terminal Interface', () {
    test('Terminal has input and output properties', () {
      final terminal = DartTerminal();
      expect(terminal.input, isA<TerminalInput>());
      expect(terminal.output, isA<TerminalOutput>());
    });

    test('TerminalInput interface has required methods', () {
      final input = DartTerminal().input;
      expect(() => input.hasTerminal, returnsNormally);
      expect(() => input.echoMode, returnsNormally);
      expect(() => input.lineMode, returnsNormally);
    });

    test('TerminalOutput interface has required methods', () {
      final output = DartTerminal().output;
      expect(() => output.hasTerminal, returnsNormally);
      expect(() => output.terminalColumns, returnsNormally);
      expect(() => output.terminalLines, returnsNormally);
    });
  });

  group('MockTerminal', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
    });

    test('creates with input and output', () {
      expect(terminal.input, isA<MockTerminalInput>());
      expect(terminal.output, isA<MockTerminalOutput>());
    });

    test('mockInput and mockOutput accessors work', () {
      expect(terminal.mockInput, same(terminal.input));
      expect(terminal.mockOutput, same(terminal.output));
    });

    test('reset clears both input and output', () {
      terminal.mockInput.queueByte(65);
      terminal.mockOutput.write('test');

      terminal.reset();

      expect(terminal.mockInput.bytesRemaining, equals(0));
      expect(terminal.mockOutput.allOutput, isEmpty);
    });
  });

  group('MockTerminalInput', () {
    late MockTerminalInput input;

    setUp(() {
      input = MockTerminalInput();
    });

    test('queueBytes adds bytes to queue', () {
      input.queueBytes([65, 66, 67]);
      expect(input.bytesRemaining, equals(3));
      expect(input.readByteSync(), equals(65));
      expect(input.readByteSync(), equals(66));
      expect(input.readByteSync(), equals(67));
    });

    test('queueByte adds single byte', () {
      input.queueByte(65);
      expect(input.bytesRemaining, equals(1));
      expect(input.readByteSync(), equals(65));
    });

    test('queueString adds string as bytes', () {
      input.queueString('AB');
      expect(input.readByteSync(), equals(65));
      expect(input.readByteSync(), equals(66));
    });

    test('queueKey queues enter key', () {
      input.queueKey(KeyEventType.enter);
      expect(input.readByteSync(), equals(13));
    });

    test('queueKey queues escape key', () {
      input.queueKey(KeyEventType.esc);
      expect(input.readByteSync(), equals(27));
    });

    test('queueKey queues ctrl+c', () {
      input.queueKey(KeyEventType.ctrlC);
      expect(input.readByteSync(), equals(3));
    });

    test('queueKey queues arrow keys as escape sequences', () {
      input.queueKey(KeyEventType.arrowUp);
      expect(input.readByteSync(), equals(27));
      expect(input.readByteSync(), equals(91));
      expect(input.readByteSync(), equals(65));
    });

    test('queueKey queues character', () {
      input.queueKey(KeyEventType.char, 'a');
      expect(input.readByteSync(), equals(97));
    });

    test('queueLine adds line to queue', () {
      input.queueLine('hello');
      expect(input.linesRemaining, equals(1));
      expect(input.readLineSync(), equals('hello'));
    });

    test('queueLines adds multiple lines', () {
      input.queueLines(['one', 'two', 'three']);
      expect(input.linesRemaining, equals(3));
      expect(input.readLineSync(), equals('one'));
      expect(input.readLineSync(), equals('two'));
      expect(input.readLineSync(), equals('three'));
    });

    test('readLineSync returns null when queue is empty', () {
      expect(input.readLineSync(), isNull);
    });

    test('readByteSync throws when queue is empty', () {
      expect(() => input.readByteSync(), throwsStateError);
    });

    test('echoMode can be get and set', () {
      expect(input.echoMode, isTrue);
      input.echoMode = false;
      expect(input.echoMode, isFalse);
    });

    test('lineMode can be get and set', () {
      expect(input.lineMode, isTrue);
      input.lineMode = false;
      expect(input.lineMode, isFalse);
    });

    test('hasTerminal can be configured', () {
      expect(input.hasTerminal, isTrue);
      input.setHasTerminal(false);
      expect(input.hasTerminal, isFalse);
    });

    test('reset clears all state', () {
      input.queueByte(65);
      input.queueLine('test');
      input.echoMode = false;
      input.lineMode = false;
      input.setHasTerminal(false);

      input.reset();

      expect(input.bytesRemaining, equals(0));
      expect(input.linesRemaining, equals(0));
      expect(input.echoMode, isTrue);
      expect(input.lineMode, isTrue);
      expect(input.hasTerminal, isTrue);
    });
  });

  group('MockTerminalOutput', () {
    late MockTerminalOutput output;

    setUp(() {
      output = MockTerminalOutput();
    });

    test('write captures output', () {
      output.write('hello');
      expect(output.allOutput, equals('hello'));
      expect(output.writes, equals(['hello']));
    });

    test('writeln captures output with newline', () {
      output.writeln('hello');
      expect(output.allOutput, equals('hello\n'));
      expect(output.lines, equals(['hello']));
    });

    test('multiple writes are concatenated', () {
      output.write('hello');
      output.write(' ');
      output.write('world');
      expect(output.allOutput, equals('hello world'));
      expect(output.writeCount, equals(3));
    });

    test('contains checks for substring', () {
      output.write('hello world');
      expect(output.contains('world'), isTrue);
      expect(output.contains('foo'), isFalse);
    });

    test('containsPattern checks for pattern', () {
      output.write('hello123world');
      expect(output.containsPattern(RegExp(r'\d+')), isTrue);
      expect(output.containsPattern(RegExp(r'^hello')), isTrue);
    });

    test('dimensions can be configured', () {
      expect(output.terminalColumns, equals(80));
      expect(output.terminalLines, equals(24));

      output.setDimensions(columns: 120, rows: 40);

      expect(output.terminalColumns, equals(120));
      expect(output.terminalLines, equals(40));
    });

    test('hasTerminal can be configured', () {
      expect(output.hasTerminal, isTrue);
      output.setHasTerminal(false);
      expect(output.hasTerminal, isFalse);
    });

    test('reset clears all state', () {
      output.write('test');
      output.writeln('line');
      output.setDimensions(columns: 100, rows: 50);
      output.setHasTerminal(false);

      output.reset();

      expect(output.allOutput, isEmpty);
      expect(output.writes, isEmpty);
      expect(output.lines, isEmpty);
      expect(output.terminalColumns, equals(80));
      expect(output.terminalLines, equals(24));
      expect(output.hasTerminal, isTrue);
    });
  });

  group('SpyTerminal', () {
    late SpyTerminal terminal;

    setUp(() {
      terminal = SpyTerminal();
    });

    test('tracks input method calls', () {
      terminal.input.hasTerminal;
      terminal.input.echoMode;
      terminal.input.echoMode = true;
      terminal.input.lineMode;
      terminal.input.lineMode = true;
      terminal.input.readByteSync();
      terminal.input.readLineSync();

      expect(terminal.calls, contains('input.hasTerminal'));
      expect(terminal.calls, contains('input.echoMode.get'));
      expect(terminal.calls, contains('input.echoMode.set'));
      expect(terminal.calls, contains('input.lineMode.get'));
      expect(terminal.calls, contains('input.lineMode.set'));
      expect(terminal.calls, contains('input.readByteSync'));
      expect(terminal.calls, contains('input.readLineSync'));
    });

    test('tracks output method calls', () {
      terminal.output.hasTerminal;
      terminal.output.terminalColumns;
      terminal.output.terminalLines;
      terminal.output.write('test');
      terminal.output.writeln('line');

      expect(terminal.calls, contains('output.hasTerminal'));
      expect(terminal.calls, contains('output.terminalColumns'));
      expect(terminal.calls, contains('output.terminalLines'));
      expect(terminal.calls, contains('output.write'));
      expect(terminal.calls, contains('output.writeln'));
    });

    test('wasCalled checks for method call', () {
      terminal.output.write('test');
      expect(terminal.wasCalled('output.write'), isTrue);
      expect(terminal.wasCalled('output.writeln'), isFalse);
    });

    test('callCount counts method calls', () {
      terminal.output.write('a');
      terminal.output.write('b');
      terminal.output.write('c');

      expect(terminal.callCount('output.write'), equals(3));
    });

    test('reset clears call history', () {
      terminal.output.write('test');
      terminal.reset();
      expect(terminal.calls, isEmpty);
    });
  });

  group('TerminalContext', () {
    setUp(() {
      // Reset to clean state before each test
      TerminalContext.reset();
    });

    tearDown(() {
      // Clean up after each test
      TerminalContext.reset();
    });

    test('current returns DartTerminal by default', () {
      expect(TerminalContext.current, isA<DartTerminal>());
    });

    test('current can be set to custom terminal', () {
      final mock = MockTerminal();
      TerminalContext.current = mock;
      expect(TerminalContext.current, same(mock));
    });

    test('reset returns to default DartTerminal', () {
      final mock = MockTerminal();
      TerminalContext.current = mock;

      TerminalContext.reset();

      expect(TerminalContext.current, isA<DartTerminal>());
      expect(TerminalContext.current, isNot(same(mock)));
    });

    test('input shortcut returns current terminal input', () {
      final mock = MockTerminal();
      TerminalContext.current = mock;
      expect(TerminalContext.input, same(mock.input));
    });

    test('output shortcut returns current terminal output', () {
      final mock = MockTerminal();
      TerminalContext.current = mock;
      expect(TerminalContext.output, same(mock.output));
    });

    test('hasCustomTerminal returns false before first access', () {
      TerminalContext.reset();
      expect(TerminalContext.hasCustomTerminal, isFalse);
    });

    test('hasCustomTerminal returns true after accessing current', () {
      TerminalContext.reset();
      TerminalContext.current; // triggers lazy init
      expect(TerminalContext.hasCustomTerminal, isTrue);
    });

    test('hasCustomTerminal returns true after setting custom', () {
      TerminalContext.current = MockTerminal();
      expect(TerminalContext.hasCustomTerminal, isTrue);
    });

    test('hasCustomTerminal returns false after reset', () {
      TerminalContext.current = MockTerminal();
      TerminalContext.reset();
      expect(TerminalContext.hasCustomTerminal, isFalse);
    });

    test('setting null resets to default', () {
      TerminalContext.current = MockTerminal();
      TerminalContext.current = null;
      expect(TerminalContext.current, isA<DartTerminal>());
    });
  });

  group('TerminalControl with MockTerminal', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
      TerminalContext.current = terminal;
    });

    tearDown(() {
      TerminalContext.reset();
    });

    test('enterRaw changes echo and line mode', () {
      expect(terminal.mockInput.echoMode, isTrue);
      expect(terminal.mockInput.lineMode, isTrue);

      final state = TerminalControl.enterRaw();

      expect(terminal.mockInput.echoMode, isFalse);
      expect(terminal.mockInput.lineMode, isFalse);

      state.restore();

      expect(terminal.mockInput.echoMode, isTrue);
      expect(terminal.mockInput.lineMode, isTrue);
    });

    test('hideCursor writes escape sequence', () {
      TerminalControl.hideCursor();
      expect(terminal.mockOutput.contains('\x1B[?25l'), isTrue);
    });

    test('showCursor writes escape sequence', () {
      TerminalControl.showCursor();
      expect(terminal.mockOutput.contains('\x1B[?25h'), isTrue);
    });

    test('clearAndHome writes escape sequences', () {
      TerminalControl.clearAndHome();
      expect(terminal.mockOutput.contains('\x1B[2J'), isTrue);
      expect(terminal.mockOutput.contains('\x1B[H'), isTrue);
    });
  });

  group('TerminalInfo with MockTerminal', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
      TerminalContext.current = terminal;
    });

    tearDown(() {
      TerminalContext.reset();
    });

    test('columns returns mock terminal columns', () {
      terminal.mockOutput.setDimensions(columns: 120);
      expect(TerminalInfo.columns, equals(120));
    });

    test('rows returns mock terminal rows', () {
      terminal.mockOutput.setDimensions(rows: 40);
      expect(TerminalInfo.rows, equals(40));
    });

    test('size returns both dimensions', () {
      terminal.mockOutput.setDimensions(columns: 100, rows: 50);
      final size = TerminalInfo.size;
      expect(size.columns, equals(100));
      expect(size.rows, equals(50));
    });

    test('hasTerminal returns mock value', () {
      expect(TerminalInfo.hasTerminal, isTrue);
      terminal.mockOutput.setHasTerminal(false);
      expect(TerminalInfo.hasTerminal, isFalse);
    });

    test('returns defaults when terminal unavailable', () {
      terminal.mockOutput.setHasTerminal(false);
      expect(TerminalInfo.columns, equals(TerminalInfo.defaultColumns));
      expect(TerminalInfo.rows, equals(TerminalInfo.defaultRows));
    });
  });

  group('RenderOutput with MockTerminal', () {
    late MockTerminal terminal;
    late RenderOutput output;

    setUp(() {
      terminal = MockTerminal();
      TerminalContext.current = terminal;
      output = RenderOutput();
    });

    tearDown(() {
      TerminalContext.reset();
    });

    test('writeln writes to terminal output', () {
      output.writeln('Hello');
      expect(terminal.mockOutput.contains('Hello'), isTrue);
    });

    test('write writes to terminal output', () {
      output.write('Test');
      expect(terminal.mockOutput.contains('Test'), isTrue);
    });

    test('clear writes escape sequences', () {
      output.writeln('Line 1');
      output.writeln('Line 2');
      output.clear();
      // Should have cursor up and clear sequences
      expect(terminal.mockOutput.contains('\x1B['), isTrue);
    });

    test('lineCount tracks written lines', () {
      expect(output.lineCount, equals(0));
      output.writeln('Line 1');
      expect(output.lineCount, equals(1));
      output.writeln('Line 2');
      expect(output.lineCount, equals(2));
    });

    test('clear resets lineCount', () {
      output.writeln('Line');
      output.clear();
      expect(output.lineCount, equals(0));
    });
  });

  group('KeyEventReader with MockTerminal', () {
    late MockTerminal terminal;

    setUp(() {
      terminal = MockTerminal();
      TerminalContext.current = terminal;
    });

    tearDown(() {
      TerminalContext.reset();
    });

    test('reads enter key', () {
      terminal.mockInput.queueKey(KeyEventType.enter);
      final event = KeyEventReader.read();
      expect(event.type, equals(KeyEventType.enter));
    });

    test('reads escape key', () {
      terminal.mockInput.queueByte(27);
      final event = KeyEventReader.read();
      expect(event.type, equals(KeyEventType.esc));
    });

    test('reads ctrl+c', () {
      terminal.mockInput.queueKey(KeyEventType.ctrlC);
      final event = KeyEventReader.read();
      expect(event.type, equals(KeyEventType.ctrlC));
    });

    test('reads space', () {
      terminal.mockInput.queueKey(KeyEventType.space);
      final event = KeyEventReader.read();
      expect(event.type, equals(KeyEventType.space));
    });

    test('reads character', () {
      terminal.mockInput.queueByte(97); // 'a'
      final event = KeyEventReader.read();
      expect(event.type, equals(KeyEventType.char));
      expect(event.char, equals('a'));
    });

    test('reads backspace', () {
      terminal.mockInput.queueKey(KeyEventType.backspace);
      final event = KeyEventReader.read();
      expect(event.type, equals(KeyEventType.backspace));
    });

    test('reads tab', () {
      terminal.mockInput.queueKey(KeyEventType.tab);
      final event = KeyEventReader.read();
      expect(event.type, equals(KeyEventType.tab));
    });
  });

  group('Integration: Terminal switching', () {
    setUp(() {
      TerminalContext.reset();
    });

    tearDown(() {
      TerminalContext.reset();
    });

    test('switching terminals changes where output goes', () {
      final terminal1 = MockTerminal();
      final terminal2 = MockTerminal();

      TerminalContext.current = terminal1;
      TerminalContext.output.write('To terminal 1');

      TerminalContext.current = terminal2;
      TerminalContext.output.write('To terminal 2');

      expect(terminal1.mockOutput.contains('To terminal 1'), isTrue);
      expect(terminal1.mockOutput.contains('To terminal 2'), isFalse);
      expect(terminal2.mockOutput.contains('To terminal 2'), isTrue);
      expect(terminal2.mockOutput.contains('To terminal 1'), isFalse);
    });

    test('RenderOutput uses current terminal', () {
      final terminal1 = MockTerminal();
      final terminal2 = MockTerminal();

      TerminalContext.current = terminal1;
      final out1 = RenderOutput();
      out1.writeln('Output 1');

      TerminalContext.current = terminal2;
      final out2 = RenderOutput();
      out2.writeln('Output 2');

      expect(terminal1.mockOutput.contains('Output 1'), isTrue);
      expect(terminal2.mockOutput.contains('Output 2'), isTrue);
    });

    test('TerminalControl uses current terminal', () {
      final terminal = MockTerminal();
      TerminalContext.current = terminal;

      TerminalControl.hideCursor();

      expect(terminal.mockOutput.allOutput.isNotEmpty, isTrue);
    });
  });
}
