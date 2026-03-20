/// Semantic badge tones shared by style-aware components.
///
/// Widgets such as badges, inline labels, and frame decorators resolve these
/// tones through the active [PromptTheme] to stay visually consistent. Prefer
/// using a tone instead of hard-coding colors so downstream themes can adapt.
enum BadgeTone {
  /// Neutral/default emphasis (often rendered as gray).
  neutral,

  /// Informational state that maps to the accent color.
  info,

  /// Success/positive signal (typically green / checkbox-on color).
  success,

  /// Warning/semi-critical emphasis (usually highlight/yellow).
  warning,

  /// Danger/critical emphasis (typically red).
  danger,
}
