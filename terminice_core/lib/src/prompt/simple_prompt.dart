import 'package:terminice_core/terminice_core.dart';

// ============================================================================
// SIMPLE PROMPT – Composable system for basic prompt patterns
// ============================================================================

/// `SimplePrompt<T>` – A lightweight, composable prompt wrapper.
///
/// Centralizes the common boilerplate found in basic prompts:
/// - State management with cancellation tracking
/// - Initial value vs confirmed value handling
/// - PromptRunner + FrameView + KeyBindings wiring
///
/// **Problem it solves:**
/// Many prompts repeat the same pattern:
/// ```dart
/// // Before SimplePrompt
/// bool cancelled = false;
/// var value = initialValue;
/// final bindings = KeyBindings.somePreset(onCancel: () => cancelled = true);
/// final frame = FrameView(...);
/// void render(RenderOutput out) { frame.render(out, (ctx) { ... }); }
/// final runner = PromptRunner();
/// final result = runner.runWithBindings(...);
/// if (cancelled || result == PromptResult.cancelled) return initialValue;
/// return value;
/// ```
///
/// **After SimplePrompt:**
/// ```dart
/// final prompt = SimplePrompt<bool>(
///   title: 'Confirm',
///   initialValue: true,
///   buildBindings: (state) => KeyBindings.togglePrompt(
///     onToggle: () => state.value = !state.value,
///     onCancel: state.cancel,
///   ),
///   render: (ctx, state) => renderMyContent(ctx, state.value),
/// );
/// return prompt.run(); // Returns initialValue on cancel
/// ```
///
/// **Design principles:**
/// - Composition over inheritance
/// - Works alongside existing systems (not a replacement)
/// - Separation of concerns (state separate from rendering)
/// - DRY: Eliminates repeated cancellation/default value boilerplate
///
/// **When to use:**
/// - Simple prompts with a single return value
/// - Prompts that don't need list navigation or complex state
/// - When you want less boilerplate without creating a new prompt class
///
/// **When NOT to use:**
/// - Complex prompts – use SelectableListPrompt, ValuePrompt, etc.
/// - Display-only views – use FrameView.show()
class SimplePrompt<T> {
  /// Title displayed in the frame header.
  final String title;

  /// Theme for styling.
  final PromptTheme theme;

  /// Initial value (returned on cancel).
  final T initialValue;

  /// Builds key bindings given the prompt state.
  ///
  /// This allows bindings to reference and modify the state.
  /// The state provides [cancel] method to mark as cancelled.
  final KeyBindings Function(PromptState<T> state) buildBindings;

  /// Renders the prompt content.
  ///
  /// Receives the FrameContext and current state.
  final void Function(FrameContext ctx, PromptState<T> state) render;

  /// Whether to hide the cursor during the prompt.
  final bool hideCursor;

  /// Hint style for displaying key bindings.
  final HintStyle hintStyle;

  /// Whether to show connector line after header.
  final bool showConnector;

  const SimplePrompt({
    required this.title,
    required this.initialValue,
    required this.buildBindings,
    required this.render,
    this.theme = PromptTheme.dark,
    this.hideCursor = true,
    this.hintStyle = HintStyle.bullets,
    this.showConnector = false,
  });

  /// Runs the prompt and returns the result.
  ///
  /// Returns [initialValue] if cancelled, otherwise returns the
  /// final value from the state.
  T run() {
    final state = PromptState<T>(initialValue);
    final bindings = buildBindings(state);

    final frame = FrameView(
      title: title,
      theme: theme,
      bindings: bindings,
      hintStyle: hintStyle,
      showConnector: showConnector,
    );

    void renderFrame(RenderOutput out) {
      frame.render(out, (ctx) => render(ctx, state));
    }

    final runner = PromptRunner(hideCursor: hideCursor);
    final result = runner.runWithBindings(
      render: renderFrame,
      bindings: bindings,
    );

    if (state.isCancelled || result == PromptResult.cancelled) {
      return initialValue;
    }
    return state.value;
  }
}

// ============================================================================
// PROMPT STATE – Mutable state container for SimplePrompt
// ============================================================================

/// Mutable state container for prompt values.
///
/// Provides:
/// - [value]: The current value (mutable)
/// - [isCancelled]: Whether the prompt was cancelled
/// - [cancel()]: Method to mark as cancelled
///
/// This is passed to both [buildBindings] and [render] functions,
/// allowing bindings to modify state and rendering to read it.
class PromptState<T> {
  /// The current value.
  T value;

  /// Whether the prompt was cancelled.
  bool _cancelled = false;

  /// Creates a new prompt state with initial value.
  PromptState(this.value);

  /// Whether the prompt was cancelled.
  bool get isCancelled => _cancelled;

  /// Marks the prompt as cancelled.
  ///
  /// Call this from your cancel key binding.
  void cancel() {
    _cancelled = true;
  }
}

// ============================================================================
// EXTENSIONS – Builder pattern for fluent API
// ============================================================================

/// Extension for creating SimplePrompt with builder pattern.
extension SimplePromptBuilder<T> on SimplePrompt<T> {
  /// Creates a copy with modified properties.
  SimplePrompt<T> copyWith({
    String? title,
    PromptTheme? theme,
    T? initialValue,
    KeyBindings Function(PromptState<T> state)? buildBindings,
    void Function(FrameContext ctx, PromptState<T> state)? render,
    bool? hideCursor,
    HintStyle? hintStyle,
    bool? showConnector,
  }) {
    return SimplePrompt<T>(
      title: title ?? this.title,
      theme: theme ?? this.theme,
      initialValue: initialValue ?? this.initialValue,
      buildBindings: buildBindings ?? this.buildBindings,
      render: render ?? this.render,
      hideCursor: hideCursor ?? this.hideCursor,
      hintStyle: hintStyle ?? this.hintStyle,
      showConnector: showConnector ?? this.showConnector,
    );
  }
}

// ============================================================================
// PRESET FACTORIES – Common prompt patterns
// ============================================================================

/// Factory methods for common SimplePrompt patterns.
class SimplePrompts {
  SimplePrompts._();

  /// Creates a boolean confirm prompt (Yes/No).
  ///
  /// ```dart
  /// final result = SimplePrompts.confirm(
  ///   title: 'Delete file?',
  ///   message: 'Are you sure?',
  /// ).run();
  /// ```
  static SimplePrompt<bool> confirm({
    required String title,
    required String message,
    String yesLabel = 'Yes',
    String noLabel = 'No',
    bool defaultYes = true,
    PromptTheme theme = PromptTheme.dark,
  }) {
    return SimplePrompt<bool>(
      title: title,
      theme: theme,
      initialValue: defaultYes,
      buildBindings: (state) => KeyBindings.togglePrompt(
        onToggle: () => state.value = !state.value,
        onCancel: state.cancel,
      ),
      render: (ctx, state) {
        // Message with arrow
        ctx.emptyLine();
        ctx.line(
            ' ${ctx.lb.arrowAccent()} ${ctx.theme.bold}$message${ctx.theme.reset}');
        ctx.emptyLine();

        // Yes/No buttons
        final yes = state.value
            ? '${ctx.theme.inverse}${ctx.theme.accent} $yesLabel ${ctx.theme.reset}'
            : '${ctx.theme.dim}$yesLabel${ctx.theme.reset}';
        final no = !state.value
            ? '${ctx.theme.inverse}${ctx.theme.accent} $noLabel ${ctx.theme.reset}'
            : '${ctx.theme.dim}$noLabel${ctx.theme.reset}';

        ctx.line('   $yes   $no\n');
      },
    );
  }

  /// Creates a single-choice prompt with inline options.
  ///
  /// Unlike SelectableListPrompt (vertical list), this shows options inline.
  /// Best for 2-4 options that fit on one line.
  ///
  /// ```dart
  /// final choice = SimplePrompts.choice(
  ///   title: 'Select mode',
  ///   options: ['Debug', 'Release', 'Profile'],
  /// ).run(); // Returns selected option or first on cancel
  /// ```
  static SimplePrompt<String> choice({
    required String title,
    required List<String> options,
    int initialIndex = 0,
    PromptTheme theme = PromptTheme.dark,
  }) {
    assert(options.isNotEmpty, 'Options cannot be empty');
    final clampedIndex = initialIndex.clamp(0, options.length - 1);

    // Use a wrapper class to hold the index since we need both index and string
    return SimplePrompt<String>(
      title: title,
      theme: theme,
      initialValue: options[clampedIndex],
      buildBindings: (state) {
        var currentIndex = clampedIndex;
        return KeyBindings.horizontalNavigation(
              onLeft: () {
                currentIndex = (currentIndex - 1).clamp(0, options.length - 1);
                state.value = options[currentIndex];
              },
              onRight: () {
                currentIndex = (currentIndex + 1).clamp(0, options.length - 1);
                state.value = options[currentIndex];
              },
            ) +
            KeyBindings.prompt(onCancel: state.cancel);
      },
      render: (ctx, state) {
        ctx.emptyLine();

        final buffer = StringBuffer('   ');
        for (var i = 0; i < options.length; i++) {
          final opt = options[i];
          final isSelected = opt == state.value;
          if (isSelected) {
            buffer.write(
                '${ctx.theme.inverse}${ctx.theme.accent} $opt ${ctx.theme.reset}');
          } else {
            buffer.write('${ctx.theme.dim}$opt${ctx.theme.reset}');
          }
          if (i < options.length - 1) buffer.write('   ');
        }

        ctx.line(buffer.toString());
        ctx.emptyLine();
      },
    );
  }

  /// Creates a simple number input prompt.
  ///
  /// Uses arrow keys for increment/decrement.
  /// For more features, use ValuePrompt instead.
  ///
  /// ```dart
  /// final count = SimplePrompts.number(
  ///   title: 'Enter count',
  ///   initial: 5,
  ///   min: 0,
  ///   max: 100,
  /// ).run();
  /// ```
  static SimplePrompt<int> number({
    required String title,
    int initial = 0,
    int min = 0,
    int max = 100,
    int step = 1,
    PromptTheme theme = PromptTheme.dark,
  }) {
    return SimplePrompt<int>(
      title: title,
      theme: theme,
      initialValue: initial.clamp(min, max),
      buildBindings: (state) =>
          KeyBindings.horizontalNavigation(
            onLeft: () => state.value = (state.value - step).clamp(min, max),
            onRight: () => state.value = (state.value + step).clamp(min, max),
          ) +
          KeyBindings.prompt(onCancel: state.cancel),
      render: (ctx, state) {
        ctx.gutterLine('${ctx.theme.accent}${state.value}${ctx.theme.reset}'
            '${ctx.theme.dim} (range: $min–$max)${ctx.theme.reset}');
      },
    );
  }
}

// ============================================================================
// TEXT INPUT STATE – Extended state for text input prompts
// ============================================================================

/// Extended state for text input prompts.
///
/// Adds text buffer management, validation state, and visibility toggle
/// on top of the basic [PromptState].
class TextInputState {
  /// The text input buffer.
  final TextInputBuffer buffer;

  /// Whether the prompt was cancelled.
  bool _cancelled = false;

  /// Whether the prompt was confirmed.
  bool _confirmed = false;

  /// Validation error message (null if valid).
  String? error;

  /// Whether input is currently valid.
  bool valid = true;

  /// Whether to show plain text (for password prompts).
  bool showPlain = false;

  /// Creates a new text input state.
  TextInputState() : buffer = TextInputBuffer();

  /// The current text value.
  String get text => buffer.text;

  /// Whether the buffer is empty.
  bool get isEmpty => buffer.isEmpty;

  /// Whether the buffer is not empty.
  bool get isNotEmpty => buffer.isNotEmpty;

  /// Length of the text.
  int get length => buffer.length;

  /// Whether the prompt was cancelled.
  bool get isCancelled => _cancelled;

  /// Whether the prompt was confirmed.
  bool get isConfirmed => _confirmed;

  /// Marks the prompt as cancelled.
  void cancel() => _cancelled = true;

  /// Marks the prompt as confirmed.
  void confirm() => _confirmed = true;

  /// Sets validation error.
  void setError(String message) {
    valid = false;
    error = message;
  }

  /// Clears validation error.
  void clearError() {
    valid = true;
    error = null;
  }

  /// Toggles plain text visibility (for passwords).
  void toggleVisibility() => showPlain = !showPlain;
}

// ============================================================================
// SYNC TEXT PROMPT – Text input with static cursor
// ============================================================================

/// `TextPromptSync` – Sync text input prompt with validation.
///
/// Features:
/// - Static cursor (always visible, no blink)
/// - TextInputBuffer management
/// - Validation with error messages
/// - Optional password masking
///
/// **Usage:**
/// ```dart
/// final result = TextPromptSync(
///   title: 'Enter name',
///   placeholder: 'Your name...',
///   validator: (text) => text.length < 2 ? 'Too short' : '',
/// ).run();
/// ```
class TextPromptSync {
  /// Title displayed in the frame header.
  final String title;

  /// Theme for styling.
  final PromptTheme theme;

  /// Placeholder text shown when empty.
  final String? placeholder;

  /// Validator function. Return empty string if valid, error message if not.
  final String Function(String text)? validator;

  /// Whether input is required (non-empty).
  final bool required;

  /// Whether to mask input (password mode).
  final bool masked;

  /// Mask character for password mode.
  final String maskChar;

  /// Whether to allow Ctrl+R to toggle visibility in password mode.
  final bool allowReveal;

  const TextPromptSync({
    required this.title,
    this.theme = PromptTheme.dark,
    this.placeholder,
    this.validator,
    this.required = false,
    this.masked = false,
    this.maskChar = '•',
    this.allowReveal = true,
  });

  /// Runs the prompt and returns the result.
  ///
  /// Returns null if cancelled, otherwise returns the trimmed text.
  String? run() {
    final state = TextInputState();

    // Build bindings
    var bindings = state.buffer.toTextInputBindings(onInput: () {
      state.clearError();
    });

    bindings = bindings +
        KeyBindings.confirm(onConfirm: () {
          final text = state.text.trim();

          // Validate required
          if (required && text.isEmpty) {
            state.setError('Input cannot be empty.');
            return KeyActionResult.handled;
          }

          // Custom validation
          if (validator != null) {
            final error = validator!(text);
            if (error.isNotEmpty) {
              state.setError(error);
              return KeyActionResult.handled;
            }
          }

          state.confirm();
          return KeyActionResult.confirmed;
        });

    // Add reveal toggle for password mode
    if (masked && allowReveal) {
      bindings = bindings +
          KeyBindings.ctrlR(
            onPress: state.toggleVisibility,
            hintDescription: 'reveal',
          );
    }

    bindings = bindings + KeyBindings.cancel(onCancel: state.cancel);

    // Render function
    void renderFrame(RenderOutput out) {
      final frame = FrameView(
        title: title,
        theme: theme,
        bindings: null, // Manual hints below
      );

      frame.renderContent(out, (ctx) {
        // Build display text
        String displayText;
        if (state.isEmpty) {
          displayText = placeholder != null
              ? '${theme.dim}$placeholder${theme.reset}'
              : '';
        } else if (masked && !state.showPlain) {
          displayText = maskChar * state.length;
        } else {
          displayText = state.text;
        }

        // Static cursor (always visible)
        final cursor = '${theme.accent}▌${theme.reset}';

        // Color based on validation
        final color = state.valid ? theme.accent : theme.error;

        ctx.gutterLine('$color$displayText$cursor${theme.reset}');

        // Error or hints
        if (state.error != null) {
          ctx.gutterLine('${theme.error}${state.error}${theme.reset}');
        } else {
          final hints = <String>['Enter to confirm', 'Esc to cancel'];
          if (masked && allowReveal) hints.add('Ctrl+R to reveal');
          ctx.gutterLine(HintFormat.comma(hints, theme));
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(
      render: renderFrame,
      bindings: bindings,
    );

    if (state.isCancelled) return null;
    return state.isConfirmed ? state.text.trim() : null;
  }
}

// ============================================================================
// SYNC SIMPLE PROMPTS – Factory methods for sync prompts
// ============================================================================

/// Factory methods for common sync prompt patterns.
class SyncPrompts {
  SyncPrompts._();

  /// Creates a text input prompt with optional validation.
  ///
  /// ```dart
  /// final name = SyncPrompts.text(
  ///   title: 'Enter name',
  ///   placeholder: 'Your name...',
  ///   required: true,
  /// ).run();
  /// ```
  static TextPromptSync text({
    required String title,
    String? placeholder,
    String Function(String)? validator,
    bool required = false,
    PromptTheme theme = PromptTheme.dark,
  }) {
    return TextPromptSync(
      title: title,
      theme: theme,
      placeholder: placeholder,
      validator: validator,
      required: required,
    );
  }

  /// Creates a password input prompt with masking.
  ///
  /// ```dart
  /// final password = SyncPrompts.password(
  ///   title: 'Enter password',
  ///   required: true,
  /// ).run();
  /// ```
  static TextPromptSync password({
    required String title,
    bool required = true,
    bool allowReveal = true,
    String maskChar = '•',
    PromptTheme theme = PromptTheme.dark,
  }) {
    return TextPromptSync(
      title: title,
      theme: theme,
      masked: true,
      maskChar: maskChar,
      allowReveal: allowReveal,
      required: required,
    );
  }

  /// Creates a text input with custom validation message.
  ///
  /// ```dart
  /// final email = SyncPrompts.validated(
  ///   title: 'Enter email',
  ///   validator: (t) => t.contains('@') ? '' : 'Invalid email',
  /// ).run();
  /// ```
  static TextPromptSync validated({
    required String title,
    required String Function(String) validator,
    String? placeholder,
    PromptTheme theme = PromptTheme.dark,
  }) {
    return TextPromptSync(
      title: title,
      theme: theme,
      placeholder: placeholder,
      validator: validator,
    );
  }
}
