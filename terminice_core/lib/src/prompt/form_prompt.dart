import 'package:terminice_core/terminice_core.dart';

// ============================================================================
// FORM FIELD CONFIG
// ============================================================================

/// Configuration for a single text field inside a [FormPrompt].
///
/// Each field has its own label, optional placeholder, masking settings,
/// and validation. Fields are rendered vertically inside a shared frame,
/// with the focused field receiving keyboard input.
///
/// ```dart
/// FormFieldConfig(
///   label: 'Password',
///   masked: true,
///   required: true,
/// )
/// ```
class FormFieldConfig {
  /// Label displayed to the left of the input.
  final String label;

  /// Placeholder text shown when the field is empty and focused.
  final String? placeholder;

  /// When `true`, input is displayed as [maskChar] characters.
  final bool masked;

  /// Character used to mask input when [masked] is `true`.
  final String maskChar;

  /// Whether Ctrl+R toggles plain-text reveal on this field.
  final bool allowReveal;

  /// Whether the field must be non-empty to submit.
  final bool required;

  /// Per-field validator. Return empty string if valid, error message if not.
  final String Function(String text)? validator;

  /// Optional initial value pre-filled into the buffer.
  final String? initialValue;

  const FormFieldConfig({
    required this.label,
    this.placeholder,
    this.masked = false,
    this.maskChar = '•',
    this.allowReveal = false,
    this.required = false,
    this.validator,
    this.initialValue,
  });
}

// ============================================================================
// FORM RESULT
// ============================================================================

/// The confirmed result of a [FormPrompt], containing all field values.
///
/// Access values by index:
/// ```dart
/// final password = result[0];
/// final verify = result[1];
/// ```
class FormResult {
  /// The trimmed text values of each field, in order.
  final List<String> values;

  const FormResult(this.values);

  /// Returns the value at [index].
  String operator [](int index) => values[index];

  /// Number of fields.
  int get length => values.length;
}

// ============================================================================
// FORM FIELD STATE (internal)
// ============================================================================

class _FieldState {
  final FormFieldConfig config;
  final TextInputBuffer buffer;
  bool showPlain = false;
  String? error;

  _FieldState(this.config) : buffer = TextInputBuffer() {
    if (config.initialValue != null && config.initialValue!.isNotEmpty) {
      buffer.setText(config.initialValue!);
    }
  }

  String get text => buffer.text;
  bool get isEmpty => buffer.isEmpty;
  bool get valid => error == null;

  void clearError() => error = null;
  void setError(String msg) => error = msg;

  String displayText({required bool focused}) {
    if (isEmpty) {
      if (focused && config.placeholder != null) {
        return config.placeholder!;
      }
      return '';
    }
    if (config.masked && !showPlain) {
      return config.maskChar * buffer.length;
    }
    return text;
  }
}

// ============================================================================
// FORM PROMPT
// ============================================================================

/// A multi-field text input prompt rendered inside a single [FrameView].
///
/// Composes existing [TextInputBuffer], [FrameView], [KeyBindings], and
/// [PromptRunner] to present multiple labeled text fields with per-field
/// validation, optional masking, and cross-field validation.
///
/// Key handling:
/// - Active field receives all typing keys
/// - **Tab / ↓**: move to next field
/// - **↑**: move to previous field
/// - **Enter**: next field if not on last, submit if on last
/// - **Ctrl+R**: toggle reveal on the focused field (if masked + allowReveal)
/// - **Esc / Ctrl+C**: cancel (returns `null`)
///
/// ```dart
/// final result = FormPrompt(
///   title: 'Create Account',
///   theme: PromptTheme.dark,
///   fields: [
///     FormFieldConfig(label: 'Password', masked: true, required: true),
///     FormFieldConfig(label: 'Verify', masked: true, required: true,
///       placeholder: 're-enter to confirm'),
///   ],
///   crossValidator: (values) =>
///     values[0] != values[1] ? 'Passwords do not match' : null,
/// ).run();
/// ```
class FormPrompt {
  /// Title shown in the frame header.
  final String title;

  /// Theme for styling.
  final PromptTheme theme;

  /// Field configurations, rendered top-to-bottom.
  final List<FormFieldConfig> fields;

  /// Optional cross-field validator run on submit.
  /// Return an error message to block submission, or `null` to allow it.
  final String? Function(List<String> values)? crossValidator;

  const FormPrompt({
    required this.title,
    required this.fields,
    this.theme = PromptTheme.dark,
    this.crossValidator,
  });

  /// Runs the form and returns a [FormResult] on confirmation, or `null`
  /// if cancelled.
  FormResult? run() {
    if (fields.isEmpty) return const FormResult([]);

    final states = fields.map((f) => _FieldState(f)).toList();
    var focusIndex = 0;
    var cancelled = false;
    var confirmed = false;
    String? crossError;

    void clearAllErrors() {
      for (final s in states) {
        s.clearError();
      }
      crossError = null;
    }

    bool validateAll() {
      var valid = true;
      for (final s in states) {
        s.clearError();
        if (s.config.required && s.text.trim().isEmpty) {
          s.setError('Required');
          valid = false;
        } else if (s.config.validator != null) {
          final err = s.config.validator!(s.text.trim());
          if (err.isNotEmpty) {
            s.setError(err);
            valid = false;
          }
        }
      }
      if (valid && crossValidator != null) {
        final err = crossValidator!(states.map((s) => s.text.trim()).toList());
        if (err != null) {
          crossError = err;
          valid = false;
        }
      }
      return valid;
    }

    void moveFocus(int delta) {
      focusIndex = (focusIndex + delta).clamp(0, states.length - 1);
    }

    // Build the active-field text input bindings dynamically so they
    // always target the focused buffer.
    final bindings = KeyBindings([
          // Typing, backspace, cursor movement → active buffer
          KeyBinding(
            keys: {
              KeyEventType.char,
              KeyEventType.space,
              KeyEventType.backspace,
              KeyEventType.arrowLeft,
              KeyEventType.arrowRight,
            },
            action: (event) {
              final state = states[focusIndex];
              if (state.buffer.handleKey(event)) {
                clearAllErrors();
                return KeyActionResult.handled;
              }
              return KeyActionResult.ignored;
            },
          ),
        ]) +
        // Tab / ↓: next field
        KeyBindings([
          KeyBinding.multi(
            {KeyEventType.tab, KeyEventType.arrowDown},
            (event) {
              if (focusIndex < states.length - 1) {
                moveFocus(1);
                return KeyActionResult.handled;
              }
              return KeyActionResult.ignored;
            },
            hintLabel: 'Tab',
            hintDescription: 'next field',
          ),
        ]) +
        // ↑: previous field
        KeyBindings([
          KeyBinding.single(
            KeyEventType.arrowUp,
            (event) {
              if (focusIndex > 0) {
                moveFocus(-1);
                return KeyActionResult.handled;
              }
              return KeyActionResult.ignored;
            },
          ),
        ]) +
        // Enter: next field or submit
        KeyBindings.confirm(onConfirm: () {
          if (focusIndex < states.length - 1) {
            moveFocus(1);
            return KeyActionResult.handled;
          }
          if (validateAll()) {
            confirmed = true;
            return KeyActionResult.confirmed;
          }
          return KeyActionResult.handled;
        }) +
        // Ctrl+R: toggle reveal on focused field
        KeyBindings([
          KeyBinding.single(
            KeyEventType.ctrlR,
            (event) {
              final state = states[focusIndex];
              if (state.config.masked && state.config.allowReveal) {
                state.showPlain = !state.showPlain;
                return KeyActionResult.handled;
              }
              return KeyActionResult.ignored;
            },
            hintLabel: _anyFieldRevealable(fields) ? 'Ctrl+R' : null,
            hintDescription: _anyFieldRevealable(fields) ? 'reveal' : null,
          ),
        ]) +
        KeyBindings.cancel(onCancel: () => cancelled = true);

    // Compute label column width once
    final labelWidth = _maxLabelWidth(fields);

    void render(RenderOutput out) {
      final frame = FrameView(
        title: title,
        theme: theme,
        bindings: bindings,
      );

      frame.render(out, (ctx) {
        for (var i = 0; i < states.length; i++) {
          final state = states[i];
          final focused = i == focusIndex;

          _renderField(ctx, state, focused, labelWidth, theme);

          if (state.error != null) {
            final pad = ' ' * 4;
            ctx.gutterLine('$pad${theme.error}${state.error}${theme.reset}');
          }
        }

        if (crossError != null) {
          ctx.gutterLine('${theme.error}$crossError${theme.reset}');
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(render: render, bindings: bindings);

    if (cancelled || !confirmed) return null;
    return FormResult(states.map((s) => s.text.trim()).toList());
  }
}

// ============================================================================
// RENDERING HELPERS
// ============================================================================

void _renderField(
  FrameContext ctx,
  _FieldState state,
  bool focused,
  int labelWidth,
  PromptTheme theme,
) {
  final arrow = ctx.lb.arrow(focused);
  final label = state.config.label.padRight(labelWidth);

  final display = state.displayText(focused: focused);
  final bool showPlaceholder =
      state.isEmpty && focused && state.config.placeholder != null;

  final String styledDisplay;
  if (showPlaceholder) {
    styledDisplay = '${theme.dim}$display${theme.reset}';
  } else if (state.isEmpty && !focused) {
    styledDisplay = '';
  } else if (focused) {
    styledDisplay = '${theme.accent}$display${theme.reset}';
  } else {
    styledDisplay = '${theme.dim}$display${theme.reset}';
  }

  final cursor = focused ? '${theme.accent}▌${theme.reset}' : '';

  ctx.gutterLine(
    '$arrow ${theme.bold}$label${theme.reset}  $styledDisplay$cursor',
  );
}

int _maxLabelWidth(List<FormFieldConfig> fields) {
  var w = 0;
  for (final f in fields) {
    if (f.label.length > w) w = f.label.length;
  }
  return w;
}

bool _anyFieldRevealable(List<FormFieldConfig> fields) {
  return fields.any((f) => f.masked && f.allowReveal);
}
