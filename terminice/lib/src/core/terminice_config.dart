import 'package:terminice_core/terminice_core.dart';

/// Policy for choosing high-level line-mode fallbacks.
///
/// This policy only describes when covered high-level prompts should use
/// [FallbackPrompt]. Individual prompts opt into it separately.
enum TerminiceFallbackMode {
  /// Always use the existing rich, interactive prompt implementations.
  interactive,

  /// Use line-mode fallback when either input or output is not a terminal.
  auto,

  /// Always use line-mode fallback for covered high-level prompts.
  fallback;

  /// Whether this mode should use line-mode fallback for [terminal].
  bool shouldUseFallback(Terminal terminal) {
    switch (this) {
      case TerminiceFallbackMode.interactive:
        return false;
      case TerminiceFallbackMode.auto:
        return !terminal.input.hasTerminal || !terminal.output.hasTerminal;
      case TerminiceFallbackMode.fallback:
        return true;
    }
  }
}

/// Immutable configuration shared by a Terminice instance.
///
/// The effective theme is resolved in this order:
/// [baseTheme], then [featureOverride], then [compatibility].
class TerminiceConfig {
  /// Unmodified theme chosen by the caller.
  final PromptTheme baseTheme;

  /// Optional display feature override applied after [baseTheme].
  final DisplayFeatures? featureOverride;

  /// Compatibility transform applied after display features are resolved.
  final TerminalCompatibility compatibility;

  /// Fallback policy for high-level prompts that support line-mode fallback.
  final TerminiceFallbackMode fallbackMode;

  /// Creates an immutable Terminice configuration.
  const TerminiceConfig({
    this.baseTheme = PromptTheme.dark,
    this.featureOverride,
    this.compatibility = TerminalCompatibility.modern,
    this.fallbackMode = TerminiceFallbackMode.interactive,
  });

  /// Theme produced by applying display and compatibility settings.
  PromptTheme get effectiveTheme => applyTo(baseTheme);

  /// Applies this configuration's display and compatibility settings to
  /// [theme].
  PromptTheme applyTo(PromptTheme theme) {
    final featuredTheme = featureOverride == null
        ? theme
        : theme.copyWith(features: featureOverride);
    return compatibility.applyTo(featuredTheme);
  }

  /// Returns a copy with selected settings replaced.
  TerminiceConfig copyWith({
    PromptTheme? baseTheme,
    DisplayFeatures? featureOverride,
    bool clearFeatureOverride = false,
    TerminalCompatibility? compatibility,
    TerminiceFallbackMode? fallbackMode,
  }) {
    return TerminiceConfig(
      baseTheme: baseTheme ?? this.baseTheme,
      featureOverride:
          clearFeatureOverride ? null : featureOverride ?? this.featureOverride,
      compatibility: compatibility ?? this.compatibility,
      fallbackMode: fallbackMode ?? this.fallbackMode,
    );
  }

  /// Returns a copy with [featureOverride] cleared.
  TerminiceConfig withoutFeatureOverride() {
    return copyWith(clearFeatureOverride: true);
  }
}
