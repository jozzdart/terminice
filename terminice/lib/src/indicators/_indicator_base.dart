import 'package:terminice_core/terminice_core.dart';

import '../core/terminice_api.dart';
import '../core/terminice_config.dart';
import '../messages/message_formatting.dart';

/// Shared lifecycle for all framed and inline indicators.
///
/// Subclasses implement [renderTo] for their specific visual output.
/// This mixin manages [RenderOutput] allocation, clearing on re-draw,
/// and the [runWith] session wrapper that hides the cursor.
mixin IndicatorLifecycle {
  RenderOutput? _output;
  bool _started = false;
  Terminal? _terminal;
  TerminiceExecutionMode? _executionMode;
  String? _plainLatest;

  /// Captures the ambient terminal and its automatically detected execution
  /// mode for a directly constructed indicator.
  void initializeAutomatically() {
    final terminal = TerminalContext.current;
    _terminal = terminal;
    _executionMode = TerminiceFallbackMode.auto.executionModeFor(terminal);
  }

  /// Captures the terminal and execution policy for a factory-created
  /// indicator.
  void initializeFromTerminice(Terminice origin) {
    final terminal = origin.terminal ?? TerminalContext.current;
    _terminal = terminal;
    _executionMode = origin.fallbackMode.executionModeFor(terminal);
  }

  void _ensureInitialized() {
    if (_executionMode != null) return;
    initializeAutomatically();
  }

  bool get _usesPlainOutput {
    _ensureInitialized();
    return _executionMode != TerminiceExecutionMode.rich;
  }

  T _withTerminal<T>(T Function() body) {
    _ensureInitialized();
    return TerminalContext.runWith(_terminal!, body);
  }

  /// Renders one indicator update according to the captured execution policy.
  void renderIndicator(
    String plainLine,
    void Function(RenderOutput output) renderRich,
  ) {
    if (_usesPlainOutput) {
      _showPlain(plainLine);
      return;
    }
    _withTerminal(() => renderRich(prepareFrame()));
  }

  /// Prepares a [RenderOutput], clears the previous frame if one was drawn,
  /// and returns the output for the subclass to render into.
  RenderOutput prepareFrame() {
    _output ??= RenderOutput();
    final out = _output!;
    if (_started) out.clear();
    _started = true;
    return out;
  }

  /// Clears the indicator from the terminal and resets internal state.
  void clear() {
    if (_usesPlainOutput) {
      if (!_started) return;
      _writePlainStatus(terminiceInfoStatusLabel, _plainLatest!);
      _resetLifecycleState();
      return;
    }
    _withTerminal(_clearRich);
  }

  /// Runs a callback inside a cursor-hidden terminal session, calling [clear]
  /// when the callback finishes.
  void runSession(
    void Function() body, {
    required String plainStart,
    required String plainSuccess,
  }) {
    if (!_usesPlainOutput) {
      _withTerminal(() {
        final session = TerminalSession(hideCursor: true)..start();
        try {
          body();
        } finally {
          // The callback may replace TerminalContext.current. Keep both frame
          // cleanup and cursor restoration owned by the captured terminal.
          _withTerminal(() {
            try {
              _clearRich();
            } finally {
              session.end();
            }
          });
        }
      });
      return;
    }

    _showPlain(plainStart);
    try {
      body();
    } catch (error, stackTrace) {
      _writePlainStatus(
        terminiceErrorStatusLabel,
        '$plainSuccess failed: $error',
      );
      _resetLifecycleState();
      Error.throwWithStackTrace(error, stackTrace);
    }
    _writePlainStatus(terminiceSuccessStatusLabel, plainSuccess);
    _resetLifecycleState();
  }

  /// Adds the one start line required by task-like indicator sugar while the
  /// existing task renderer remains responsible for its single final line.
  Future<T> runTaskSession<T>(
    Future<T> Function(
      Terminal terminal,
      TerminiceFallbackMode directFallbackMode,
    ) run, {
    required String plainStart,
  }) async {
    final usesPlainOutput = _usesPlainOutput;
    final directFallbackMode = usesPlainOutput
        ? TerminiceFallbackMode.fallback
        : TerminiceFallbackMode.interactive;
    if (!usesPlainOutput) {
      // A task helper uses its own renderer. Clear any manually rendered frame
      // before handing off so its RenderOutput is never abandoned on screen.
      _withTerminal(_clearRich);
      try {
        return await run(_terminal!, directFallbackMode);
      } finally {
        _resetLifecycleState();
      }
    }

    _showPlain(plainStart);
    try {
      return await run(_terminal!, directFallbackMode);
    } finally {
      _resetLifecycleState();
    }
  }

  void _showPlain(String line) {
    _plainLatest = terminalSafeLineText(line);
    if (_started) return;
    _started = true;
    _terminal!.output.writeln(_plainLatest);
  }

  void _writePlainStatus(String status, String message) {
    _terminal!.output.writeln(
      terminiceStatusLine(status, terminalSafeLineText(message)),
    );
  }

  void _resetLifecycleState() {
    _output = null;
    _started = false;
    _plainLatest = null;
  }

  void _clearRich() {
    _output?.clear();
    _resetLifecycleState();
  }
}

/// Returns the task client associated with an indicator controller.
///
/// Controllers created from a [Terminice] extension keep that originating
/// client so async sugar preserves compatibility, fallback, and terminal
/// configuration. Direct constructor usage falls back to the current terminal
/// context with the controller's explicit theme.
Terminice indicatorTaskClient(
  PromptTheme theme,
  Terminice? origin, {
  required Terminal terminal,
  required TerminiceFallbackMode directFallbackMode,
}) {
  return origin ??
      Terminice(
        terminal: terminal,
        config: TerminiceConfig(
          baseTheme: theme,
          fallbackMode: directFallbackMode,
          colorMode: TerminiceColorMode.always,
        ),
      );
}

/// Returns an originating client with its terminal fixed at creation time.
Terminice captureIndicatorClient(Terminice origin) {
  return origin.withTerminal(origin.terminal ?? TerminalContext.current);
}
