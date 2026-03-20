/// Tone for stat/styled items.
///
/// Used by style-aware components to resolve semantic colors through the
/// active [PromptTheme]. Prefer using a tone instead of hard-coding colors
/// so downstream themes can adapt.
enum StatTone {
  /// Informational state (maps to theme info color).
  info,

  /// Warning state (maps to theme warn color).
  warn,

  /// Error state (maps to theme error color).
  error,

  /// Accent state (maps to theme accent color).
  accent,

  /// Success state (maps to theme checkboxOn color).
  success,

  /// Neutral state (maps to theme gray color).
  neutral,
}
