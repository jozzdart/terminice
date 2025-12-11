import 'key_events.dart';

/// Result of a key action handler.
///
/// - `handled`: Key was processed, continue the loop (re-render)
/// - `confirmed`: End prompt with confirmed result
/// - `cancelled`: End prompt with cancelled result
/// - `ignored`: Key was not handled by this binding
enum KeyActionResult {
  /// Key was handled, continue the prompt loop (trigger re-render)
  handled,

  /// End prompt with confirmed result
  confirmed,

  /// End prompt with cancelled result
  cancelled,

  /// Key was not handled by this binding (try next binding)
  ignored,
}

// ============================================================================
// KEY BINDING
// ============================================================================

/// A single key binding that maps key events to actions.
///
/// Bindings are designed to stay pure/side-effect free except for the action
/// you provide. This keeps them trivial to test and reason about when multiple
/// sets are composed together.
///
/// This is the core building block of the KeyBindings system.
/// Each binding can:
/// - Match one or more key types
/// - Execute an action when matched
/// - Provide a hint label and description for hint display in views/prompts
class KeyBinding {
  /// Key types that trigger this binding.
  final Set<KeyEventType> keys;

  /// Optional character matcher (for `KeyEventType.char` events).
  final bool Function(String char)? charMatcher;

  /// The action to execute when this binding matches.
  final KeyActionResult Function(KeyEvent event) action;

  /// Short label for hints (e.g., "←/→", "Enter", "Esc")
  final String? hintLabel;

  /// Description for hints (e.g., "navigate", "confirm", "cancel")
  final String? hintDescription;

  /// Creates a binding that matches the provided [keys]. For convenience,
  /// prefer the `single`, `multi`, or `char` factories when possible.
  const KeyBinding({
    required this.keys,
    required this.action,
    this.charMatcher,
    this.hintLabel,
    this.hintDescription,
  });

  /// Creates a binding for a single key type.
  factory KeyBinding.single(
    KeyEventType key,
    KeyActionResult Function(KeyEvent event) action, {
    String? hintLabel,
    String? hintDescription,
  }) {
    return KeyBinding(
      keys: {key},
      action: action,
      hintLabel: hintLabel,
      hintDescription: hintDescription,
    );
  }

  /// Creates a binding for multiple key types.
  factory KeyBinding.multi(
    Set<KeyEventType> keys,
    KeyActionResult Function(KeyEvent event) action, {
    String? hintLabel,
    String? hintDescription,
  }) {
    return KeyBinding(
      keys: keys,
      action: action,
      hintLabel: hintLabel,
      hintDescription: hintDescription,
    );
  }

  /// Creates a binding for character input matching a predicate.
  factory KeyBinding.char(
    bool Function(String char) matcher,
    KeyActionResult Function(KeyEvent event) action, {
    String? hintLabel,
    String? hintDescription,
  }) {
    return KeyBinding(
      keys: {KeyEventType.char},
      charMatcher: matcher,
      action: action,
      hintLabel: hintLabel,
      hintDescription: hintDescription,
    );
  }

  /// Checks if this binding matches the given event.
  bool matches(KeyEvent event) {
    if (!keys.contains(event.type)) return false;

    // For char events, also check the character matcher
    if (event.type == KeyEventType.char && charMatcher != null) {
      return event.char != null && charMatcher!(event.char!);
    }

    return true;
  }

  /// Attempts to handle the event. Returns the result if matched, null otherwise.
  KeyActionResult? tryHandle(KeyEvent event) {
    if (matches(event)) {
      return action(event);
    }
    return null;
  }
}

// ============================================================================
// KEY BINDINGS (composable collection)
// ============================================================================

/// A composable collection of key bindings.
///
/// KeyBindings can be:
/// - Combined using `+` operator or `merge()`
/// - Extended with additional bindings
/// - Used to generate hints automatically
/// - Treated as immutable value objects (safe to reuse across renders)
///
/// Example:
/// ```dart
/// final bindings = KeyBindings.cancel() +
///     KeyBindings.confirm() +
///     KeyBindings.verticalNavigation(onUp: moveUp, onDown: moveDown);
/// ```
class KeyBindings {
  final List<KeyBinding> _bindings;

  /// Creates an immutable binding collection. Prefer using the provided
  /// factories (`KeyBindings.prompt()`, etc.) instead of building the list
  /// manually.
  const KeyBindings(this._bindings);

  /// Creates an empty KeyBindings collection.
  const KeyBindings.empty() : _bindings = const [];

  /// Creates KeyBindings from a list of bindings.
  factory KeyBindings.from(List<KeyBinding> bindings) => KeyBindings(bindings);

  /// All bindings in this collection.
  List<KeyBinding> get bindings => List.unmodifiable(_bindings);

  // --------------------------------------------------------------------------
  // COMPOSITION
  // --------------------------------------------------------------------------

  /// Combines this with another KeyBindings collection.
  /// Bindings from [other] are added after this collection's bindings.
  KeyBindings operator +(KeyBindings other) {
    return KeyBindings([..._bindings, ...other._bindings]);
  }

  /// Merges multiple KeyBindings collections.
  static KeyBindings merge(List<KeyBindings> collections) {
    return KeyBindings(collections.expand((c) => c._bindings).toList());
  }

  /// Adds a single binding to this collection.
  /// Returns a new collection with [binding] appended to the end.
  KeyBindings add(KeyBinding binding) {
    return KeyBindings([..._bindings, binding]);
  }

  /// Adds multiple bindings to this collection.
  /// Returns a new collection with every binding in [bindings] appended.
  KeyBindings addAll(List<KeyBinding> bindings) {
    return KeyBindings([..._bindings, ...bindings]);
  }

  // --------------------------------------------------------------------------
  // HANDLING
  // --------------------------------------------------------------------------

  /// Processes a key event through all bindings.
  ///
  /// Returns the first non-ignored result, or [KeyActionResult.ignored]
  /// if no binding matched.
  KeyActionResult handle(KeyEvent event) {
    for (final binding in _bindings) {
      final result = binding.tryHandle(event);
      if (result != null && result != KeyActionResult.ignored) {
        return result;
      }
    }
    return KeyActionResult.ignored;
  }

  // --------------------------------------------------------------------------
  // HINT GENERATION
  // --------------------------------------------------------------------------

  /// Generates hint entries from all bindings that have hints defined.
  ///
  /// Returns a list of [hintLabel, hintDescription] pairs suitable
  /// for use with `Hints.grid()` or `Hints.bullets()`.
  List<List<String>> toHintEntries() {
    final hints = <List<String>>[];
    for (final binding in _bindings) {
      if (binding.hintLabel != null && binding.hintDescription != null) {
        hints.add([binding.hintLabel!, binding.hintDescription!]);
      }
    }
    return hints;
  }

  // --------------------------------------------------------------------------
  // STANDARD BINDINGS FACTORIES
  // --------------------------------------------------------------------------

  /// Creates cancel bindings (Esc and Ctrl+C).
  static KeyBindings cancel({
    void Function()? onCancel,
    String hintLabel = 'Esc',
    String hintDescription = 'cancel',
  }) {
    return KeyBindings([
      KeyBinding.multi(
        {KeyEventType.esc, KeyEventType.ctrlC},
        (event) {
          onCancel?.call();
          return KeyActionResult.cancelled;
        },
        hintLabel: hintLabel,
        hintDescription: hintDescription,
      ),
    ]);
  }

  /// Creates confirm binding (Enter).
  static KeyBindings confirm({
    KeyActionResult Function()? onConfirm,
    String hintLabel = 'Enter',
    String hintDescription = 'confirm',
  }) {
    return KeyBindings([
      KeyBinding.single(
        KeyEventType.enter,
        (event) => onConfirm?.call() ?? KeyActionResult.confirmed,
        hintLabel: hintLabel,
        hintDescription: hintDescription,
      ),
    ]);
  }

  /// Creates vertical navigation bindings (↑/↓).
  static KeyBindings verticalNavigation({
    required void Function() onUp,
    required void Function() onDown,
    String hintLabel = '↑/↓',
    String hintDescription = 'navigate',
  }) {
    return KeyBindings([
      KeyBinding.single(
        KeyEventType.arrowUp,
        (event) {
          onUp();
          return KeyActionResult.handled;
        },
      ),
      KeyBinding.single(
        KeyEventType.arrowDown,
        (event) {
          onDown();
          return KeyActionResult.handled;
        },
        hintLabel: hintLabel,
        hintDescription: hintDescription,
      ),
    ]);
  }

  /// Creates horizontal navigation bindings (←/→).
  static KeyBindings horizontalNavigation({
    required void Function() onLeft,
    required void Function() onRight,
    String hintLabel = '←/→',
    String hintDescription = 'adjust',
  }) {
    return KeyBindings([
      KeyBinding.single(
        KeyEventType.arrowLeft,
        (event) {
          onLeft();
          return KeyActionResult.handled;
        },
      ),
      KeyBinding.single(
        KeyEventType.arrowRight,
        (event) {
          onRight();
          return KeyActionResult.handled;
        },
        hintLabel: hintLabel,
        hintDescription: hintDescription,
      ),
    ]);
  }

  /// Creates all-direction navigation bindings (↑/↓/←/→).
  static KeyBindings directionalNavigation({
    void Function()? onUp,
    void Function()? onDown,
    void Function()? onLeft,
    void Function()? onRight,
    String hintLabel = '↑/↓/←/→',
    String hintDescription = 'navigate',
  }) {
    final bindings = <KeyBinding>[];

    if (onUp != null) {
      bindings.add(KeyBinding.single(
        KeyEventType.arrowUp,
        (event) {
          onUp();
          return KeyActionResult.handled;
        },
      ));
    }

    if (onDown != null) {
      bindings.add(KeyBinding.single(
        KeyEventType.arrowDown,
        (event) {
          onDown();
          return KeyActionResult.handled;
        },
      ));
    }

    if (onLeft != null) {
      bindings.add(KeyBinding.single(
        KeyEventType.arrowLeft,
        (event) {
          onLeft();
          return KeyActionResult.handled;
        },
      ));
    }

    if (onRight != null) {
      bindings.add(KeyBinding.single(
        KeyEventType.arrowRight,
        (event) {
          onRight();
          return KeyActionResult.handled;
        },
        hintLabel: hintLabel,
        hintDescription: hintDescription,
      ));
    }

    return KeyBindings(bindings);
  }

  /// Creates toggle binding (Space).
  static KeyBindings toggle({
    required void Function() onToggle,
    String hintLabel = 'Space',
    String hintDescription = 'toggle',
  }) {
    return KeyBindings([
      KeyBinding.single(
        KeyEventType.space,
        (event) {
          onToggle();
          return KeyActionResult.handled;
        },
        hintLabel: hintLabel,
        hintDescription: hintDescription,
      ),
    ]);
  }

  /// Creates tab binding.
  static KeyBindings tab({
    required void Function() onTab,
    String hintLabel = 'Tab',
    String hintDescription = 'switch',
  }) {
    return KeyBindings([
      KeyBinding.single(
        KeyEventType.tab,
        (event) {
          onTab();
          return KeyActionResult.handled;
        },
        hintLabel: hintLabel,
        hintDescription: hintDescription,
      ),
    ]);
  }

  /// Creates search toggle binding (/).
  static KeyBindings searchToggle({
    required void Function() onToggle,
    String hintLabel = '/',
    String hintDescription = 'search',
  }) {
    return KeyBindings([
      KeyBinding.single(
        KeyEventType.slash,
        (event) {
          onToggle();
          return KeyActionResult.handled;
        },
        hintLabel: hintLabel,
        hintDescription: hintDescription,
      ),
    ]);
  }

  /// Creates number key bindings (default 1-9, optionally 0).
  ///
  /// Handy for quick-select lists where pressing `3` should highlight/confirm
  /// the third entry. Set [max] to limit accepted digits and [includeZero] to
  /// keep `0` as a valid shortcut.
  static KeyBindings numbers({
    required void Function(int number) onNumber,
    int max = 9,
    bool includeZero = false,
    String? hintLabel,
    String? hintDescription,
  }) {
    return KeyBindings([
      KeyBinding.char(
        (char) {
          if (!RegExp(r'^[0-9]$').hasMatch(char)) return false;
          final n = int.parse(char);
          if (n == 0 && !includeZero) return false;
          if (n > max) return false;
          return true;
        },
        (event) {
          final n = int.parse(event.char!);
          onNumber(n);
          return KeyActionResult.handled;
        },
        hintLabel: hintLabel ?? (includeZero ? '0–$max' : '1–$max'),
        hintDescription: hintDescription ?? 'set value',
      ),
    ]);
  }

  /// Creates letter key binding for a specific character (case-insensitive).
  static KeyBindings letter({
    required String char,
    required void Function() onPress,
    String? hintLabel,
    String? hintDescription,
  }) {
    final lower = char.toLowerCase();
    final upper = char.toUpperCase();
    return KeyBindings([
      KeyBinding.char(
        (c) => c == lower || c == upper,
        (event) {
          onPress();
          return KeyActionResult.handled;
        },
        hintLabel: hintLabel ?? upper,
        hintDescription: hintDescription,
      ),
    ]);
  }

  // --------------------------------------------------------------------------
  // COMMON PRESETS
  // --------------------------------------------------------------------------

  /// Standard prompt bindings: confirm (Enter) + cancel (Esc/Ctrl+C).
  static KeyBindings prompt({
    KeyActionResult Function()? onConfirm,
    void Function()? onCancel,
  }) {
    return confirm(onConfirm: onConfirm) + cancel(onCancel: onCancel);
  }

  /// Standard list bindings: navigation + confirm + cancel.
  static KeyBindings list({
    required void Function() onUp,
    required void Function() onDown,
    KeyActionResult Function()? onConfirm,
    void Function()? onCancel,
  }) {
    return verticalNavigation(onUp: onUp, onDown: onDown) +
        confirm(onConfirm: onConfirm) +
        cancel(onCancel: onCancel);
  }

  /// Standard selection bindings: navigation + toggle + confirm + cancel.
  static KeyBindings selection({
    required void Function() onUp,
    required void Function() onDown,
    required void Function() onToggle,
    KeyActionResult Function()? onConfirm,
    void Function()? onCancel,
  }) {
    return verticalNavigation(onUp: onUp, onDown: onDown) +
        toggle(onToggle: onToggle, hintDescription: 'select') +
        confirm(onConfirm: onConfirm) +
        cancel(onCancel: onCancel);
  }

  /// Standard slider bindings: horizontal navigation + confirm + cancel.
  static KeyBindings slider({
    required void Function() onLeft,
    required void Function() onRight,
    KeyActionResult Function()? onConfirm,
    void Function()? onCancel,
  }) {
    return horizontalNavigation(onLeft: onLeft, onRight: onRight) +
        confirm(onConfirm: onConfirm) +
        cancel(onCancel: onCancel);
  }

  /// Standard toggle bindings: arrows toggle + space toggle + confirm + cancel.
  static KeyBindings togglePrompt({
    required void Function() onToggle,
    KeyActionResult Function()? onConfirm,
    void Function()? onCancel,
    String toggleHint = 'toggle',
  }) {
    return KeyBindings([
          // All arrow keys toggle
          KeyBinding.multi(
            {
              KeyEventType.arrowLeft,
              KeyEventType.arrowRight,
              KeyEventType.arrowUp,
              KeyEventType.arrowDown,
            },
            (event) {
              onToggle();
              return KeyActionResult.handled;
            },
            hintLabel: '←/→',
            hintDescription: toggleHint,
          ),
          // Space also toggles
          KeyBinding.single(
            KeyEventType.space,
            (event) {
              onToggle();
              return KeyActionResult.handled;
            },
          ),
        ]) +
        confirm(onConfirm: onConfirm) +
        cancel(onCancel: onCancel);
  }

  // --------------------------------------------------------------------------
  // EXTENDED BINDINGS
  // --------------------------------------------------------------------------

  /// Creates Ctrl+R binding (commonly used for reveal/toggle modes).
  static KeyBindings ctrlR({
    required void Function() onPress,
    String hintLabel = 'Ctrl+R',
    String hintDescription = 'reveal',
  }) {
    return KeyBindings([
      KeyBinding.single(
        KeyEventType.ctrlR,
        (event) {
          onPress();
          return KeyActionResult.handled;
        },
        hintLabel: hintLabel,
        hintDescription: hintDescription,
      ),
    ]);
  }

  /// Creates Ctrl+D binding.
  static KeyBindings ctrlD({
    required void Function() onPress,
    String hintLabel = 'Ctrl+D',
    String? hintDescription,
  }) {
    return KeyBindings([
      KeyBinding.single(
        KeyEventType.ctrlD,
        (event) {
          onPress();
          return KeyActionResult.handled;
        },
        hintLabel: hintLabel,
        hintDescription: hintDescription,
      ),
    ]);
  }

  /// Creates Tab binding for switching between items/modes.
  ///
  /// Alias for [tab] that reads nicer in contexts where the intent is to swap
  /// focus rather than perform a generic tab action.
  static KeyBindings tabSwitch({
    required void Function() onTab,
    String hintLabel = 'Tab',
    String hintDescription = 'switch',
  }) {
    return tab(
        onTab: onTab, hintLabel: hintLabel, hintDescription: hintDescription);
  }

  /// Creates conditional toggle binding (Space only when [isEnabled] is true).
  ///
  /// Useful for multi-select modes where toggle is only available when
  /// multi-select is enabled or when the underlying data needs validation
  /// before allowing a toggle.
  static KeyBindings conditionalToggle({
    required bool Function() isEnabled,
    required void Function() onToggle,
    String hintLabel = 'Space',
    String hintDescription = 'select',
  }) {
    return KeyBindings([
      KeyBinding.single(
        KeyEventType.space,
        (event) {
          if (!isEnabled()) return KeyActionResult.ignored;
          onToggle();
          return KeyActionResult.handled;
        },
        hintLabel: hintLabel,
        hintDescription: hintDescription,
      ),
    ]);
  }

  /// Creates row toggle binding (←/→ or Space to toggle current row).
  ///
  /// Used for toggle switches where horizontal arrows or space toggle the value.
  static KeyBindings rowToggle({
    required void Function() onToggle,
    String hintLabel = '←/→ / Space',
    String hintDescription = 'toggle',
  }) {
    return KeyBindings([
      KeyBinding.multi(
        {KeyEventType.arrowLeft, KeyEventType.arrowRight, KeyEventType.space},
        (event) {
          onToggle();
          return KeyActionResult.handled;
        },
        hintLabel: hintLabel,
        hintDescription: hintDescription,
      ),
    ]);
  }

  /// Creates 2D grid navigation bindings with custom move functions.
  ///
  /// Used for grid-based selection (GridSelect, ChoiceMap) where navigation
  /// wraps around edges and needs custom logic.
  static KeyBindings gridNavigation({
    required void Function() onUp,
    required void Function() onDown,
    required void Function() onLeft,
    required void Function() onRight,
    String hintLabel = '↑/↓/←/→',
    String hintDescription = 'navigate',
  }) {
    return KeyBindings([
      KeyBinding.single(KeyEventType.arrowUp, (event) {
        onUp();
        return KeyActionResult.handled;
      }),
      KeyBinding.single(KeyEventType.arrowDown, (event) {
        onDown();
        return KeyActionResult.handled;
      }),
      KeyBinding.single(KeyEventType.arrowLeft, (event) {
        onLeft();
        return KeyActionResult.handled;
      }),
      KeyBinding.single(
        KeyEventType.arrowRight,
        (event) {
          onRight();
          return KeyActionResult.handled;
        },
        hintLabel: hintLabel,
        hintDescription: hintDescription,
      ),
    ]);
  }

  /// Creates 2D grid selection bindings (navigation + optional toggle + confirm + cancel).
  ///
  /// Useful for multi-column selectors where arrow keys move the cursor and an
  /// optional space-bar toggle is exposed for selecting cells inline.
  static KeyBindings gridSelection({
    required void Function() onUp,
    required void Function() onDown,
    required void Function() onLeft,
    required void Function() onRight,
    void Function()? onToggle,
    bool showToggleHint = false,
    KeyActionResult Function()? onConfirm,
    void Function()? onCancel,
  }) {
    var bindings = gridNavigation(
      onUp: onUp,
      onDown: onDown,
      onLeft: onLeft,
      onRight: onRight,
    );

    if (onToggle != null) {
      bindings = bindings +
          KeyBindings([
            KeyBinding.single(
              KeyEventType.space,
              (event) {
                onToggle();
                return KeyActionResult.handled;
              },
              hintLabel: showToggleHint ? 'Space' : null,
              hintDescription: showToggleHint ? 'toggle selection' : null,
            ),
          ]);
    }

    return bindings +
        confirm(onConfirm: onConfirm) +
        cancel(onCancel: onCancel);
  }

  /// Creates toggle group bindings: vertical nav + row toggle + 'A' for all + prompt.
  ///
  /// Pairs nicely with `ToggleGroupView` components where keyboard support
  /// needs to feel consistent with CLI conventions.
  static KeyBindings toggleGroup({
    required void Function() onUp,
    required void Function() onDown,
    required void Function() onToggle,
    required void Function() onToggleAll,
    KeyActionResult Function()? onConfirm,
    void Function()? onCancel,
  }) {
    return verticalNavigation(onUp: onUp, onDown: onDown) +
        rowToggle(onToggle: onToggle) +
        letter(char: 'A', onPress: onToggleAll, hintDescription: 'toggle all') +
        confirm(onConfirm: onConfirm) +
        cancel(onCancel: onCancel);
  }

  // --------------------------------------------------------------------------
  // WAIT / ANY KEY UTILITIES
  // --------------------------------------------------------------------------

  /// Creates bindings that exit on any of the specified keys.
  ///
  /// Useful for "press Enter to continue" or "press any key" scenarios.
  static KeyBindings exitOn({
    required Set<KeyEventType> keys,
    void Function()? onExit,
    String? hintLabel,
    String? hintDescription,
  }) {
    return KeyBindings([
      KeyBinding.multi(
        keys,
        (event) {
          onExit?.call();
          return KeyActionResult.confirmed;
        },
        hintLabel: hintLabel,
        hintDescription: hintDescription,
      ),
    ]);
  }

  /// Creates bindings that exit on common "continue" keys (Enter, Esc, Space).
  static KeyBindings continuePrompt({
    void Function()? onContinue,
    String hintLabel = 'Enter',
    String hintDescription = 'continue',
  }) {
    return exitOn(
      keys: {KeyEventType.enter, KeyEventType.esc, KeyEventType.space},
      onExit: onContinue,
      hintLabel: hintLabel,
      hintDescription: hintDescription,
    );
  }

  /// Creates bindings for "press any key to continue" scenarios.
  ///
  /// This matches common navigation keys - not literally every key,
  /// but the ones users typically expect to work.
  static KeyBindings anyKeyToContinue({
    void Function()? onContinue,
    String hintLabel = 'any key',
    String hintDescription = 'continue',
  }) {
    return KeyBindings([
      KeyBinding.multi(
        {
          KeyEventType.enter,
          KeyEventType.esc,
          KeyEventType.space,
          KeyEventType.arrowLeft,
          KeyEventType.arrowRight,
          KeyEventType.arrowUp,
          KeyEventType.arrowDown,
          KeyEventType.tab,
          KeyEventType.ctrlC,
        },
        (event) {
          onContinue?.call();
          return KeyActionResult.confirmed;
        },
        hintLabel: hintLabel,
        hintDescription: hintDescription,
      ),
      // Also handle any character press
      KeyBinding.char(
        (c) => true,
        (event) {
          onContinue?.call();
          return KeyActionResult.confirmed;
        },
      ),
    ]);
  }

  /// Creates "back" bindings (Left arrow, Esc, Enter) for viewer scenarios.
  static KeyBindings back({
    void Function()? onBack,
    String hintLabel = '← / Esc / Enter',
    String hintDescription = 'back',
  }) {
    return exitOn(
      keys: {
        KeyEventType.arrowLeft,
        KeyEventType.esc,
        KeyEventType.enter,
        KeyEventType.ctrlC,
      },
      onExit: onBack,
      hintLabel: hintLabel,
      hintDescription: hintDescription,
    );
  }

  // --------------------------------------------------------------------------
  // UTILITY METHODS
  // --------------------------------------------------------------------------

  /// Waits for any matching key event using KeyEventReader.
  ///
  /// This is a convenience method for simple "wait for key" scenarios
  /// that don't need a full render loop.
  ///
  /// Example:
  /// ```dart
  /// final bindings = KeyBindings.continuePrompt();
  /// bindings.waitForKey(); // Blocks until Enter, Esc, or Space
  /// ```
  void waitForKey() {
    while (true) {
      final event = KeyEventReader.read();
      final result = handle(event);
      if (result != KeyActionResult.ignored &&
          result != KeyActionResult.handled) {
        break;
      }
      // For simple wait scenarios, also break on 'handled' if there are no 'ignored' results possible
      if (result == KeyActionResult.handled) {
        break;
      }
    }
  }

  /// Waits for a key and returns whichever [KeyActionResult] resolves first.
  ///
  /// Keeps looping until a binding returns something other than
  /// [KeyActionResult.ignored], which makes it ideal for command-line tools
  /// that just need to block until the user acknowledges something.
  KeyActionResult waitForKeyWithResult() {
    while (true) {
      final event = KeyEventReader.read();
      final result = handle(event);
      if (result != KeyActionResult.ignored) {
        return result;
      }
    }
  }
}
