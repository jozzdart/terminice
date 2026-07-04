import 'dart:async';

import 'package:terminice/terminice.dart';
import 'package:terminice_core/testing.dart';

/// Opt-in harness for testing high-level Terminice CLIs.
///
/// The tester owns a [MockTerminal], configures a [Terminice] instance to use
/// it, and restores the previous [TerminalContext] terminal after every run.
class TerminiceTester {
  /// Terminice instance configured for this tester's terminal and mode.
  final Terminice terminice;

  /// Fake terminal used for input, output, and terminal capability checks.
  final MockTerminal terminal;

  TerminiceTester._({
    required this.terminice,
    required this.terminal,
  });

  /// Creates a tester for rich interactive prompts.
  factory TerminiceTester.interactive({
    Terminice? base,
    TerminalScript? script,
    int columns = 80,
    int rows = 24,
  }) {
    final terminal = _mockTerminal(columns: columns, rows: rows);
    if (script != null) terminal.queueScript(script);

    return _build(
      base: base,
      terminal: terminal,
      configure: (terminice) => terminice.interactive,
    );
  }

  /// Creates a tester that always exercises high-level line-mode fallback.
  factory TerminiceTester.fallback({
    Terminice? base,
    Iterable<String> lines = const [],
    int columns = 80,
    int rows = 24,
  }) {
    final terminal = _mockTerminal(columns: columns, rows: rows)
      ..queueScript(TerminalScript.lines(lines));

    return _build(
      base: base,
      terminal: terminal,
      configure: (terminice) => terminice.fallback,
    );
  }

  /// Creates a tester whose terminal streams report that no TTY is available.
  ///
  /// High-level prompts configured with automatic fallback will use line-mode
  /// behavior through the normal centralized fallback decision.
  factory TerminiceTester.nonInteractive({
    Terminice? base,
    Iterable<String> lines = const [],
    int columns = 80,
    int rows = 24,
  }) {
    final terminal = _mockTerminal(columns: columns, rows: rows)
      ..queueScript(TerminalScript.lines(lines));
    terminal.mockInput.setHasTerminal(false);
    terminal.mockOutput.setHasTerminal(false);

    return _build(
      base: base,
      terminal: terminal,
      configure: (terminice) => terminice.autoFallback,
    );
  }

  static TerminiceTester _build({
    required Terminice? base,
    required MockTerminal terminal,
    required Terminice Function(Terminice terminice) configure,
  }) {
    return TerminalContext.runWith(terminal, () {
      final configured = configure(base ?? Terminice()).withTerminal(terminal);
      return TerminiceTester._(terminice: configured, terminal: terminal);
    });
  }

  /// Captured output from this tester's terminal.
  TerminalOutputSnapshot get output => terminal.outputSnapshot;

  /// Adds scripted terminal input after construction.
  void queue(TerminalScript script) {
    terminal.queueScript(script);
  }

  /// Runs [body] with this tester's terminal active.
  ///
  /// The previously active terminal is restored whether [body] succeeds or
  /// throws.
  T run<T>(T Function(Terminice t) body) {
    return TerminalContext.runWith(terminal, () => body(terminice));
  }

  /// Runs asynchronous [body] with this tester's terminal active.
  ///
  /// The previously active terminal is restored after the returned future
  /// completes, whether it succeeds or fails.
  Future<T> runAsync<T>(FutureOr<T> Function(Terminice t) body) {
    return TerminalContext.runWithAsync(terminal, () => body(terminice));
  }
}

MockTerminal _mockTerminal({
  required int columns,
  required int rows,
}) {
  final terminal = MockTerminal();
  terminal.mockOutput.setDimensions(columns: columns, rows: rows);
  return terminal;
}
