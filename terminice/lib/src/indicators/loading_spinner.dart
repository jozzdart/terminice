import 'dart:async';

import 'package:terminice_core/terminice_core.dart';

import '../core/terminice_api.dart';
import '../tasks/async_task.dart';
import '_indicator_base.dart';
import 'inline_spinner.dart';

/// Adds the [loadingSpinner] method to the [Terminice] instance.
extension LoadingSpinnerExtensions on Terminice {
  /// Creates a themed loading spinner with customizable message and style.
  ///
  /// ```dart
  /// final spinner = terminice.loadingSpinner('Loading');
  /// spinner.show(0);
  /// // ... do work ...
  /// spinner.show(1);
  /// spinner.clear();
  /// ```
  ///
  /// The [prompt] is the label displayed above the spinner.
  /// The [message] is the text displayed next to the spinner.
  /// The [style] determines the visual appearance of the spinner.
  LoadingSpinner loadingSpinner(
    String prompt, {
    String message = 'Loading',
    SpinnerStyle style = SpinnerStyle.dots,
  }) {
    return LoadingSpinner._fromTerminice(
      prompt,
      this,
      message: message,
      style: style,
      theme: defaultTheme,
    );
  }
}

/// Theme-aware loading spinner with multiple visual styles.
///
/// Styles: dots (braille), bars (rising/falling), arcs (quarter/half circles).
///
/// **Usage:**
///
/// 1. **Static display** (caller controls updates):
/// ```dart
/// final spinner = LoadingSpinner('Loading');
/// spinner.show(frame: 0);
/// // ... do work ...
/// spinner.show(frame: 1);
/// spinner.clear();
/// ```
///
/// 2. **With callback** (caller drives progress):
/// ```dart
/// LoadingSpinner('Processing').runWith((tick) {
///   for (int i = 0; i < 10; i++) {
///     doWork();
///     tick();
///   }
/// });
/// ```
class LoadingSpinner with IndicatorLifecycle {
  /// The label displayed above the spinner.
  final String prompt;

  /// The text displayed next to the spinner.
  final String message;

  /// The visual appearance of the spinner.
  final SpinnerStyle style;

  /// The theme controlling the colors used for the spinner and text.
  final PromptTheme theme;

  final Terminice? _taskClient;

  /// Creates a loading spinner.
  ///
  /// The [prompt] is the label displayed above the spinner.
  /// The [message] is the text displayed next to the spinner.
  /// The [style] determines the visual appearance of the spinner.
  /// The [theme] controls the colors used for the spinner and text.
  LoadingSpinner(
    this.prompt, {
    this.message = 'Loading',
    this.style = SpinnerStyle.dots,
    this.theme = PromptTheme.dark,
  }) : _taskClient = null;

  LoadingSpinner._fromTerminice(
    this.prompt,
    this._taskClient, {
    this.message = 'Loading',
    this.style = SpinnerStyle.dots,
    this.theme = PromptTheme.dark,
  });

  /// Shows the spinner at the given frame.
  void show(int frame) {
    final out = prepareFrame();
    _render(out, frame);
  }

  /// Runs the spinner with a callback that provides tick updates.
  void runWith(void Function(void Function() tick) callback) {
    runSession(() {
      int frame = 0;
      callback(() {
        show(frame++);
      });
    });
  }

  /// Runs [run] while showing this spinner and returns its typed result.
  ///
  /// Errors are rendered with the same cleanup and rethrow behavior as
  /// [AsyncTaskExtensions.task].
  Future<T> whileRunning<T>(
    FutureOr<T> Function() run, {
    String? message,
    String? success,
    TaskErrorMessage? failure,
    TaskErrorMessage? cancel,
    TaskCancelPredicate? isCanceled,
    Duration interval = const Duration(milliseconds: 80),
    TaskDisplay display = TaskDisplay.auto,
    TaskFinalBehavior finalBehavior = TaskFinalBehavior.persist,
  }) {
    return indicatorTaskClient(theme, _taskClient).task<T>(
      prompt,
      run: run,
      message: message ?? this.message,
      success: success,
      failure: failure,
      cancel: cancel,
      isCanceled: isCanceled,
      interval: interval,
      style: style,
      display: display,
      finalBehavior: finalBehavior,
    );
  }

  void _render(RenderOutput out, int frameIndex) {
    final frames = InlineSpinner.framesForStyle(style);
    final widgetFrame = FrameView(title: prompt, theme: theme);

    final color = (frameIndex % 2 == 0) ? theme.accent : theme.highlight;

    widgetFrame.showTo(out, (ctx) {
      final spin = frames[frameIndex % frames.length];
      ctx.gutterLine(
          '${theme.dim}$message${theme.reset}  ${theme.bold}$color$spin${theme.reset}');
    });
    final styleName = style.name;

    out.writeln(HintFormat.bullets([
      'Theme-aware spinner',
      'Style: $styleName',
    ], theme, dim: true));
  }
}
