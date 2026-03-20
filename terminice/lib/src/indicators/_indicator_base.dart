import 'package:terminice_core/terminice_core.dart';

/// Shared lifecycle for all framed and inline indicators.
///
/// Subclasses implement [renderTo] for their specific visual output.
/// This mixin manages [RenderOutput] allocation, clearing on re-draw,
/// and the [runWith] session wrapper that hides the cursor.
mixin IndicatorLifecycle {
  RenderOutput? _output;
  bool _started = false;

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
    _output?.clear();
    _output = null;
    _started = false;
  }

  /// Runs a callback inside a cursor-hidden terminal session, calling [clear]
  /// when the callback finishes.
  void runSession(void Function() body) {
    TerminalSession(hideCursor: true).run(() {
      body();
      clear();
    });
  }
}
