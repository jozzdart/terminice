import 'dart:async';

import 'package:test/test.dart';
import 'package:terminice/terminice.dart';

import 'mock_terminal.dart';

void main() {
  setUp(TerminalContext.reset);
  tearDown(TerminalContext.reset);

  group('async task helper', () {
    test('returns the typed result', () async {
      final terminal = MockTerminal();
      final t = terminice.withTerminal(terminal);

      final result = await t.task<int>(
        'Compute',
        run: () async => 42,
        display: TaskDisplay.plain,
      );

      expect(result, equals(42));
      expect(terminal.mockOutput.lines, equals(['OK: Compute']));
    });

    test('renders and rethrows sync errors', () async {
      final terminal = MockTerminal();
      final error = StateError('boom');

      final task = terminice.withTerminal(terminal).task<void>(
            'Sync work',
            run: () {
              throw error;
            },
            display: TaskDisplay.plain,
            failure: (error, stackTrace) => 'sync failed: $error',
          );

      await expectLater(task, throwsA(same(error)));
      expect(
        terminal.mockOutput.lines,
        equals(['ERROR: sync failed: Bad state: boom']),
      );
    });

    test('renders and rethrows async errors', () async {
      final terminal = MockTerminal();
      final error = ArgumentError('bad input');

      final task = terminice.withTerminal(terminal).task<void>(
        'Async work',
        run: () async {
          await Future<void>.delayed(Duration.zero);
          throw error;
        },
        display: TaskDisplay.plain,
      );

      await expectLater(task, throwsA(same(error)));
      expect(terminal.mockOutput.lines.single, contains('Async work failed'));
      expect(terminal.mockOutput.lines.single, contains('bad input'));
    });

    test('renders cancellation status when the predicate matches', () async {
      final terminal = MockTerminal();
      final error = _TaskCanceled();

      final task = terminice.withTerminal(terminal).task<void>(
            'Cancelable work',
            run: () {
              throw error;
            },
            display: TaskDisplay.plain,
            isCanceled: (error) => error is _TaskCanceled,
            cancel: (error, stackTrace) => 'stopped by caller',
          );

      await expectLater(task, throwsA(same(error)));
      expect(
          terminal.mockOutput.lines, equals(['CANCELED: stopped by caller']));
      expect(terminal.mockOutput.contains('ERROR'), isFalse);
    });

    test('final behavior clear leaves no success line', () async {
      final persistTerminal = MockTerminal();
      await terminice.withTerminal(persistTerminal).task<void>(
            'Persist',
            run: () {},
            display: TaskDisplay.plain,
            success: 'done',
          );

      final clearTerminal = MockTerminal();
      await terminice.withTerminal(clearTerminal).task<void>(
            'Clear',
            run: () {},
            display: TaskDisplay.plain,
            success: 'done',
            finalBehavior: TaskFinalBehavior.clear,
          );

      expect(persistTerminal.mockOutput.lines, equals(['OK: done']));
      expect(clearTerminal.mockOutput.allOutput, isEmpty);
    });

    test('activates the configured terminal before rendering', () async {
      final target = MockTerminal();
      final other = MockTerminal();
      final t = terminice.withTerminal(target);
      TerminalContext.current = other;

      final result = await t.task<int>(
        'Activate',
        run: () => 7,
        display: TaskDisplay.plain,
        success: 'done',
      );

      expect(result, equals(7));
      expect(TerminalContext.current, same(target));
      expect(target.mockOutput.lines, equals(['OK: done']));
      expect(other.mockOutput.allOutput, isEmpty);
    });

    test('animated task keeps using the originating terminal', () async {
      final target = MockTerminal();
      final other = MockTerminal();
      final t = terminice.withTerminal(target);

      final result = await t.task<int>(
        'Origin',
        run: () async {
          terminice.withTerminal(other).activate();
          final targetLinesAtSwitch = target.mockOutput.lineCount;
          final otherOutputLengthAtSwitch = other.mockOutput.allOutput.length;
          await _waitForPostSwitchRender(
            target,
            targetLinesAtSwitch,
            other,
            otherOutputLengthAtSwitch,
          );
          return 7;
        },
        display: TaskDisplay.inline,
        interval: _asyncRenderInterval,
        success: 'done',
      );

      expect(result, equals(7));
      expect(_stripAnsi(target.mockOutput.allOutput), contains('Origin'));
      expect(_stripAnsi(target.mockOutput.allOutput), contains('done'));
      _expectCursorRestored(target.mockOutput.allOutput);
      expect(other.mockOutput.allOutput, isEmpty);
    });

    test('auto display uses plain output in fallback mode without ANSI',
        () async {
      final terminal = MockTerminal();

      final result = await terminice.fallback.withTerminal(terminal).task<int>(
            'Fallback',
            run: () => 1,
            success: 'done',
          );

      expect(result, equals(1));
      expect(terminal.mockOutput.lines, equals(['OK: done']));
      expect(_containsAnsi(terminal.mockOutput.allOutput), isFalse);
      expect(_isAscii(terminal.mockOutput.allOutput), isTrue);
    });

    test('auto display uses plain output for non-interactive terminals',
        () async {
      final terminal = MockTerminal();
      terminal.mockInput.setHasTerminal(false);
      terminal.mockOutput.setHasTerminal(false);

      await terminice.autoFallback.withTerminal(terminal).task<void>(
            'Non-interactive',
            run: () {},
            success: 'done',
          );

      expect(terminal.mockOutput.lines, equals(['OK: done']));
      expect(_containsAnsi(terminal.mockOutput.allOutput), isFalse);
    });

    test('basic compatibility keeps auto output ASCII and ANSI-free', () async {
      final terminal = MockTerminal();

      await terminice.basic.withTerminal(terminal).task<void>(
            'Basic',
            run: () {},
          );

      expect(terminal.mockOutput.lines, equals(['OK: Basic']));
      expect(_containsAnsi(terminal.mockOutput.allOutput), isFalse);
      expect(_isAscii(terminal.mockOutput.allOutput), isTrue);
    });

    test('indicator whileRunning preserves fallback origin', () async {
      final terminal = MockTerminal();

      final result = await terminice.fallback
          .withTerminal(terminal)
          .loadingSpinner('Install')
          .whileRunning<int>(
            () => 7,
            success: 'installed',
          );

      expect(result, equals(7));
      expect(terminal.mockOutput.lines, equals(['OK: installed']));
      expect(_containsAnsi(terminal.mockOutput.allOutput), isFalse);
      expect(_isAscii(terminal.mockOutput.allOutput), isTrue);
    });

    test('progressBar whileRunning preserves basic origin', () async {
      final terminal = MockTerminal();

      await terminice.basic
          .withTerminal(terminal)
          .progressBar('Upload')
          .whileRunning<void>(
        (progress) {
          progress.increment();
        },
        total: 1,
        success: 'uploaded',
      );

      expect(terminal.mockOutput.lines, equals(['OK: uploaded (1/1, 100%)']));
      expect(_containsAnsi(terminal.mockOutput.allOutput), isFalse);
      expect(_isAscii(terminal.mockOutput.allOutput), isTrue);
    });

    test('progressDots whileRunning preserves legacy origin', () async {
      final terminal = MockTerminal();

      await terminice.legacy
          .withTerminal(terminal)
          .progressDots('Wait')
          .whileRunning<void>(
            () {},
            success: 'waited',
          );

      expect(terminal.mockOutput.lines, equals(['OK: waited']));
      expect(_containsAnsi(terminal.mockOutput.allOutput), isFalse);
      expect(_isAscii(terminal.mockOutput.allOutput), isTrue);
    });

    test('progressTask exposes progress updates and typed results', () async {
      final terminal = MockTerminal();
      final t = terminice.withTerminal(terminal);
      TaskProgress? captured;

      final result = await t.progressTask<String>(
        'Download',
        total: 3,
        message: 'starting',
        display: TaskDisplay.plain,
        success: 'downloaded',
        run: (progress) async {
          expect(progress.current, equals(0));
          expect(progress.total, equals(3));
          expect(progress.message, equals('starting'));
          expect(progress.ratio, equals(0));
          expect(progress.isComplete, isFalse);

          progress.update(current: 1, message: 'first chunk');
          progress.increment(2);
          captured = progress;
          return 'artifact';
        },
      );

      expect(result, equals('artifact'));
      expect(captured?.current, equals(3));
      expect(captured?.ratio, equals(1));
      expect(captured?.isComplete, isTrue);
      expect(
        terminal.mockOutput.lines,
        equals(['OK: downloaded (3/3, 100%)']),
      );
    });

    test('progressTask validates totals and clamps current progress', () async {
      final invalidTerminal = MockTerminal();

      for (final invalidTotal in [0, -1]) {
        await expectLater(
          terminice.withTerminal(invalidTerminal).progressTask<void>(
                'Invalid',
                total: invalidTotal,
                display: TaskDisplay.plain,
                run: (_) {},
              ),
          throwsArgumentError,
        );
      }
      expect(invalidTerminal.mockOutput.allOutput, isEmpty);

      final terminal = MockTerminal();
      final result = await terminice.withTerminal(terminal).progressTask<int>(
        'Clamp',
        total: 5,
        display: TaskDisplay.plain,
        run: (progress) {
          expect(() => progress.update(total: -1), throwsArgumentError);

          progress.update(current: 99);
          expect(progress.current, equals(5));
          expect(progress.ratio, equals(1));

          progress.update(current: -10);
          expect(progress.current, equals(0));

          progress.update(total: 3, current: 10);
          expect(progress.current, equals(3));
          expect(progress.total, equals(3));
          return progress.current;
        },
      );

      expect(result, equals(3));
      expect(terminal.mockOutput.lines, equals(['OK: Clamp (3/3, 100%)']));
    });

    test('progressTask summaries render clamped display values', () async {
      final negativeTerminal = MockTerminal();

      await terminice.withTerminal(negativeTerminal).progressTask<void>(
        'Negative',
        total: 10,
        display: TaskDisplay.plain,
        run: (progress) {
          progress.update(current: -4);
        },
      );

      expect(
        negativeTerminal.mockOutput.lines,
        equals(['OK: Negative (0/10, 0%)']),
      );

      final overTotalTerminal = MockTerminal();

      await terminice.withTerminal(overTotalTerminal).progressTask<void>(
        'Over',
        total: 10,
        display: TaskDisplay.plain,
        run: (progress) {
          progress.update(current: 14);
        },
      );

      expect(
        overTotalTerminal.mockOutput.lines,
        equals(['OK: Over (10/10, 100%)']),
      );
    });

    test('progressTask renders and rethrows failures', () async {
      final terminal = MockTerminal();
      final error = StateError('boom');

      final task = terminice.withTerminal(terminal).progressTask<void>(
        'Progress work',
        total: 4,
        display: TaskDisplay.plain,
        run: (progress) {
          progress.increment(2);
          throw error;
        },
      );

      await expectLater(task, throwsA(same(error)));
      expect(
        terminal.mockOutput.lines,
        equals(['ERROR: Progress work failed: Bad state: boom (2/4, 50%)']),
      );
    });

    test('progressTask fallback output stays ASCII and ANSI-free', () async {
      final terminal = MockTerminal();

      final result =
          await terminice.fallback.withTerminal(terminal).progressTask<int>(
        'Fallback progress',
        total: 2,
        success: 'done',
        run: (progress) {
          progress.increment();
          progress.increment();
          return 2;
        },
      );

      expect(result, equals(2));
      expect(terminal.mockOutput.lines, equals(['OK: done (2/2, 100%)']));
      expect(_containsAnsi(terminal.mockOutput.allOutput), isFalse);
      expect(_isAscii(terminal.mockOutput.allOutput), isTrue);
    });

    test('trackStream collects values and advances progress', () async {
      final terminal = MockTerminal();

      final values = await terminice.withTerminal(terminal).trackStream<int>(
            'Stream',
            Stream<int>.fromIterable([1, 2, 3]),
            total: 3,
            display: TaskDisplay.plain,
            success: 'streamed',
          );

      expect(values, equals([1, 2, 3]));
      expect(
        terminal.mockOutput.lines,
        equals(['OK: streamed (3/3, 100%)']),
      );
    });

    test('trackStream rethrows stream errors and cleans up animated output',
        () async {
      final terminal = MockTerminal();
      final error = StateError('stream failed');

      final task = terminice.withTerminal(terminal).trackStream<int>(
            'Stream',
            Stream<int>.error(error),
            total: 1,
            failure: (error, stackTrace) => 'stream failed: $error',
          );

      await expectLater(task, throwsA(same(error)));
      _expectCursorRestored(terminal.mockOutput.allOutput);
      expect(
          terminal.mockOutput
              .contains('stream failed: Bad state: stream failed'),
          isTrue);
    });

    test('formatter and predicate failures still clean up animated output',
        () async {
      final terminal = MockTerminal();
      final formatterError = StateError('formatter failed');

      await expectLater(
        terminice.withTerminal(terminal).task<void>(
          'Format',
          run: () {
            throw StateError('work failed');
          },
          failure: (error, stackTrace) {
            throw formatterError;
          },
        ),
        throwsA(same(formatterError)),
      );
      _expectCursorRestored(terminal.mockOutput.allOutput);

      terminal.reset();
      final predicateError = StateError('predicate failed');

      await expectLater(
        terminice.withTerminal(terminal).task<void>(
          'Predicate',
          run: () {
            throw StateError('work failed');
          },
          isCanceled: (error) {
            throw predicateError;
          },
        ),
        throwsA(same(predicateError)),
      );
      _expectCursorRestored(terminal.mockOutput.allOutput);
    });

    test('rendering failures still clean up animated output', () async {
      final renderError = StateError('render failed');
      final terminal = _ThrowingTerminal(
        renderError,
        shouldThrowLine: (line) => line.contains('Render start'),
      );

      await expectLater(
        terminice.withTerminal(terminal).task<void>(
              'Render start',
              run: () {},
            ),
        throwsA(same(renderError)),
      );
      _expectCursorRestored(terminal.mockOutput.allOutput);
    });

    test('final success render failures bypass user error callbacks', () async {
      final renderError = StateError('final render failed');
      final callbackErrors = <Object>[];
      final terminal = _ThrowingTerminal(
        renderError,
        shouldThrowLine: (line) => line.contains('final ok'),
      );

      await expectLater(
        terminice.withTerminal(terminal).task<void>(
          'Final render',
          run: () {},
          success: 'final ok',
          isCanceled: (error) {
            callbackErrors.add(error);
            return false;
          },
          failure: (error, stackTrace) {
            callbackErrors.add(error);
            return 'classified as task failure';
          },
          cancel: (error, stackTrace) {
            callbackErrors.add(error);
            return 'classified as cancellation';
          },
        ),
        throwsA(same(renderError)),
      );

      expect(callbackErrors, isEmpty);
      _expectCursorRestored(terminal.mockOutput.allOutput);
    });

    test('progress update render failures bypass callbacks and clean up',
        () async {
      final renderError = StateError('progress render failed');
      final callbackErrors = <Object>[];
      final terminal = _ThrowingTerminal(
        renderError,
        shouldThrowLine: (line) => line.contains('1/2'),
      );

      await expectLater(
        terminice.withTerminal(terminal).progressTask<void>(
          'Progress render',
          total: 2,
          interval: const Duration(seconds: 1),
          run: (progress) {
            progress.increment();
          },
          isCanceled: (error) {
            callbackErrors.add(error);
            return false;
          },
          failure: (error, stackTrace) {
            callbackErrors.add(error);
            return 'classified as task failure';
          },
          cancel: (error, stackTrace) {
            callbackErrors.add(error);
            return 'classified as cancellation';
          },
        ),
        throwsA(same(renderError)),
      );

      expect(callbackErrors, isEmpty);
      _expectCursorRestored(terminal.mockOutput.allOutput);
    });

    test('periodic render failures bypass callbacks and clean up', () async {
      final renderError = StateError('periodic render failed');
      var failureCalls = 0;
      var cancelCalls = 0;
      var isCanceledCalls = 0;
      var renderLineWrites = 0;
      final terminal = _ThrowingTerminal(
        renderError,
        shouldThrowLine: (line) {
          if (!line.contains('Periodic render')) return false;
          renderLineWrites++;
          return renderLineWrites > 1;
        },
      );
      final work = Completer<void>();

      final task = terminice.withTerminal(terminal).task<void>(
            'Periodic render',
            run: () => work.future,
            interval: _asyncRenderInterval,
            isCanceled: (error) {
              isCanceledCalls++;
              return true;
            },
            failure: (error, stackTrace) {
              failureCalls++;
              return 'classified as task failure';
            },
            cancel: (error, stackTrace) {
              cancelCalls++;
              return 'classified as cancellation';
            },
          );

      await expectLater(
        task.timeout(_asyncWaitTimeout),
        throwsA(same(renderError)),
      );
      expect(renderLineWrites, greaterThan(1));
      expect(failureCalls, equals(0));
      expect(cancelCalls, equals(0));
      expect(isCanceledCalls, equals(0));
      _expectCursorRestored(terminal.mockOutput.allOutput);
    });

    test('loadingSpinner whileRunning awaits async work and returns a result',
        () async {
      final terminal = MockTerminal();
      var completed = false;

      final result = await terminice
          .withTerminal(terminal)
          .loadingSpinner('Install')
          .whileRunning<int>(
        () async {
          await Future<void>.delayed(Duration.zero);
          completed = true;
          return 42;
        },
        display: TaskDisplay.plain,
        success: 'installed',
      );

      expect(result, equals(42));
      expect(completed, isTrue);
      expect(terminal.mockOutput.lines, equals(['OK: installed']));
    });

    test('loadingSpinner whileRunning cleans up and rethrows errors', () async {
      final terminal = MockTerminal();
      final error = StateError('boom');

      final task = terminice
          .withTerminal(terminal)
          .loadingSpinner('Install')
          .whileRunning<void>(
        () {
          throw error;
        },
        failure: (error, stackTrace) => 'install failed: $error',
      );

      await expectLater(task, throwsA(same(error)));
      expect(terminal.mockOutput.contains('\x1B[?25h'), isTrue);
      expect(terminal.mockOutput.contains('install failed: Bad state: boom'),
          isTrue);
    });

    test('progressBar whileRunning updates progress and returns a result',
        () async {
      final terminal = MockTerminal();
      TaskProgress? captured;

      final result = await terminice
          .withTerminal(terminal)
          .progressBar('Upload')
          .whileRunning<String>(
        (progress) async {
          progress.increment();
          await Future<void>.delayed(Duration.zero);
          progress.update(current: 4);
          captured = progress;
          return 'artifact';
        },
        total: 4,
        display: TaskDisplay.plain,
        success: 'uploaded',
      );

      expect(result, equals('artifact'));
      expect(captured?.current, equals(4));
      expect(captured?.total, equals(4));
      expect(terminal.mockOutput.lines, equals(['OK: uploaded (4/4, 100%)']));
    });

    test('progressBar trackStream collects values and advances progress',
        () async {
      final terminal = MockTerminal();

      final values = await terminice
          .withTerminal(terminal)
          .progressBar('Upload')
          .trackStream<String>(
            Stream<String>.fromIterable(['a', 'b', 'c']),
            total: 3,
            display: TaskDisplay.plain,
            success: 'uploaded',
          );

      expect(values, equals(['a', 'b', 'c']));
      expect(terminal.mockOutput.lines, equals(['OK: uploaded (3/3, 100%)']));
    });

    test('progressBar trackStream uses controller width for async rendering',
        () async {
      final terminal = MockTerminal();
      TerminalContext.current = terminal;

      final values = await ProgressBar('Upload', width: 5).trackStream<String>(
        Stream<String>.fromIterable(['a', 'b']),
        total: 4,
        display: TaskDisplay.inline,
        interval: const Duration(seconds: 1),
      );

      expect(values, equals(['a', 'b']));
      final output = _stripAnsi(terminal.mockOutput.allOutput);
      final bars = RegExp(r'\[([█░]+)\]').allMatches(output).toList();
      expect(bars, isNotEmpty);
      expect(bars.every((match) => match.group(1)!.length == 5), isTrue);
    });

    test('progressBar width is used for async progress rendering', () async {
      final terminal = MockTerminal();
      TerminalContext.current = terminal;

      await ProgressBar('Upload', width: 5).whileRunning<void>(
        (progress) {
          progress.update(current: 5);
        },
        total: 10,
        display: TaskDisplay.inline,
        interval: const Duration(seconds: 1),
      );

      final output = _stripAnsi(terminal.mockOutput.allOutput);
      final bars = RegExp(r'\[([█░]+)\]').allMatches(output).toList();
      expect(bars, isNotEmpty);
      expect(bars.every((match) => match.group(1)!.length == 5), isTrue);
    });

    test('progressDots maxDots is used for async dot rendering', () async {
      final terminal = MockTerminal();
      TerminalContext.current = terminal;

      await ProgressDots('Wait', maxDots: 5).whileRunning<void>(
        () async {
          await _waitForOutput(
            terminal,
            (output) => _stripAnsi(output).contains('.....'),
          );
        },
        display: TaskDisplay.inline,
        interval: _asyncRenderInterval,
        finalBehavior: TaskFinalBehavior.clear,
      );

      final output = _stripAnsi(terminal.mockOutput.allOutput);
      expect(output, contains('.....'));
      expect(output, isNot(contains('......')));
    });

    test('inlineProgressBar clamps percent display', () {
      expect(
        _renderInlineProgress(current: -4, total: 10),
        equals('Download 0%'),
      );
      expect(
        _renderInlineProgress(current: 14, total: 10),
        equals('Download 100%'),
      );
      expect(
        _renderInlineProgress(current: 4, total: 0),
        equals('Download 0%'),
      );
      expect(
        _renderInlineProgress(current: 4, total: -10),
        equals('Download 0%'),
      );
    });

    test('progressBar clamps percent and count display', () {
      expect(
        _renderProgressBar(current: -4, total: 10),
        allOf(contains('Progress: 0%'), contains('(0/10)')),
      );
      expect(
        _renderProgressBar(current: 14, total: 10),
        allOf(contains('Progress: 100%'), contains('(10/10)')),
      );
      expect(
        _renderProgressBar(current: 4, total: 0),
        allOf(contains('Progress: 0%'), contains('(0/0)')),
      );
      expect(
        _renderProgressBar(current: 4, total: -10),
        allOf(contains('Progress: 0%'), contains('(0/0)')),
      );
    });
  });
}

const _plainProgressTheme = PromptTheme(
  colors: TerminalColors.none,
  features: DisplayFeatures.minimal,
);

String _renderInlineProgress({required int current, required int total}) {
  final terminal = MockTerminal();
  TerminalContext.current = terminal;

  InlineProgressBar('Download', theme: _plainProgressTheme).show(
    current: current,
    total: total,
  );

  return terminal.mockOutput.lines.single;
}

String _renderProgressBar({required int current, required int total}) {
  final terminal = MockTerminal();
  TerminalContext.current = terminal;

  ProgressBar('Download', width: 10, theme: _plainProgressTheme).show(
    current: current,
    total: total,
  );

  return terminal.mockOutput.allOutput;
}

bool _containsAnsi(String output) {
  return RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]').hasMatch(output);
}

String _stripAnsi(String output) {
  return output.replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '');
}

bool _isAscii(String output) {
  return output.runes.every((rune) => rune <= 0x7f);
}

const _asyncRenderInterval = Duration(milliseconds: 10);
const _asyncWaitTimeout = Duration(seconds: 2);
const _asyncPollInterval = Duration(milliseconds: 5);

void _expectCursorRestored(String output) {
  final hideIndex = output.indexOf('\x1B[?25l');
  final showIndex = output.lastIndexOf('\x1B[?25h');
  expect(hideIndex, isNot(equals(-1)));
  expect(showIndex, greaterThan(hideIndex));
}

Future<void> _waitForOutput(
  MockTerminal terminal,
  bool Function(String output) matches,
) async {
  final deadline = DateTime.now().add(_asyncWaitTimeout);
  while (DateTime.now().isBefore(deadline)) {
    if (matches(terminal.mockOutput.allOutput)) return;
    await Future<void>.delayed(_asyncPollInterval);
  }
  fail('Timed out waiting for output:\n${terminal.mockOutput.allOutput}');
}

Future<void> _waitForPostSwitchRender(
  MockTerminal target,
  int targetLineCount,
  MockTerminal other,
  int otherOutputLength,
) async {
  final deadline = DateTime.now().add(_asyncWaitTimeout);
  while (DateTime.now().isBefore(deadline)) {
    if (target.mockOutput.lineCount > targetLineCount ||
        other.mockOutput.allOutput.length > otherOutputLength) {
      return;
    }
    await Future<void>.delayed(_asyncPollInterval);
  }
  fail(
    'Timed out waiting for post-switch render:\n'
    'target: ${target.mockOutput.allOutput}\n'
    'other: ${other.mockOutput.allOutput}',
  );
}

class _TaskCanceled implements Exception {}

class _ThrowingTerminal implements Terminal {
  final MockTerminalInput mockInput = MockTerminalInput();
  final _ThrowingOutput mockOutput;

  _ThrowingTerminal(
    Object error, {
    required bool Function(String line) shouldThrowLine,
  }) : mockOutput = _ThrowingOutput(error, shouldThrowLine);

  @override
  TerminalInput get input => mockInput;

  @override
  TerminalOutput get output => mockOutput;
}

class _ThrowingOutput extends MockTerminalOutput {
  final Object error;
  final bool Function(String line) shouldThrowLine;

  _ThrowingOutput(this.error, this.shouldThrowLine);

  @override
  void writeln([Object? object = '']) {
    final line = object?.toString() ?? '';
    if (shouldThrowLine(line)) throw error;
    super.writeln(object);
  }
}
