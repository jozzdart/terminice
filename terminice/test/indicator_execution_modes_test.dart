import 'package:terminice/terminice.dart';
import 'package:test/test.dart';

import 'mock_terminal.dart';

void main() {
  setUp(TerminalContext.reset);
  tearDown(TerminalContext.reset);

  for (final mode in ['fallback', 'unattended']) {
    test('$mode indicators are reusable with bounded plain output', () {
      final terminal = _terminalFor(mode);
      final client = _clientFor(mode, terminal);

      final controllers = <void Function()>[
        () {
          final value = client.inlineSpinner('Spin\x1b[2J');
          value.show(0);
          value.show(1);
          value.clear();
          value.clear();
          value.show(2);
          value.clear();
        },
        () {
          final value = client.loadingSpinner('Load\x1b[2J');
          value.show(0);
          value.show(1);
          value.clear();
          value.clear();
          value.show(2);
          value.clear();
        },
        () {
          final value = client.progressDots('Dots\x1b[2J');
          value.show(phase: 0);
          value.show(phase: 2);
          value.clear();
          value.clear();
          value.show(phase: 1);
          value.clear();
        },
        () {
          final value = client.progressBar('Bar\x1b[2J');
          value.show(current: 0, total: 2);
          value.show(current: 1, total: 2);
          value.clear();
          value.clear();
          value.show(current: 2, total: 2);
          value.clear();
        },
        () {
          final value = client.inlineProgressBar('Inline\x1b[2J');
          value.show(current: 0, total: 2);
          value.show(current: 1, total: 2);
          value.clear();
          value.clear();
          value.show(current: 2, total: 2);
          value.clear();
        },
      ];

      for (final exercise in controllers) {
        final before = terminal.mockOutput.lineCount;
        exercise();
        expect(terminal.mockOutput.lineCount - before, equals(4));
      }

      _expectSafePlainOutput(terminal);
      expect(terminal.mockInput.linesRemaining, equals(1));
      expect(terminal.mockInput.bytesRemaining, equals(1));
    });

    test('$mode callback controllers emit one start and one final line', () {
      final terminal = _terminalFor(mode);
      final client = _clientFor(mode, terminal);

      client.loadingSpinner('Load').runWith((tick) {
        tick();
        tick();
      });
      client.progressDots('Dots').runWith((tick) {
        tick();
        tick();
      });
      client.progressBar('Bar').runWith((update) {
        update(1, 2);
        update(2, 2);
      });

      expect(terminal.mockOutput.lineCount, equals(6));
      expect(
        terminal.mockOutput.lines.where((line) => line.startsWith('OK:')),
        hasLength(3),
      );
      _expectSafePlainOutput(terminal);
      expect(terminal.mockInput.linesRemaining, equals(1));
      expect(terminal.mockInput.bytesRemaining, equals(1));
    });

    test('$mode task sugar preserves values, errors, and bounded output',
        () async {
      final terminal = _terminalFor(mode);
      final client = _clientFor(mode, terminal);

      expect(
        await client
            .loadingSpinner('Load\x1b[2J')
            .whileRunning<int>(() => 7, success: 'done\x1b[2J'),
        equals(7),
      );
      expect(
        await client.progressDots('Dots').whileRunning<String>(() => 'done'),
        equals('done'),
      );
      expect(
        await client.progressBar('Bar').whileRunning<int>(
          (progress) {
            progress.increment();
            return 9;
          },
          total: 1,
        ),
        equals(9),
      );
      expect(
        await client.progressBar('Stream').trackStream<int>(
              Stream<int>.fromIterable([1, 2]),
              total: 2,
            ),
        equals([1, 2]),
      );

      expect(terminal.mockOutput.lineCount, equals(8));
      _expectSafePlainOutput(terminal);
      expect(terminal.mockInput.linesRemaining, equals(1));
      expect(terminal.mockInput.bytesRemaining, equals(1));

      final error = StateError('boom');
      StackTrace? originalStack;
      try {
        await client.loadingSpinner('Fail').whileRunning<void>(() {
          originalStack = StackTrace.current;
          Error.throwWithStackTrace(error, originalStack!);
        });
        fail('Expected task failure');
      } catch (caught, stackTrace) {
        expect(identical(caught, error), isTrue);
        expect(stackTrace.toString(), equals(originalStack.toString()));
      }
      expect(terminal.mockOutput.lineCount, equals(10));
      _expectSafePlainOutput(terminal);
    });
  }

  test('factory controllers capture terminal and effective mode at creation',
      () async {
    final intended = MockTerminal();
    final other = MockTerminal();
    final client = terminice.fallback.withTerminal(intended);
    final spinner = client.inlineSpinner('Captured');
    final taskSpinner = client.loadingSpinner('Async captured');

    TerminalContext.current = other;
    spinner.show(0);
    spinner.clear();
    expect(await taskSpinner.whileRunning<int>(() => 4), equals(4));

    expect(intended.mockOutput.lineCount, equals(4));
    expect(other.mockOutput.allOutput, isEmpty);
    _expectSafePlainOutput(intended);
  });

  test('factory controllers preserve an explicit interactive policy', () {
    final terminal = MockTerminal();
    terminal.mockInput.setHasTerminal(false);
    terminal.mockOutput.setHasTerminal(false);
    final spinner = terminice.interactive
        .withTerminal(terminal)
        .inlineSpinner('Explicit rich');

    spinner.show(0);
    spinner.clear();

    expect(terminal.mockOutput.allOutput, contains('\x1b['));
    expect(terminal.mockOutput.writeCount, greaterThan(0));
  });

  test('all direct indicators capture the ambient terminal at construction',
      () {
    final first = MockTerminal();
    first.mockInput.setHasTerminal(false);
    first.mockOutput.setHasTerminal(false);
    final second = MockTerminal();
    TerminalContext.current = first;
    final inlineSpinner = InlineSpinner('Inline spinner');
    final loadingSpinner = LoadingSpinner('Loading spinner');
    final dots = ProgressDots('Dots');
    final progressBar = ProgressBar('Progress');
    final inlineProgressBar = InlineProgressBar('Inline progress');
    final controllers = <void Function()>[
      () {
        inlineSpinner.show(0);
        inlineSpinner.clear();
      },
      () {
        loadingSpinner.show(0);
        loadingSpinner.clear();
      },
      () {
        dots.show(phase: 0);
        dots.clear();
      },
      () {
        progressBar.show(current: 1, total: 2);
        progressBar.clear();
      },
      () {
        inlineProgressBar.show(current: 1, total: 2);
        inlineProgressBar.clear();
      },
    ];

    TerminalContext.current = second;
    for (final exercise in controllers) {
      exercise();
    }

    expect(first.mockOutput.lineCount, equals(10));
    expect(second.mockOutput.allOutput, isEmpty);
    _expectSafePlainOutput(first);
  });

  for (final mode in ['line', 'unattended']) {
    test('all direct indicators use bounded safe output in $mode mode', () {
      final terminal = MockTerminal();
      terminal.mockOutput.setHasTerminal(false);
      if (mode == 'unattended') terminal.mockInput.setHasTerminal(false);
      TerminalContext.current = terminal;

      final controllers = <void Function()>[
        () {
          final value = InlineSpinner('Spin\x1b[2J');
          value.show(0);
          value.show(1);
          value.clear();
        },
        () {
          final value = LoadingSpinner('Load\x1b]0;bad\x07');
          value.show(0);
          value.show(1);
          value.clear();
        },
        () {
          final value = ProgressDots('Dots\x1b[2J');
          value.show(phase: 0);
          value.show(phase: 2);
          value.clear();
        },
        () {
          final value = ProgressBar('Bar\x1b[2J');
          value.show(current: 0, total: 2);
          value.show(current: 1, total: 2);
          value.clear();
        },
        () {
          final value = InlineProgressBar('Inline\x1b[2J');
          value.show(current: 0, total: 2);
          value.show(current: 1, total: 2);
          value.clear();
        },
      ];

      for (final exercise in controllers) {
        final before = terminal.mockOutput.lineCount;
        exercise();
        expect(terminal.mockOutput.lineCount - before, equals(2));
      }

      _expectSafePlainOutput(terminal);
    });
  }

  for (final throwingProbe in [
    _ThrowingProbe.input,
    _ThrowingProbe.output,
  ]) {
    test('direct indicators fall back when the $throwingProbe probe throws',
        () {
      final terminal = _ProbeTerminal(throwingProbe);
      TerminalContext.current = terminal;

      final spinner = InlineSpinner('Probe\x1b[2J');
      spinner.show(0);
      spinner.clear();

      expect(terminal.delegate.mockOutput.lineCount, equals(2));
      _expectSafePlainOutput(terminal.delegate);
    });
  }

  test('direct task sugar keeps the terminal captured by its lifecycle',
      () async {
    final intended = MockTerminal();
    intended.mockInput.setHasTerminal(false);
    intended.mockOutput.setHasTerminal(false);
    final other = MockTerminal();
    TerminalContext.current = intended;
    final spinner = LoadingSpinner('Direct task\x1b[2J');
    expect(
      await spinner.whileRunning<int>(() {
        TerminalContext.current = other;
        return 7;
      }),
      equals(7),
    );

    expect(intended.mockOutput.lineCount, equals(2));
    expect(other.mockOutput.allOutput, isEmpty);
    _expectSafePlainOutput(intended);
  });

  test('direct task sugar keeps the mode captured by its lifecycle', () async {
    final terminal = MockTerminal();
    terminal.mockInput.setHasTerminal(false);
    terminal.mockOutput.setHasTerminal(false);
    TerminalContext.current = terminal;
    final spinner = LoadingSpinner('Captured mode');

    spinner.show(0);
    terminal.mockInput.setHasTerminal(true);
    terminal.mockOutput.setHasTerminal(true);
    expect(await spinner.whileRunning<int>(() => 9), equals(9));

    expect(terminal.mockOutput.lineCount, equals(2));
    _expectSafePlainOutput(terminal);
  });

  test('direct callback sugar preserves error, stack, and terminal state', () {
    final terminal = MockTerminal();
    terminal.mockInput.setHasTerminal(false);
    terminal.mockOutput.setHasTerminal(false);
    TerminalContext.current = terminal;
    final error = StateError('direct callback failed\x1b[2J');
    late StackTrace originalStack;

    final dots = ProgressDots('Direct fail\x1b[2J');
    try {
      dots.runWith((_) {
        originalStack = StackTrace.current;
        Error.throwWithStackTrace(error, originalStack);
      });
      fail('Expected callback failure');
    } catch (caught, stackTrace) {
      expect(identical(caught, error), isTrue);
      expect(stackTrace.toString(), equals(originalStack.toString()));
    }

    expect(terminal.mockOutput.lineCount, equals(2));
    expect(terminal.mockOutput.lines.last, startsWith('ERROR:'));

    dots.runWith((tick) => tick());
    expect(terminal.mockOutput.lineCount, equals(4));
    expect(terminal.mockOutput.lines.last, startsWith('OK:'));
    _expectSafePlainOutput(terminal);
  });

  test('direct task sugar is reusable after success and error', () async {
    final terminal = MockTerminal();
    terminal.mockInput.setHasTerminal(false);
    terminal.mockOutput.setHasTerminal(false);
    TerminalContext.current = terminal;
    final spinner = LoadingSpinner('Reusable task');

    expect(await spinner.whileRunning<int>(() => 1), equals(1));

    final error = StateError('task failed');
    late StackTrace originalStack;
    try {
      await spinner.whileRunning<void>(() {
        originalStack = StackTrace.current;
        Error.throwWithStackTrace(error, originalStack);
      });
      fail('Expected task failure');
    } catch (caught, stackTrace) {
      expect(identical(caught, error), isTrue);
      expect(stackTrace.toString(), equals(originalStack.toString()));
    }

    expect(await spinner.whileRunning<int>(() => 3), equals(3));
    expect(terminal.mockOutput.lineCount, equals(6));
    expect(
      terminal.mockOutput.lines.where((line) => line.startsWith('OK:')),
      hasLength(2),
    );
    expect(
      terminal.mockOutput.lines.where((line) => line.startsWith('ERROR:')),
      hasLength(1),
    );
    _expectSafePlainOutput(terminal);
  });

  test('direct rich callback restores the cursor when the callback throws', () {
    final terminal = MockTerminal();
    TerminalContext.current = terminal;
    final error = StateError('rich callback failed');
    late StackTrace originalStack;

    try {
      LoadingSpinner('Rich fail').runWith((tick) {
        tick();
        originalStack = StackTrace.current;
        Error.throwWithStackTrace(error, originalStack);
      });
      fail('Expected callback failure');
    } catch (caught, stackTrace) {
      expect(identical(caught, error), isTrue);
      expect(stackTrace.toString(), equals(originalStack.toString()));
    }

    expect(terminal.mockOutput.allOutput, contains('\x1b[?25l'));
    expect(terminal.mockOutput.allOutput, contains('\x1b[?25h'));
    expect(terminal.mockInput.lineMode, isTrue);
    expect(terminal.mockInput.echoMode, isTrue);
  });

  test('rich callback teardown stays on its captured terminal', () {
    final captured = MockTerminal();
    final caller = MockTerminal();
    final changedInsideCallback = MockTerminal();
    TerminalContext.current = captured;
    final spinner = LoadingSpinner('Captured rich');
    TerminalContext.current = caller;

    spinner.runWith((tick) {
      tick();
      TerminalContext.current = changedInsideCallback;
    });

    expect(captured.mockOutput.allOutput, contains('\x1b[?25l'));
    expect(captured.mockOutput.allOutput, contains('\x1b[4A\x1b[0J'));
    expect(captured.mockOutput.allOutput, contains('\x1b[?25h'));
    expect(changedInsideCallback.mockOutput.allOutput, isEmpty);
    expect(TerminalContext.current, same(caller));
  });

  test('rich task sugar clears an active manual frame before delegation',
      () async {
    final successTerminal = MockTerminal();
    TerminalContext.current = successTerminal;
    final direct = LoadingSpinner('Direct handoff');
    direct.show(0);

    expect(
      await direct.whileRunning<int>(() {
        expect(successTerminal.mockOutput.writes.first, startsWith('\x1b['));
        expect(successTerminal.mockOutput.writes.first, endsWith('A'));
        expect(successTerminal.mockOutput.writes[1], equals('\x1b[0J'));
        return 7;
      }),
      equals(7),
    );

    final failureTerminal = MockTerminal();
    final factory = terminice.interactive
        .withTerminal(failureTerminal)
        .progressDots('Factory handoff');
    factory.show(phase: 0);
    final error = StateError('handoff failed');
    late StackTrace originalStack;

    try {
      await factory.whileRunning<void>(() {
        expect(failureTerminal.mockOutput.writes.first, startsWith('\x1b['));
        expect(failureTerminal.mockOutput.writes.first, endsWith('A'));
        expect(failureTerminal.mockOutput.writes[1], equals('\x1b[0J'));
        originalStack = StackTrace.current;
        Error.throwWithStackTrace(error, originalStack);
      });
      fail('Expected task failure');
    } catch (caught, stackTrace) {
      expect(identical(caught, error), isTrue);
      expect(stackTrace.toString(), equals(originalStack.toString()));
    }
  });

  test('callback runWith rethrows the identical error and stack trace', () {
    final terminal = MockTerminal();
    final error = StateError('callback failed');
    late StackTrace originalStack;

    try {
      terminice.fallback
          .withTerminal(terminal)
          .progressDots('Fail')
          .runWith((_) {
        originalStack = StackTrace.current;
        Error.throwWithStackTrace(error, originalStack);
      });
      fail('Expected callback failure');
    } catch (caught, stackTrace) {
      expect(identical(caught, error), isTrue);
      expect(stackTrace.toString(), equals(originalStack.toString()));
    }

    expect(terminal.mockOutput.lineCount, equals(2));
    expect(terminal.mockOutput.lines.last, startsWith('ERROR:'));
    _expectSafePlainOutput(terminal);
  });
}

enum _ThrowingProbe { input, output }

class _ProbeTerminal implements Terminal {
  _ProbeTerminal(this.throwingProbe);

  final _ThrowingProbe throwingProbe;
  final MockTerminal delegate = MockTerminal();

  @override
  TerminalInput get input =>
      _ProbeInput(delegate.mockInput, throwingProbe == _ThrowingProbe.input);

  @override
  TerminalOutput get output =>
      _ProbeOutput(delegate.mockOutput, throwingProbe == _ThrowingProbe.output);
}

class _ProbeInput implements TerminalInput {
  _ProbeInput(this.delegate, this.throwHasTerminal);

  final MockTerminalInput delegate;
  final bool throwHasTerminal;

  @override
  bool get hasTerminal {
    if (throwHasTerminal) throw StateError('input capability unavailable');
    return delegate.hasTerminal;
  }

  @override
  bool get echoMode => delegate.echoMode;

  @override
  set echoMode(bool value) => delegate.echoMode = value;

  @override
  bool get lineMode => delegate.lineMode;

  @override
  set lineMode(bool value) => delegate.lineMode = value;

  @override
  int readByteSync() => delegate.readByteSync();

  @override
  String? readLineSync() => delegate.readLineSync();
}

class _ProbeOutput implements TerminalOutput {
  _ProbeOutput(this.delegate, this.throwHasTerminal);

  final MockTerminalOutput delegate;
  final bool throwHasTerminal;

  @override
  bool get hasTerminal {
    if (throwHasTerminal) throw StateError('output capability unavailable');
    return delegate.hasTerminal;
  }

  @override
  int get terminalColumns => delegate.terminalColumns;

  @override
  int get terminalLines => delegate.terminalLines;

  @override
  void write(Object? object) => delegate.write(object);

  @override
  void writeln([Object? object = '']) => delegate.writeln(object);
}

MockTerminal _terminalFor(String mode) {
  final terminal = MockTerminal();
  terminal.mockInput.queueLine('unread');
  terminal.mockInput.queueByte(13);
  if (mode == 'unattended') {
    terminal.mockInput.setHasTerminal(false);
    terminal.mockOutput.setHasTerminal(false);
  }
  return terminal;
}

Terminice _clientFor(String mode, MockTerminal terminal) {
  final client = terminice.withTerminal(terminal);
  return mode == 'fallback' ? client.fallback : client.autoFallback;
}

void _expectSafePlainOutput(MockTerminal terminal) {
  expect(terminal.mockOutput.allOutput, isNot(contains('\x1b')));
  expect(terminal.mockOutput.writeCount, equals(0));
  expect(terminal.mockInput.lineMode, isTrue);
  expect(terminal.mockInput.echoMode, isTrue);
}
