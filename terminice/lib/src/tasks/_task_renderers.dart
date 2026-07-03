part of 'async_task.dart';

abstract class _TaskRenderer {
  Future<_RenderFailure>? get renderFailure => null;

  void start();

  void stop() {}

  void success(String message);

  void failure(String message);

  void cancel(String message);

  void progress(TaskProgress progress) {}

  void recordRenderFailure(Object error, StackTrace stackTrace) {}
}

abstract class _PlainStatusTaskRenderer extends _TaskRenderer {
  final TerminalOutput output;
  final TaskFinalBehavior finalBehavior;

  _PlainStatusTaskRenderer({
    required this.output,
    required this.finalBehavior,
  });

  @override
  void start() {}

  @override
  void success(String message) {
    _writeFinal(_taskSuccessStatus, message);
  }

  @override
  void failure(String message) {
    _writeFinal(_taskFailureStatus, message);
  }

  @override
  void cancel(String message) {
    _writeFinal(_taskCancelStatus, message);
  }

  void _writeFinal(String status, String message) {
    if (finalBehavior == TaskFinalBehavior.persist) {
      output.writeln(_statusLine(status, message, _finalSuffix()));
    }
  }

  String _finalSuffix() => '';
}

class _PlainTaskRenderer extends _PlainStatusTaskRenderer {
  _PlainTaskRenderer({
    required super.output,
    required super.finalBehavior,
  });
}

class _PlainProgressTaskRenderer extends _PlainStatusTaskRenderer {
  TaskProgress? _progress;

  _PlainProgressTaskRenderer({
    required super.output,
    required super.finalBehavior,
  });

  @override
  void progress(TaskProgress progress) {
    _progress = progress;
  }

  @override
  String _finalSuffix() {
    final progress = _progress;
    if (progress == null) return '';
    return ' (${_progressSummary(progress)})';
  }
}

abstract class _AnimatedTaskRenderer extends _TaskRenderer {
  final Terminal terminal;
  final Duration interval;
  final PromptTheme theme;
  final TaskFinalBehavior finalBehavior;

  final RenderOutput _output = RenderOutput();
  final TerminalSession _session = TerminalSession(hideCursor: true);
  final Completer<_RenderFailure> _renderFailure =
      Completer<_RenderFailure>.sync();

  Timer? _timer;
  int _frame = 0;
  bool _finished = false;

  _AnimatedTaskRenderer({
    required this.terminal,
    required this.interval,
    required this.theme,
    required this.finalBehavior,
  });

  @override
  Future<_RenderFailure> get renderFailure => _renderFailure.future;

  @override
  void start() {
    _withTerminal(_session.start);
    _renderRunning();
    _timer = Timer.periodic(interval, (_) {
      try {
        _renderRunning();
      } catch (error, stackTrace) {
        _recordRenderFailure(error, stackTrace);
      }
    });
  }

  @override
  void stop() {
    _finished = true;
    _timer?.cancel();
    _timer = null;
    _endSession(ignoreErrors: true);
  }

  @override
  void success(String message) {
    _finish('${theme.accent}✓${theme.reset} $message');
  }

  @override
  void failure(String message) {
    _finish('${theme.error}✗${theme.reset} $message');
  }

  @override
  void cancel(String message) {
    _finish('${theme.warn}-${theme.reset} $message');
  }

  void _renderRunning() {
    if (_finished) return;

    _withTerminal(() {
      _output.clear();
      writeRunning(_output);
    });
  }

  void writeRunning(RenderOutput output);

  void _finish(String finalLine) {
    _finished = true;
    _timer?.cancel();
    _timer = null;

    Object? renderError;
    StackTrace? renderStackTrace;

    try {
      _withTerminal(() {
        _output.clear();
        if (finalBehavior == TaskFinalBehavior.persist) {
          _output.writeln(finalLine);
        }
      });
    } catch (error, stackTrace) {
      renderError = error;
      renderStackTrace = stackTrace;
    } finally {
      _endSession(ignoreErrors: renderError != null);
    }

    if (renderError != null) {
      Error.throwWithStackTrace(renderError, renderStackTrace!);
    }
  }

  T _withTerminal<T>(T Function() body) {
    final previous = TerminalContext.current;
    TerminalContext.current = terminal;
    try {
      return body();
    } finally {
      TerminalContext.current = previous;
    }
  }

  void _recordRenderFailure(Object error, StackTrace stackTrace) {
    if (_renderFailure.isCompleted) return;

    _finished = true;
    _timer?.cancel();
    _timer = null;
    _cleanupAfterRenderFailure();
    _renderFailure.complete(_RenderFailure(error, stackTrace));
  }

  @override
  void recordRenderFailure(Object error, StackTrace stackTrace) {
    _recordRenderFailure(error, stackTrace);
  }

  void _cleanupAfterRenderFailure() {
    try {
      _withTerminal(() {
        try {
          _output.clear();
        } catch (_) {
          // Keep going so cursor/session cleanup still has a chance to run.
        }
        _endSession(ignoreErrors: true);
      });
    } catch (_) {
      // The original render failure is the error reported to the task future.
    }
  }

  void _endSession({required bool ignoreErrors}) {
    try {
      _withTerminal(() {
        if (_session.isActive) _session.end();
      });
    } catch (_) {
      if (!ignoreErrors) rethrow;
    }
  }
}

class _InlineTaskRenderer extends _AnimatedTaskRenderer {
  final String prompt;
  final String? message;
  final SpinnerStyle style;
  final TaskRunningIndicator indicator;
  final int maxDots;

  _InlineTaskRenderer({
    required super.terminal,
    required this.prompt,
    required this.message,
    required super.interval,
    required this.style,
    required this.indicator,
    required this.maxDots,
    required super.theme,
    required super.finalBehavior,
  });

  @override
  void writeRunning(RenderOutput output) {
    if (indicator == TaskRunningIndicator.dots) {
      final dots = _dotsFrame(_frame, maxDots);
      _frame++;
      output.writeln(
        '${theme.dim}${_runningText(prompt, message)}${theme.reset} '
        '${theme.accent}$dots${theme.reset}',
      );
      return;
    }

    final spinner = _spinnerFrame(style, _frame);
    _frame++;

    output.writeln(
      '${theme.accent}$spinner${theme.reset} ${theme.dim}'
      '${_runningText(prompt, message)}${theme.reset}',
    );
  }
}

class _InlineProgressTaskRenderer extends _AnimatedTaskRenderer {
  final String prompt;
  final SpinnerStyle style;
  final int width;

  TaskProgress? _progress;

  _InlineProgressTaskRenderer({
    required super.terminal,
    required this.prompt,
    required super.interval,
    required this.style,
    required super.theme,
    required super.finalBehavior,
    required this.width,
  });

  @override
  void progress(TaskProgress progress) {
    _progress = progress;
    if (_session.isActive) _renderRunning();
  }

  @override
  void writeRunning(RenderOutput output) {
    final spinner = _spinnerFrame(style, _frame);
    _frame++;

    final progress = _progress;
    if (progress == null) {
      output.writeln('${theme.accent}$spinner${theme.reset} $prompt');
      return;
    }

    output.writeln(
      '${theme.accent}$spinner${theme.reset} ${theme.dim}'
      '${_runningText(prompt, progress.message)}${theme.reset} '
      '${theme.accent}${_progressBar(progress, width)}${theme.reset} '
      '${theme.dim}${_progressSummary(progress)}${theme.reset}',
    );
  }
}
