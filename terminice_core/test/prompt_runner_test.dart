import 'package:terminice_core/testing.dart';
import 'package:test/test.dart';

class _TestTerminal implements Terminal {
  @override
  final _TestInput input;

  @override
  final _TestOutput output;

  _TestTerminal({
    bool echoMode = true,
    bool lineMode = true,
    bool failWhenDisablingLineMode = false,
    int failingOutputWrites = 0,
  })  : input = _TestInput(
          echoMode: echoMode,
          lineMode: lineMode,
          failWhenDisablingLineMode: failWhenDisablingLineMode,
        ),
        output = _TestOutput(failingWrites: failingOutputWrites);
}

class _TestInput implements TerminalInput {
  bool _echoMode;
  bool _lineMode;

  @override
  bool get echoMode => _echoMode;

  @override
  set echoMode(bool value) => _echoMode = value;

  @override
  bool get lineMode => _lineMode;

  final bool failWhenDisablingLineMode;

  _TestInput({
    required bool echoMode,
    required bool lineMode,
    required this.failWhenDisablingLineMode,
  })  : _echoMode = echoMode,
        _lineMode = lineMode;

  @override
  bool get hasTerminal => true;

  @override
  int readByteSync() => throw StateError('No input queued');

  @override
  String? readLineSync() => null;

  @override
  set lineMode(bool value) {
    _lineMode = value;
    if (!value && failWhenDisablingLineMode) {
      throw StateError('line mode failed');
    }
  }
}

class _TestOutput implements TerminalOutput {
  int failingWrites;
  final writes = <String>[];

  _TestOutput({required this.failingWrites});

  @override
  bool get hasTerminal => true;

  @override
  int get terminalColumns => 80;

  @override
  int get terminalLines => 24;

  @override
  void write(Object? object) {
    writes.add(object?.toString() ?? '');
    if (failingWrites > 0) {
      failingWrites--;
      throw StateError('output failed');
    }
  }

  @override
  void writeln([Object? object = '']) => write('$object\n');
}

void main() {
  late MockTerminal terminal;

  setUp(() {
    terminal = MockTerminal();
    TerminalContext.current = terminal;
  });

  tearDown(TerminalContext.reset);

  void expectTerminalRestored() {
    expect(terminal.mockInput.echoMode, isTrue);
    expect(terminal.mockInput.lineMode, isTrue);
    expect(terminal.mockOutput.contains('\x1B[?25h'), isTrue);
  }

  test('Ctrl+C input cancels and restores the terminal session', () {
    terminal.mockInput.queueByte(3);
    var cancelCalls = 0;

    final result = PromptRunner().runWithBindings(
      render: (out) => out.writeln('Prompt'),
      bindings: KeyBindings.cancel(onCancel: () => cancelCalls++),
    );

    expect(result, PromptResult.cancelled);
    expect(cancelCalls, 1);
    expectTerminalRestored();
  });

  test('restores the terminal when the initial render throws', () {
    expect(
      () => PromptRunner().run(
        render: (_) => throw StateError('render failed'),
        onKey: (_) => null,
      ),
      throwsStateError,
    );

    expectTerminalRestored();
  });

  test('restores the terminal when the before-cleanup callback throws', () {
    terminal.mockInput.queueByte(3);

    expect(
      () => PromptRunner(
        onBeforeCleanup: () => throw StateError('cleanup failed'),
      ).runWithBindings(
        render: (out) => out.writeln('Prompt'),
        bindings: KeyBindings.cancel(),
      ),
      throwsStateError,
    );

    expectTerminalRestored();
  });

  test('raw-mode entry rolls back a partially changed input', () {
    final failingTerminal = _TestTerminal(
      failWhenDisablingLineMode: true,
    );
    TerminalContext.current = failingTerminal;
    final session = TerminalSession(rawMode: true);

    expect(session.start, throwsStateError);

    expect(session.isActive, isFalse);
    expect(failingTerminal.input.echoMode, isTrue);
    expect(failingTerminal.input.lineMode, isTrue);
  });

  test('cursor startup failure restores raw mode and attempts cursor recovery',
      () {
    final failingTerminal = _TestTerminal(failingOutputWrites: 1);
    TerminalContext.current = failingTerminal;
    final session = TerminalSession(hideCursor: true, rawMode: true);

    expect(session.start, throwsStateError);

    expect(session.isActive, isFalse);
    expect(failingTerminal.input.echoMode, isTrue);
    expect(failingTerminal.input.lineMode, isTrue);
    expect(
      failingTerminal.output.writes,
      equals(['\x1B[?25l', '\x1B[?25h']),
    );
  });

  test('session cleanup targets the terminal captured at startup', () {
    final original = MockTerminal();
    final replacement = MockTerminal();
    TerminalContext.current = original;
    final session = TerminalSession(hideCursor: true, rawMode: true);

    session.run(() {
      TerminalContext.current = replacement;
    });

    expect(TerminalContext.current, same(replacement));
    expect(original.mockInput.echoMode, isTrue);
    expect(original.mockInput.lineMode, isTrue);
    expect(original.mockOutput.contains('\x1B[?25h'), isTrue);
    expect(replacement.mockOutput.allOutput, isEmpty);
  });

  test('runCustom restores its captured terminal after an error', () {
    final replacement = MockTerminal();

    expect(
      () => PromptRunner().runCustom<void>((_) {
        TerminalContext.current = replacement;
        throw StateError('custom failed');
      }),
      throwsStateError,
    );

    expect(terminal.mockInput.echoMode, isTrue);
    expect(terminal.mockInput.lineMode, isTrue);
    expect(terminal.mockOutput.contains('\x1B[?25h'), isTrue);
    expect(replacement.mockOutput.allOutput, isEmpty);
  });

  test('session restores non-default original terminal modes', () {
    final nonDefaultTerminal = _TestTerminal(
      echoMode: false,
      lineMode: true,
    );
    TerminalContext.current = nonDefaultTerminal;

    TerminalSession(rawMode: true).run(() {
      expect(nonDefaultTerminal.input.echoMode, isFalse);
      expect(nonDefaultTerminal.input.lineMode, isFalse);
    });

    expect(nonDefaultTerminal.input.echoMode, isFalse);
    expect(nonDefaultTerminal.input.lineMode, isTrue);
  });
}
