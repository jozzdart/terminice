import 'dart:async';

import 'package:terminice/terminice.dart';
import 'package:terminice/testing.dart' show MockTerminal;

const _accent = '\x1B[38;5;201m';
const _theme = PromptTheme(
  colors: TerminalColors(accent: _accent, highlight: _accent),
);

Future<void> main() async {
  final directBar = await _capture((terminal) async {
    await ProgressBar('Bar', theme: _theme).whileRunning<void>(
      (progress) async {
        progress.increment();
        await Future<void>.delayed(const Duration(milliseconds: 5));
      },
      total: 2,
      display: TaskDisplay.inline,
      interval: const Duration(milliseconds: 1),
      finalBehavior: TaskFinalBehavior.clear,
    );
  });
  final directDots = await _capture((terminal) async {
    await ProgressDots('Dots', theme: _theme).whileRunning<void>(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
      display: TaskDisplay.inline,
      interval: const Duration(milliseconds: 1),
      finalBehavior: TaskFinalBehavior.clear,
    );
  });
  final directSpinner = await _capture((terminal) async {
    await LoadingSpinner('Spinner', theme: _theme).whileRunning<void>(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
      display: TaskDisplay.inline,
      interval: const Duration(milliseconds: 1),
      finalBehavior: TaskFinalBehavior.clear,
    );
  });
  final autoClient = await _capture((terminal) async {
    await terminice
        .themed(_theme)
        .withTerminal(terminal)
        .progressBar('Auto')
        .whileRunning<void>(
          (progress) => Future<void>.delayed(const Duration(milliseconds: 5)),
          total: 1,
          display: TaskDisplay.inline,
          interval: const Duration(milliseconds: 1),
          finalBehavior: TaskFinalBehavior.clear,
        );
  });
  final neverClient = await _capture((terminal) async {
    await terminice
        .themed(_theme)
        .withColorMode(TerminiceColorMode.never)
        .withTerminal(terminal)
        .progressDots('Never')
        .whileRunning<void>(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
          display: TaskDisplay.inline,
          interval: const Duration(milliseconds: 1),
          finalBehavior: TaskFinalBehavior.clear,
        );
  });

  print([
    directBar,
    directDots,
    directSpinner,
    autoClient,
    neverClient,
  ].join(','));
}

Future<bool> _capture(
  Future<void> Function(MockTerminal terminal) run,
) async {
  final terminal = MockTerminal();
  TerminalContext.current = terminal;
  await run(terminal);
  return terminal.mockOutput.allOutput.contains(_accent);
}
