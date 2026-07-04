import 'dart:convert';

import 'package:test/test.dart';
import 'package:terminice_core/testing.dart';

List<int> _drainBytes(MockTerminalInput input) {
  final bytes = <int>[];
  while (input.bytesRemaining > 0) {
    bytes.add(input.readByteSync());
  }
  return bytes;
}

void main() {
  group('TerminalScript', () {
    test('queues lines, text, and key events and can be reused', () {
      final script = TerminalScript.build(
        (script) =>
            script.line('first').lines(['second', 'third']).text('ok').enter(),
      );

      final terminal = MockTerminal();
      terminal.queueScript(script);

      expect(terminal.input.readLineSync(), equals('first'));
      expect(terminal.input.readLineSync(), equals('second'));
      expect(terminal.input.readLineSync(), equals('third'));
      expect(terminal.input.readByteSync(), equals('o'.codeUnitAt(0)));
      expect(terminal.input.readByteSync(), equals('k'.codeUnitAt(0)));
      expect(terminal.input.readByteSync(), equals(13));

      terminal.queueScript(script);

      expect(terminal.input.readLineSync(), equals('first'));
      expect(terminal.input.readLineSync(), equals('second'));
      expect(terminal.input.readLineSync(), equals('third'));
      expect(terminal.input.readByteSync(), equals('o'.codeUnitAt(0)));
      expect(terminal.input.readByteSync(), equals('k'.codeUnitAt(0)));
      expect(terminal.input.readByteSync(), equals(13));
    });

    test('constructs scripts from explicit steps', () {
      final script = TerminalScript([
        const TerminalScriptStep.text('x'),
        const TerminalScriptStep.key(KeyEventType.char, 'y'),
        const TerminalScriptStep.line('done'),
      ]);

      final input = MockTerminalInput();
      input.queueScript(script);

      expect(input.readLineSync(), equals('done'));
      expect(input.readByteSync(), equals('x'.codeUnitAt(0)));
      expect(input.readByteSync(), equals('y'.codeUnitAt(0)));
    });

    test('text steps queue non-ASCII text as UTF-8 bytes', () {
      final script = TerminalScript([
        const TerminalScriptStep.text('é界'),
      ]);

      final input = MockTerminalInput()..queueScript(script);

      expect(_drainBytes(input), equals(utf8.encode('é界')));
    });

    test('creates line scripts with TerminalScript.lines', () {
      final script = TerminalScript.lines(['one', 'two']);
      final input = MockTerminalInput()..queueScript(script);

      expect(script.length, equals(2));
      expect(script.isNotEmpty, isTrue);
      expect(
        () => script.steps.add(const TerminalScriptStep.line('three')),
        throwsUnsupportedError,
      );
      expect(input.readLineSync(), equals('one'));
      expect(input.readLineSync(), equals('two'));
    });

    test('navigation and control helpers queue existing key bytes', () {
      final script = TerminalScript.build(
        (script) => script
            .up()
            .down()
            .left()
            .right()
            .space()
            .backspace()
            .tab()
            .ctrlC()
            .ctrlD()
            .escape(),
      );

      final input = MockTerminalInput()..queueScript(script);
      final bytes = <int>[];
      while (input.bytesRemaining > 0) {
        bytes.add(input.readByteSync());
      }

      expect(
        bytes,
        equals([
          27, 91, 65, // up
          27, 91, 66, // down
          27, 91, 68, // left
          27, 91, 67, // right
          32, // space
          127, // backspace
          9, // tab
          3, // ctrlC
          4, // ctrlD
          27, // escape
        ]),
      );
    });

    test('extension APIs work from MockTerminal and MockTerminalInput', () {
      final terminalScript = TerminalScript.build(
        (script) => script.text('a').enter(),
      );
      final inputScript = TerminalScript.build((script) => script.text('b'));

      final terminal = MockTerminal()..queueScript(terminalScript);
      final input = MockTerminalInput()..queueScript(inputScript);

      expect(terminal.input.readByteSync(), equals('a'.codeUnitAt(0)));
      expect(terminal.input.readByteSync(), equals(13));
      expect(input.readByteSync(), equals('b'.codeUnitAt(0)));
    });
  });

  group('TerminalOutputSnapshot', () {
    test('strips broad terminal control sequences', () {
      final raw = [
        '\x1B[?25l',
        '\x1B[2J',
        '\x1B[H',
        '\x1B[31mHello\x1B[0m',
        '\x1B[1A',
        '\x1B[2K',
        ' world',
        '\x1B]0;title\x07',
        '\x1B[?25h',
      ].join();

      final snapshot = TerminalOutputSnapshot(raw);

      expect(snapshot.plainText, equals('Hello world'));
      expect(snapshot.normalizedText, equals('Hello world'));
      expect(snapshot.containsAnsiControls, isTrue);
      expect(snapshot.isAscii, isTrue);
    });

    test('normalizes text and exposes raw and plain lines', () {
      final snapshot = TerminalOutputSnapshot(
        'first  \r\nsecond\t \n\x1B[2Kthird  \n',
      );

      expect(snapshot.raw, contains('\x1B[2K'));
      expect(
          snapshot.lines, equals(['first  ', 'second\t ', '\x1B[2Kthird  ']));
      expect(snapshot.plainLines, equals(['first  ', 'second\t ', 'third  ']));
      expect(snapshot.normalizedText, equals('first\nsecond\nthird'));
      expect(snapshot.containsAnsiControls, isTrue);
    });

    test('detects plain output and non-ascii output predictably', () {
      final plain = TerminalOutputSnapshot('plain\ntext');
      final nonAscii = TerminalOutputSnapshot('cafe\u0301');

      expect(plain.containsAnsiControls, isFalse);
      expect(plain.isAscii, isTrue);
      expect(nonAscii.containsAnsiControls, isFalse);
      expect(nonAscii.isAscii, isFalse);
    });

    test('snapshot extensions capture mock output ergonomically', () {
      final terminal = MockTerminal();
      terminal.output.write('\x1B[31mReady\x1B[0m\n');

      final fromOutput = terminal.output.snapshot;
      final fromTerminal = terminal.outputSnapshot;

      expect(fromOutput.plainText, equals('Ready\n'));
      expect(fromOutput.normalizedText, equals('Ready'));
      expect(fromTerminal.raw, equals(fromOutput.raw));
    });
  });
}
