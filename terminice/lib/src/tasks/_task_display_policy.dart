part of 'async_task.dart';

_TaskRenderer _createTaskRenderer({
  required Terminice terminice,
  required Terminal terminal,
  required String prompt,
  required String? message,
  required Duration interval,
  required SpinnerStyle style,
  required TaskRunningIndicator indicator,
  required int maxDots,
  required TaskDisplay display,
  required TaskFinalBehavior finalBehavior,
}) {
  if (_shouldUsePlainRenderer(terminice, terminal, display)) {
    return _PlainTaskRenderer(
      output: terminal.output,
      finalBehavior: finalBehavior,
    );
  }

  return _InlineTaskRenderer(
    terminal: terminal,
    prompt: prompt,
    message: message,
    interval: interval,
    style: style,
    indicator: indicator,
    maxDots: maxDots,
    theme: terminice.defaultTheme,
    finalBehavior: finalBehavior,
  );
}

_TaskRenderer _createProgressTaskRenderer({
  required Terminice terminice,
  required Terminal terminal,
  required String prompt,
  required Duration interval,
  required TaskDisplay display,
  required TaskFinalBehavior finalBehavior,
  required int progressWidth,
}) {
  if (_shouldUsePlainRenderer(terminice, terminal, display)) {
    return _PlainProgressTaskRenderer(
      output: terminal.output,
      finalBehavior: finalBehavior,
    );
  }

  return _InlineProgressTaskRenderer(
    terminal: terminal,
    prompt: prompt,
    interval: interval,
    style: SpinnerStyle.dots,
    theme: terminice.defaultTheme,
    finalBehavior: finalBehavior,
    width: progressWidth,
  );
}

bool _shouldUsePlainRenderer(
  Terminice terminice,
  Terminal terminal,
  TaskDisplay display,
) {
  if (display == TaskDisplay.plain) return true;
  if (!_terminalCanAnimate(terminal)) return true;
  if (terminice.compatibility != TerminalCompatibility.modern) return true;
  if (terminice.fallbackMode == TerminiceFallbackMode.fallback) return true;
  if (display == TaskDisplay.auto && terminice.shouldUseFallback) return true;
  return false;
}

bool _terminalCanAnimate(Terminal terminal) {
  try {
    return terminal.input.hasTerminal && terminal.output.hasTerminal;
  } catch (_) {
    return false;
  }
}
