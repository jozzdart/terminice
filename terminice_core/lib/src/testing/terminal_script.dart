import 'package:terminice_core/terminice_core.dart';

import 'mock_terminal.dart';

/// The kind of input operation represented by a [TerminalScriptStep].
enum TerminalScriptStepKind {
  /// Queue a line for [MockTerminalInput.readLineSync].
  line,

  /// Queue UTF-8 text bytes for [MockTerminalInput.readByteSync].
  text,

  /// Queue a normalized key event through [MockTerminalInput.queueKey].
  key,
}

/// One reusable queued-input operation in a [TerminalScript].
class TerminalScriptStep {
  /// The kind of input operation this step performs.
  final TerminalScriptStepKind kind;

  /// Text payload for [TerminalScriptStepKind.line] and
  /// [TerminalScriptStepKind.text] steps.
  final String? text;

  /// Key payload for [TerminalScriptStepKind.key] steps.
  final KeyEventType? key;

  /// Optional character payload for character and generic Ctrl key events.
  final String? char;

  /// Creates a step that queues [text] for line-mode input.
  const TerminalScriptStep.line(String this.text)
      : kind = TerminalScriptStepKind.line,
        key = null,
        char = null;

  /// Creates a step that queues [text] as UTF-8 raw input bytes.
  const TerminalScriptStep.text(String this.text)
      : kind = TerminalScriptStepKind.text,
        key = null,
        char = null;

  /// Creates a step that queues [key] through [MockTerminalInput.queueKey].
  const TerminalScriptStep.key(KeyEventType this.key, [this.char])
      : kind = TerminalScriptStepKind.key,
        text = null;

  /// Queues this step on [input].
  void queueOn(MockTerminalInput input) {
    switch (kind) {
      case TerminalScriptStepKind.line:
        input.queueLine(text!);
        break;
      case TerminalScriptStepKind.text:
        input.queueString(text!);
        break;
      case TerminalScriptStepKind.key:
        input.queueKey(key!, char);
        break;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is TerminalScriptStep &&
        other.kind == kind &&
        other.text == text &&
        other.key == key &&
        other.char == char;
  }

  @override
  int get hashCode => Object.hash(kind, text, key, char);

  @override
  String toString() {
    switch (kind) {
      case TerminalScriptStepKind.line:
        return 'TerminalScriptStep.line($text)';
      case TerminalScriptStepKind.text:
        return 'TerminalScriptStep.text($text)';
      case TerminalScriptStepKind.key:
        if (char == null) return 'TerminalScriptStep.key($key)';
        return 'TerminalScriptStep.key($key, $char)';
    }
  }
}

/// Immutable, reusable terminal input queued for a [MockTerminal].
class TerminalScript {
  /// Input operations in queue order.
  final List<TerminalScriptStep> steps;

  /// Creates a script from already-built [steps].
  TerminalScript(Iterable<TerminalScriptStep> steps)
      : steps = List.unmodifiable(steps);

  /// Creates a script that queues each line for [MockTerminalInput.readLineSync].
  factory TerminalScript.lines(Iterable<String> lines) {
    return TerminalScript.build((script) => script.lines(lines));
  }

  /// Creates a script with the fluent [TerminalScriptBuilder].
  factory TerminalScript.build(
      void Function(TerminalScriptBuilder script) build) {
    final builder = TerminalScriptBuilder();
    build(builder);
    return builder.build();
  }

  /// Queues this script on [input].
  void applyToInput(MockTerminalInput input) {
    for (final step in steps) {
      step.queueOn(input);
    }
  }

  /// Queues this script on [terminal].
  void applyToTerminal(MockTerminal terminal) {
    applyToInput(terminal.mockInput);
  }

  /// Whether this script has no queued input.
  bool get isEmpty => steps.isEmpty;

  /// Whether this script has at least one queued input step.
  bool get isNotEmpty => steps.isNotEmpty;

  /// Number of queued input steps.
  int get length => steps.length;
}

/// Fluent builder for [TerminalScript].
class TerminalScriptBuilder {
  final List<TerminalScriptStep> _steps = [];

  /// Queues [line] for line-mode input.
  TerminalScriptBuilder line(String line) {
    _steps.add(TerminalScriptStep.line(line));
    return this;
  }

  /// Queues each line in [lines] for line-mode input.
  TerminalScriptBuilder lines(Iterable<String> lines) {
    for (final line in lines) {
      this.line(line);
    }
    return this;
  }

  /// Queues [text] as UTF-8 raw input bytes.
  TerminalScriptBuilder text(String text) {
    _steps.add(TerminalScriptStep.text(text));
    return this;
  }

  /// Queues [type] through [MockTerminalInput.queueKey].
  TerminalScriptBuilder key(KeyEventType type, [String? char]) {
    _steps.add(TerminalScriptStep.key(type, char));
    return this;
  }

  /// Queues Enter.
  TerminalScriptBuilder enter() => key(KeyEventType.enter);

  /// Queues Escape.
  TerminalScriptBuilder escape() => key(KeyEventType.esc);

  /// Queues Arrow Up.
  TerminalScriptBuilder up() => key(KeyEventType.arrowUp);

  /// Queues Arrow Down.
  TerminalScriptBuilder down() => key(KeyEventType.arrowDown);

  /// Queues Arrow Left.
  TerminalScriptBuilder left() => key(KeyEventType.arrowLeft);

  /// Queues Arrow Right.
  TerminalScriptBuilder right() => key(KeyEventType.arrowRight);

  /// Queues Space.
  TerminalScriptBuilder space() => key(KeyEventType.space);

  /// Queues Backspace.
  TerminalScriptBuilder backspace() => key(KeyEventType.backspace);

  /// Queues Tab.
  TerminalScriptBuilder tab() => key(KeyEventType.tab);

  /// Queues Ctrl+C.
  TerminalScriptBuilder ctrlC() => key(KeyEventType.ctrlC);

  /// Queues Ctrl+D.
  TerminalScriptBuilder ctrlD() => key(KeyEventType.ctrlD);

  /// Builds an immutable script from the queued steps.
  TerminalScript build() => TerminalScript(_steps);
}

/// Scripting conveniences for [MockTerminal].
extension MockTerminalScriptExtension on MockTerminal {
  /// Queues [script] on this terminal's mock input.
  void queueScript(TerminalScript script) {
    script.applyToTerminal(this);
  }
}

/// Scripting conveniences for [MockTerminalInput].
extension MockTerminalInputScriptExtension on MockTerminalInput {
  /// Queues [script] on this input.
  void queueScript(TerminalScript script) {
    script.applyToInput(this);
  }
}
