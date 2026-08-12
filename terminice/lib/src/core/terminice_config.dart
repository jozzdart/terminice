import 'dart:io' show Platform;

import 'package:terminice_core/terminice_core.dart';

/// The effective way a built-in Terminice component should execute.
enum TerminiceExecutionMode {
  /// Full-screen or raw-key interaction on a capable terminal.
  rich,

  /// Line-oriented interaction for a terminal with unsuitable output.
  line,

  /// Non-interactive execution that must not read from standard input.
  unattended,
}

/// Policy controlling color output from a high-level [Terminice] client.
enum TerminiceColorMode {
  /// Use colors unless the process has a non-empty `NO_COLOR` variable.
  auto,

  /// Use the configured colors regardless of `NO_COLOR`.
  always,

  /// Suppress foreground and background colors.
  never,
}

/// Policy for choosing built-in rich, line-oriented, or unattended execution.
enum TerminiceFallbackMode {
  /// Always use the existing rich, interactive prompt implementations.
  interactive,

  /// Automatically select rich, line-oriented, or unattended execution.
  auto,

  /// Always use line-mode fallback for built-in components.
  fallback;

  /// Resolves the effective execution mode for [terminal].
  ///
  /// [term] overrides the value exposed by an optional [TerminalEnvironment].
  /// Supplying it explicitly makes capability resolution deterministic in
  /// tests and embedded runtimes. Terminal capability probe failures are
  /// treated conservatively.
  TerminiceExecutionMode executionModeFor(Terminal terminal, {String? term}) {
    switch (this) {
      case TerminiceFallbackMode.interactive:
        return TerminiceExecutionMode.rich;
      case TerminiceFallbackMode.fallback:
        return TerminiceExecutionMode.line;
      case TerminiceFallbackMode.auto:
        if (!_hasInputTerminal(terminal)) {
          return TerminiceExecutionMode.unattended;
        }

        final effectiveTerm = term ?? _terminalType(terminal);
        if (!_hasOutputTerminal(terminal) || _isDumbTerminal(effectiveTerm)) {
          return TerminiceExecutionMode.line;
        }
        return TerminiceExecutionMode.rich;
    }
  }

  /// Whether this mode uses the compatibility line-mode fallback view.
  ///
  /// Unattended execution is also reported as fallback here for compatibility
  /// with callers written before [TerminiceExecutionMode] was introduced.
  bool shouldUseFallback(Terminal terminal) {
    return executionModeFor(terminal) != TerminiceExecutionMode.rich;
  }
}

bool _hasInputTerminal(Terminal terminal) {
  try {
    return terminal.input.hasTerminal;
  } catch (_) {
    return false;
  }
}

bool _hasOutputTerminal(Terminal terminal) {
  try {
    return terminal.output.hasTerminal;
  } catch (_) {
    return false;
  }
}

String? _terminalType(Terminal terminal) {
  if (terminal is! TerminalEnvironment) return null;
  try {
    return (terminal as TerminalEnvironment).terminalType;
  } catch (_) {
    return 'dumb';
  }
}

bool _isDumbTerminal(String? term) => term?.trim().toLowerCase() == 'dumb';

/// Immutable configuration shared by a Terminice instance.
///
/// The effective theme is resolved in this order:
/// [baseTheme], then [featureOverride], [compatibility], and [colorMode].
class TerminiceConfig {
  /// Unmodified theme chosen by the caller.
  final PromptTheme baseTheme;

  /// Optional display feature override applied after [baseTheme].
  final DisplayFeatures? featureOverride;

  /// Compatibility transform applied after display features are resolved.
  final TerminalCompatibility compatibility;

  /// Execution policy shared by built-in components.
  final TerminiceFallbackMode fallbackMode;

  /// Policy controlling whether the effective theme uses colors.
  final TerminiceColorMode colorMode;

  /// Creates an immutable Terminice configuration.
  const TerminiceConfig({
    this.baseTheme = PromptTheme.dark,
    this.featureOverride,
    this.compatibility = TerminalCompatibility.modern,
    this.fallbackMode = TerminiceFallbackMode.auto,
    this.colorMode = TerminiceColorMode.auto,
  });

  /// Theme produced by applying display, compatibility, and color settings.
  PromptTheme get effectiveTheme => applyTo(baseTheme);

  /// Applies this configuration's display, compatibility, and color settings
  /// to [theme].
  ///
  PromptTheme applyTo(PromptTheme theme) {
    final featuredTheme = featureOverride == null
        ? theme
        : theme.copyWith(features: featureOverride);
    final compatibleTheme = compatibility.applyTo(featuredTheme);
    if (!_shouldSuppressColors(Platform.environment)) {
      return compatibleTheme;
    }
    return compatibleTheme.copyWith(
      colors: compatibleTheme.colors.withoutColors(),
    );
  }

  bool _shouldSuppressColors(Map<String, String> environment) {
    switch (colorMode) {
      case TerminiceColorMode.auto:
        return environment['NO_COLOR']?.isNotEmpty ?? false;
      case TerminiceColorMode.always:
        return false;
      case TerminiceColorMode.never:
        return true;
    }
  }

  /// Returns a copy with selected settings replaced.
  TerminiceConfig copyWith({
    PromptTheme? baseTheme,
    DisplayFeatures? featureOverride,
    bool clearFeatureOverride = false,
    TerminalCompatibility? compatibility,
    TerminiceFallbackMode? fallbackMode,
    TerminiceColorMode? colorMode,
  }) {
    return TerminiceConfig(
      baseTheme: baseTheme ?? this.baseTheme,
      featureOverride:
          clearFeatureOverride ? null : featureOverride ?? this.featureOverride,
      compatibility: compatibility ?? this.compatibility,
      fallbackMode: fallbackMode ?? this.fallbackMode,
      colorMode: colorMode ?? this.colorMode,
    );
  }

  /// Returns a copy with [featureOverride] cleared.
  TerminiceConfig withoutFeatureOverride() {
    return copyWith(clearFeatureOverride: true);
  }
}
