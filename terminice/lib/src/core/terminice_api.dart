import 'package:terminice_core/terminice_core.dart';

/// Global entry point for the default Terminice client using
/// [PromptTheme.dark] and the default [DartTerminal].
final Terminice terminice = Terminice();

/// Fluent theme-aware builder that exposes every prompt as an extension method.
///
/// Create custom palettes with [themed] or grab one of the built-in presets:
/// `terminice.matrix`, `terminice.fire`, `terminice.arcane`, and more.
///
/// **Custom Terminal Support:**
/// ```dart
/// // Use a custom terminal implementation
/// final custom = terminice.withTerminal(MyCustomTerminal());
/// custom.confirm('Are you sure?'); // Uses MyCustomTerminal
///
/// // Or create with both custom theme and terminal
/// final styled = Terminice(
///   defaultTheme: PromptTheme.fire,
///   terminal: MyCustomTerminal(),
/// );
/// ```
///
/// The terminal is set globally via [TerminalContext] when the instance is
/// created or when [activate] is called.
class Terminice {
  /// Theme that will be forwarded to every prompt invocation.
  final PromptTheme defaultTheme;

  /// The terminal implementation used for I/O operations.
  ///
  /// When `null`, uses the default [DartTerminal] via [TerminalContext].
  final Terminal? terminal;

  /// Creates a new Terminice client configured with [defaultTheme] and
  /// optionally a custom [terminal].
  ///
  /// If [terminal] is provided, it will be set as the current terminal
  /// via [TerminalContext.current].
  Terminice({
    this.defaultTheme = PromptTheme.dark,
    this.terminal,
  }) {
    // Set the terminal context if a custom terminal is provided
    if (terminal != null) {
      TerminalContext.current = terminal;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TERMINAL CONFIGURATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns a new client using the provided [terminal] implementation.
  ///
  /// This allows using custom terminal I/O for testing or alternative
  /// environments while keeping the same theme.
  ///
  /// ```dart
  /// final testTerminice = terminice.withTerminal(TestTerminal());
  /// testTerminice.confirm('Test prompt'); // Uses TestTerminal
  /// ```
  Terminice withTerminal(Terminal terminal) {
    return Terminice(defaultTheme: defaultTheme, terminal: terminal);
  }

  /// Activates this instance's terminal as the global [TerminalContext.current].
  ///
  /// Call this if you have multiple Terminice instances and need to switch
  /// between them, or after the context was changed externally.
  ///
  /// ```dart
  /// final custom = terminice.withTerminal(myTerminal);
  /// // ... some other code might change TerminalContext ...
  /// custom.activate(); // Re-activate this instance's terminal
  /// custom.confirm('Now using myTerminal again');
  /// ```
  void activate() {
    if (terminal != null) {
      TerminalContext.current = terminal;
    } else {
      TerminalContext.reset();
    }
  }

  /// Resets the terminal context to the default [DartTerminal].
  ///
  /// Useful after using a custom terminal to restore normal operation.
  static void resetTerminal() {
    TerminalContext.reset();
  }

  /// The currently active terminal from [TerminalContext].
  static Terminal get currentTerminal => TerminalContext.current;

  /// Returns a new client using the provided [theme], preserving the terminal.
  Terminice themed(PromptTheme theme) {
    return Terminice(defaultTheme: theme, terminal: terminal);
  }
}
