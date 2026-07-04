import 'package:terminice_core/terminice_core.dart';

import 'terminice_config.dart';

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
  /// Immutable configuration for this Terminice instance.
  final TerminiceConfig configuration;

  /// Effective theme that will be forwarded to every prompt invocation.
  final PromptTheme defaultTheme;

  /// The terminal implementation used for I/O operations.
  ///
  /// When `null`, uses the default [DartTerminal] via [TerminalContext].
  final Terminal? terminal;

  /// Creates a new Terminice client configured with [defaultTheme] and
  /// optionally a custom [terminal].
  ///
  /// When [config] is provided, it takes precedence over [defaultTheme].
  ///
  /// If [terminal] is provided, it will be set as the current terminal
  /// via [TerminalContext.current].
  Terminice({
    PromptTheme defaultTheme = PromptTheme.dark,
    this.terminal,
    TerminiceConfig? config,
  })  : configuration = _configurationFor(defaultTheme, config),
        defaultTheme = _configurationFor(defaultTheme, config).effectiveTheme {
    // Set the terminal context if a custom terminal is provided
    if (terminal != null) {
      TerminalContext.current = terminal;
    }
  }

  Terminice._({
    required this.configuration,
    this.terminal,
  }) : defaultTheme = configuration.effectiveTheme {
    // Set the terminal context if a custom terminal is provided
    if (terminal != null) {
      TerminalContext.current = terminal;
    }
  }

  static TerminiceConfig _configurationFor(
    PromptTheme defaultTheme,
    TerminiceConfig? config,
  ) {
    return config ?? TerminiceConfig(baseTheme: defaultTheme);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TERMINAL CONFIGURATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Unmodified theme chosen by the caller before feature or compatibility
  /// transforms are applied.
  PromptTheme get baseTheme => configuration.baseTheme;

  /// Optional display feature override applied on top of [baseTheme].
  DisplayFeatures? get featureOverride => configuration.featureOverride;

  /// Terminal compatibility transform for this instance.
  TerminalCompatibility get compatibility => configuration.compatibility;

  /// Fallback policy for high-level prompts that opt into line-mode fallback.
  TerminiceFallbackMode get fallbackMode => configuration.fallbackMode;

  /// Whether covered high-level prompts should use line-mode fallback for this
  /// instance's current terminal.
  bool get shouldUseFallback {
    return fallbackMode.shouldUseFallback(terminal ?? TerminalContext.current);
  }

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
    return Terminice._(configuration: configuration, terminal: terminal);
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

  /// Returns a new client using [config], preserving this instance's terminal.
  Terminice withConfig(TerminiceConfig config) {
    return Terminice._(configuration: config, terminal: terminal);
  }

  /// Returns a new client using [theme] as the base theme.
  ///
  /// Display feature overrides, compatibility, fallback mode, and terminal are
  /// preserved.
  Terminice withTheme(PromptTheme theme) {
    return withConfig(configuration.copyWith(baseTheme: theme));
  }

  /// Returns a new client using the provided [theme], preserving the terminal.
  Terminice themed(PromptTheme theme) {
    return withTheme(theme);
  }

  /// Returns a new client with a display feature override.
  Terminice withFeatures(DisplayFeatures features) {
    return withConfig(configuration.copyWith(featureOverride: features));
  }

  /// Returns a new client with the display feature override cleared.
  Terminice withoutFeatureOverride() {
    return withConfig(configuration.withoutFeatureOverride());
  }

  /// Returns a new client with [compatibility] applied to its effective theme.
  Terminice withCompatibility(TerminalCompatibility compatibility) {
    return withConfig(configuration.copyWith(compatibility: compatibility));
  }

  /// Rich terminal compatibility with no theme transform.
  Terminice get modern => withCompatibility(TerminalCompatibility.modern);

  /// ASCII glyphs and simpler features while preserving ANSI colors.
  Terminice get basic => withCompatibility(TerminalCompatibility.basic);

  /// ASCII glyphs, no ANSI colors, and minimal output.
  Terminice get legacy => withCompatibility(TerminalCompatibility.legacy);

  /// Returns a new client with [fallbackMode].
  Terminice withFallbackMode(TerminiceFallbackMode fallbackMode) {
    return withConfig(configuration.copyWith(fallbackMode: fallbackMode));
  }

  /// Always use rich prompts, preserving the legacy Terminice behavior.
  Terminice get interactive {
    return withFallbackMode(TerminiceFallbackMode.interactive);
  }

  /// Use line-mode fallback when stdin or stdout is not a terminal.
  Terminice get autoFallback {
    return withFallbackMode(TerminiceFallbackMode.auto);
  }

  /// Always use line-mode fallback for covered high-level prompts.
  Terminice get fallback {
    return withFallbackMode(TerminiceFallbackMode.fallback);
  }
}
