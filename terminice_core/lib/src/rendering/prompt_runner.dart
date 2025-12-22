import 'package:terminice_core/terminice_core.dart';

/// Result from a prompt indicating whether it was confirmed or cancelled.
enum PromptResult { confirmed, cancelled }

// ============================================================================
// CORE COMPONENTS (can be used independently or composed)
// ============================================================================

/// A line-tracking output buffer that only clears what it wrote.
///
/// Instead of clearing the entire terminal, this tracks how many lines
/// were written and uses cursor movement to clear just those lines
/// before re-rendering. This preserves any terminal content that existed
/// before the prompt/view started.
///
/// **Standalone usage** (for simple display views):
/// ```dart
/// final out = RenderOutput();
/// out.writeln('Line 1');
/// out.writeln('Line 2');
/// // Content stays visible, terminal history preserved
/// ```
///
/// **With updates** (for updating displays):
/// ```dart
/// final out = RenderOutput();
/// out.writeln('Step 1');
/// // ... do work ...
/// out.clear();
/// out.writeln('Step 2');
/// ```
class RenderOutput {
  int _lineCount = 0;

  /// Number of lines written since the last clear.
  int get lineCount => _lineCount;

  /// Writes a line to the terminal output and tracks it.
  void writeln([String line = '']) {
    TerminalContext.output.writeln(line);
    // Count the line itself plus any embedded newlines
    _lineCount += 1 + '\n'.allMatches(line).length;
  }

  /// Writes text without a trailing newline (newlines in text are counted).
  void write(String text) {
    TerminalContext.output.write(text);
    _lineCount += '\n'.allMatches(text).length;
  }

  /// Clears only the lines we wrote by moving cursor up and erasing.
  /// This preserves terminal content from before the prompt/view started.
  /// Call this before re-rendering to update the display.
  void clear() {
    if (_lineCount > 0) {
      // Move cursor up by the number of lines we wrote
      TerminalContext.output.write('\x1B[${_lineCount}A');
      // Clear from cursor to end of screen (only our content)
      TerminalContext.output.write('\x1B[0J');
    }
    _lineCount = 0;
  }
}

/// Manages terminal session state (cursor visibility, raw mode).
///
/// This is a composable component that can be used:
/// - Directly for display views that need cursor control
/// - As part of [PromptRunner] for interactive prompts
///
/// **For display views** (no key input needed):
/// ```dart
/// final session = TerminalSession(hideCursor: true);
/// final out = RenderOutput();
///
/// session.run(() {
///   out.writeln('Loading...');
///   // ... do work ...
///   out.clear();
///   out.writeln('Done!');
/// });
/// ```
class TerminalSession {
  /// Whether to hide the cursor during the session.
  final bool hideCursor;

  /// Whether to enter raw terminal mode (for key input).
  final bool rawMode;

  TerminalModeState? _termState;
  bool _active = false;

  TerminalSession({
    this.hideCursor = false,
    this.rawMode = false,
  });

  /// Whether the session is currently active.
  bool get isActive => _active;

  /// Starts the terminal session.
  void start() {
    if (_active) return;
    _active = true;
    if (rawMode) _termState = TerminalControl.enterRaw();
    if (hideCursor) TerminalControl.hideCursor();
  }

  /// Ends the terminal session and restores state.
  void end() {
    if (!_active) return;
    _termState?.restore();
    if (hideCursor) TerminalControl.showCursor();
    _active = false;
  }

  /// Runs [body] within this session, ensuring cleanup on exit.
  T run<T>(T Function() body) {
    start();
    try {
      return body();
    } finally {
      end();
    }
  }

  /// Runs [body] with a [RenderOutput], clearing output at the end if requested.
  T runWithOutput<T>(
    T Function(RenderOutput out) body, {
    bool clearOnEnd = false,
  }) {
    final out = RenderOutput();
    start();
    try {
      return body(out);
    } finally {
      end();
      if (clearOnEnd) out.clear();
    }
  }
}

/// Configuration for end-of-prompt behavior.
class EndBehavior {
  /// Whether to clear the rendered output when the prompt ends.
  /// If false, the final render remains visible.
  final bool clearOnEnd;

  const EndBehavior({this.clearOnEnd = true});

  /// Default: clears prompt output when done (returns to clean terminal).
  static const EndBehavior clear = EndBehavior(clearOnEnd: true);

  /// Keeps the final render visible after the prompt ends.
  static const EndBehavior persist = EndBehavior(clearOnEnd: false);
}

// ============================================================================
// PROMPT RUNNER (composes TerminalSession + RenderOutput + key handling)
// ============================================================================

/// A centralized runner for interactive terminal prompts.
///
/// Composes [TerminalSession] + [RenderOutput] + key handling to provide
/// a complete solution for interactive prompts.
///
/// **Key feature**: Never clears the entire terminal. Only clears lines
/// written by the prompt/view itself, preserving any existing terminal content.
///
/// Usage:
/// ```dart
/// final runner = PromptRunner();
/// final result = runner.run(
///   render: (out) {
///     out.writeln('My prompt content');
///     out.writeln('More content');
///   },
///   onKey: (event) {
///     if (event.type == KeyEventType.enter) return PromptResult.confirmed;
///     if (event.type == KeyEventType.esc) return PromptResult.cancelled;
///     return null; // continue loop
///   },
/// );
/// ```
class PromptRunner {
  /// Whether to hide the terminal cursor during the prompt.
  final bool hideCursor;

  /// Controls what happens when the prompt ends.
  final EndBehavior endBehavior;

  /// Optional callback invoked before cleanup (e.g., for final styling).
  final void Function()? onBeforeCleanup;

  /// Optional callback invoked after cleanup completes.
  final void Function()? onAfterCleanup;

  PromptRunner({
    this.hideCursor = true,
    this.endBehavior = EndBehavior.clear,
    this.onBeforeCleanup,
    this.onAfterCleanup,
  });

  /// Creates the terminal session for this runner.
  TerminalSession _createSession() => TerminalSession(
        hideCursor: hideCursor,
        rawMode: true,
      );

  /// Runs the prompt loop synchronously.
  ///
  /// [render] is called with a [RenderOutput] to write content.
  /// [onKey] handles key events and returns:
  ///   - `PromptResult.confirmed` to exit with success
  ///   - `PromptResult.cancelled` to exit with cancellation
  ///   - `null` to continue the loop
  PromptResult run({
    required void Function(RenderOutput out) render,
    required PromptResult? Function(KeyEvent event) onKey,
  }) {
    final session = _createSession();
    final output = RenderOutput();

    session.start();

    // Initial render (no clearing needed - nothing written yet)
    render(output);

    PromptResult result = PromptResult.cancelled;

    try {
      while (true) {
        final event = KeyEventReader.read();
        final action = onKey(event);

        if (action != null) {
          result = action;
          break;
        }

        // Clear only our output, then re-render
        output.clear();
        render(output);
      }
    } finally {
      onBeforeCleanup?.call();
      session.end();
      onAfterCleanup?.call();
    }

    // Optionally clear our final output
    if (endBehavior.clearOnEnd) {
      output.clear();
    }

    return result;
  }

  /// Runs custom logic within a managed terminal session.
  ///
  /// This gives you full control over the render/input flow while still
  /// benefiting from centralized terminal management and [RenderOutput]
  /// for partial clearing.
  ///
  /// Use this for prompts or views that need:
  /// - Entry/exit styling
  /// - Custom render timing
  /// - Non-standard input loops
  ///
  /// Example:
  /// ```dart
  /// final runner = PromptRunner();
  /// final value = runner.runCustom((out) {
  ///   // Render with entry styling
  ///
  ///   // Main input loop
  ///   while (true) {
  ///     final ev = KeyEventReader.read();
  ///     if (ev.type == KeyEventType.enter) break;
  ///     // handle keys...
  ///     out.clear();
  ///     renderSlider(out);
  ///   }
  ///
  ///   // Render with exit styling
  ///   out.clear();
  ///
  ///   return finalValue;
  /// });
  /// ```
  T runCustom<T>(T Function(RenderOutput out) body) {
    final session = _createSession();
    final output = RenderOutput();

    session.start();

    try {
      return body(output);
    } finally {
      onBeforeCleanup?.call();
      session.end();
      onAfterCleanup?.call();

      // Optionally clear our final output
      if (endBehavior.clearOnEnd) {
        output.clear();
      }
    }
  }

  /// Runs the prompt loop using a [KeyBindings] instance.
  ///
  /// This is the recommended way to use PromptRunner with the KeyBindings system.
  /// It automatically handles the mapping from KeyActionResult to PromptResult.
  ///
  /// Example:
  /// ```dart
  /// final bindings = KeyBindings.togglePrompt(
  ///   onToggle: () => selectedYes = !selectedYes,
  /// );
  ///
  /// final result = runner.runWithBindings(
  ///   render: (out) => renderPrompt(out),
  ///   bindings: bindings,
  /// );
  /// ```
  PromptResult runWithBindings({
    required void Function(RenderOutput out) render,
    required KeyBindings bindings,
  }) {
    return run(
      render: render,
      onKey: (event) {
        final result = bindings.handle(event);
        return toPromptResult(result);
      },
    );
  }

  /// Converts the result to PromptRunner's PromptResult.
  ///
  /// - `confirmed` → PromptResult.confirmed
  /// - `cancelled` → PromptResult.cancelled
  /// - `handled` / `ignored` → null (continue loop)
  static PromptResult? toPromptResult(KeyActionResult result) {
    switch (result) {
      case KeyActionResult.confirmed:
        return PromptResult.confirmed;
      case KeyActionResult.cancelled:
        return PromptResult.cancelled;
      case KeyActionResult.handled:
      case KeyActionResult.ignored:
        return null;
    }
  }
}

/// Cursor state for text input prompts.
///
/// In sync mode, the cursor is always visible (no blinking).
/// This class is kept for API compatibility.
class CursorState {
  /// Whether the cursor should be visible (always true in sync mode).
  bool get isVisible => true;

  /// Creates a cursor state.
  CursorState();
}
