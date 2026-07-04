import 'dart:async';

import 'package:terminice_core/terminice_core.dart';

import '../core/terminice_api.dart';
import '../core/terminice_config.dart';
import '../indicators/inline_spinner.dart';
import '../progress_display.dart';

part '_task_display_policy.dart';
part '_task_formatting.dart';
part '_task_renderers.dart';
part '_task_runner.dart';

/// Builds a failure or cancellation message from the thrown error.
typedef TaskErrorMessage = String Function(
  Object error,
  StackTrace stackTrace,
);

/// Returns whether an error should be displayed as a cancellation.
typedef TaskCancelPredicate = bool Function(Object error);

/// Rendering mode used by [AsyncTaskExtensions.task] and progress helpers.
enum TaskDisplay {
  /// Pick the best display for the current terminal and configuration.
  auto,

  /// Render an animated inline spinner when the terminal supports it.
  inline,

  /// Render simple line output without ANSI cursor control or raw mode.
  plain,
}

/// Controls what remains on screen when a task finishes.
enum TaskFinalBehavior {
  /// Leave one final status line.
  persist,

  /// Clear the task display when the task finishes.
  clear,
}

/// Running indicator used by inline task renderers.
enum TaskRunningIndicator {
  /// Animate using a spinner frame set.
  spinner,

  /// Animate by cycling a growing text dot sequence.
  dots,
}

/// Mutable progress state passed to [AsyncTaskExtensions.progressTask].
class TaskProgress {
  int _current;
  int _total;
  String? _message;
  final void Function(TaskProgress progress)? _onChanged;

  TaskProgress._({
    required int total,
    int current = 0,
    String? message,
    void Function(TaskProgress progress)? onChanged,
  })  : _current = 0,
        _total = _validateTotal(total),
        _message = message,
        _onChanged = onChanged {
    _current = _clampCurrent(current, _total);
  }

  /// Current completed units, clamped to the inclusive `0..total` range.
  int get current => _current;

  /// Total units expected for the task.
  int get total => _total;

  /// Optional detail shown beside the prompt while the task is running.
  String? get message => _message;

  /// Completion ratio between `0` and `1`.
  double get ratio => _current / _total;

  /// Whether [current] has reached [total].
  bool get isComplete => _current >= _total;

  /// Updates any part of the progress state.
  ///
  /// [total] must be greater than zero. [current] is clamped to the current
  /// total after all updates are applied. Passing `null` for [message] leaves
  /// the existing message unchanged.
  void update({int? current, int? total, String? message}) {
    var changed = false;

    if (total != null) {
      final nextTotal = _validateTotal(total);
      if (nextTotal != _total) {
        _total = nextTotal;
        changed = true;
      }
    }

    final nextCurrent = _clampCurrent(current ?? _current, _total);
    if (nextCurrent != _current) {
      _current = nextCurrent;
      changed = true;
    }

    if (message != null && message != _message) {
      _message = message;
      changed = true;
    }

    if (changed) _onChanged?.call(this);
  }

  /// Advances [current] by [by], clamping to the inclusive `0..total` range.
  void increment([int by = 1]) {
    update(current: _current + by);
  }
}

/// Adds high-level async task rendering to [Terminice].
extension AsyncTaskExtensions on Terminice {
  /// Runs [run] while rendering task progress and returns its typed result.
  ///
  /// Synchronous throws and asynchronous errors both render failure or
  /// cancellation status before being rethrown with their original stack trace.
  Future<T> task<T>(
    String prompt, {
    required FutureOr<T> Function() run,
    String? message,
    String? success,
    TaskErrorMessage? failure,
    TaskErrorMessage? cancel,
    TaskCancelPredicate? isCanceled,
    Duration interval = const Duration(milliseconds: 80),
    SpinnerStyle style = SpinnerStyle.dots,
    TaskRunningIndicator indicator = TaskRunningIndicator.spinner,
    int maxDots = 3,
    TaskDisplay display = TaskDisplay.auto,
    TaskFinalBehavior finalBehavior = TaskFinalBehavior.persist,
  }) async {
    final validatedMaxDots = _validateMaxDots(maxDots);
    activate();

    final terminal = TerminalContext.current;
    final renderer = _createTaskRenderer(
      terminice: this,
      terminal: terminal,
      prompt: prompt,
      message: message,
      interval: interval,
      style: style,
      indicator: indicator,
      maxDots: validatedMaxDots,
      display: display,
      finalBehavior: finalBehavior,
    );

    return _runTask<T>(
      prompt: prompt,
      renderer: renderer,
      run: run,
      success: success,
      failure: failure,
      cancel: cancel,
      isCanceled: isCanceled,
    );
  }

  /// Runs [run] with a progress handle while rendering determinate progress.
  ///
  /// The returned value and error semantics mirror [task]. Invalid totals are
  /// rejected before the task starts, and displayed progress is clamped to the
  /// inclusive `0..total` range.
  Future<T> progressTask<T>(
    String prompt, {
    required int total,
    required FutureOr<T> Function(TaskProgress progress) run,
    String? message,
    String? success,
    TaskErrorMessage? failure,
    TaskErrorMessage? cancel,
    TaskCancelPredicate? isCanceled,
    TaskDisplay display = TaskDisplay.auto,
    TaskFinalBehavior finalBehavior = TaskFinalBehavior.persist,
    Duration interval = const Duration(milliseconds: 80),
    int progressWidth = 12,
  }) async {
    _validateTotal(total);
    final validatedProgressWidth = _validateProgressWidth(progressWidth);
    activate();

    final terminal = TerminalContext.current;
    final renderer = _createProgressTaskRenderer(
      terminice: this,
      terminal: terminal,
      prompt: prompt,
      interval: interval,
      display: display,
      finalBehavior: finalBehavior,
      progressWidth: validatedProgressWidth,
    );
    final progress = TaskProgress._(
      total: total,
      message: message,
      onChanged: (progress) => _notifyProgressChanged(renderer, progress),
    );
    renderer.progress(progress);

    return _runTask<T>(
      prompt: prompt,
      renderer: renderer,
      run: () => run(progress),
      success: success,
      failure: failure,
      cancel: cancel,
      isCanceled: isCanceled,
    );
  }

  /// Collects [source] into a list while advancing progress for each event.
  ///
  /// This helper keeps stream tracking predictable: the returned future
  /// completes with every streamed value in order, and any source error is
  /// rendered then rethrown using the same behavior as [task].
  Future<List<T>> trackStream<T>(
    String prompt,
    Stream<T> source, {
    required int total,
    String? message,
    String? success,
    TaskErrorMessage? failure,
    TaskErrorMessage? cancel,
    TaskCancelPredicate? isCanceled,
    TaskDisplay display = TaskDisplay.auto,
    TaskFinalBehavior finalBehavior = TaskFinalBehavior.persist,
    Duration interval = const Duration(milliseconds: 80),
    int progressWidth = 12,
  }) {
    return progressTask<List<T>>(
      prompt,
      total: total,
      message: message,
      success: success,
      failure: failure,
      cancel: cancel,
      isCanceled: isCanceled,
      display: display,
      finalBehavior: finalBehavior,
      interval: interval,
      progressWidth: progressWidth,
      run: (progress) async {
        final values = <T>[];
        await for (final value in source) {
          values.add(value);
          progress.increment();
        }
        return values;
      },
    );
  }
}
