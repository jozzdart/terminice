import 'package:terminice_core/terminice_core.dart';

// ════════════════════════════════════════════════════════════════════════════
// SPINNER FRAME STYLES
// ════════════════════════════════════════════════════════════════════════════

/// Spinner frame styles.
enum SpinnerFrames { dots, bars, arcs }

// ════════════════════════════════════════════════════════════════════════════
// INLINE STYLE
// ════════════════════════════════════════════════════════════════════════════

/// InlineStyle – theme-aware inline text styling utilities.
///
/// Use for inline components that return styled strings rather than rendering
/// to output (badges, labels, status indicators).
///
/// Example:
/// ```dart
/// final inline = InlineStyle(theme);
/// stdout.writeln('Status: ${inline.badge("SUCCESS", tone: BadgeTone.success)}');
/// stdout.writeln('Build ${inline.spinner(phase)} Processing...');
/// ```
class InlineStyle {
  final PromptTheme theme;

  const InlineStyle(this.theme);

  // ──────────────────────────────────────────────────────────────────────────
  // BADGE STYLING
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates an inline badge string: [ SUCCESS ]
  String badge(
    String text, {
    BadgeTone tone = BadgeTone.info,
    bool inverted = true,
    bool bracketed = true,
    bool bold = true,
  }) {
    final color = _badgeToneColor(tone);
    final label = ' $text ';

    if (bracketed) {
      if (inverted) {
        final body = '[$label]';
        return '${bold ? theme.bold : ''}${theme.inverse}$color$body${theme.reset}';
      }
      final inner = '${bold ? theme.bold : ''}$color$label${theme.reset}';
      return '[$inner]';
    }

    if (inverted) {
      return '${bold ? theme.bold : ''}${theme.inverse}$color$label${theme.reset}';
    }
    return '${bold ? theme.bold : ''}$color$label${theme.reset}';
  }

  /// Shorthand for success badge.
  String successBadge(String text) => badge(text, tone: BadgeTone.success);

  /// Shorthand for info badge.
  String infoBadge(String text) => badge(text, tone: BadgeTone.info);

  /// Shorthand for warning badge.
  String warnBadge(String text) => badge(text, tone: BadgeTone.warning);

  /// Shorthand for danger badge.
  String dangerBadge(String text) => badge(text, tone: BadgeTone.danger);

  // ──────────────────────────────────────────────────────────────────────────
  // SPINNER FRAMES
  // ──────────────────────────────────────────────────────────────────────────

  static const List<String> dotsFrames = [
    '⠋',
    '⠙',
    '⠹',
    '⠸',
    '⠼',
    '⠴',
    '⠦',
    '⠧',
    '⠇',
    '⠏'
  ];
  static const List<String> barsFrames = [
    '▁',
    '▂',
    '▃',
    '▄',
    '▅',
    '▆',
    '▇',
    '█',
    '▇',
    '▆',
    '▅',
    '▄',
    '▃',
    '▂'
  ];
  static const List<String> arcsFrames = ['◜', '◠', '◝', '◞', '◡', '◟'];

  /// Returns a spinner frame for the given phase.
  String spinner(int phase, {SpinnerFrames frames = SpinnerFrames.dots}) {
    final list = _spinnerFramesList(frames);
    final char = list[phase % list.length];
    final color = (phase % 2 == 0) ? theme.accent : theme.highlight;
    return '${theme.bold}$color$char${theme.reset}';
  }

  List<String> _spinnerFramesList(SpinnerFrames f) {
    switch (f) {
      case SpinnerFrames.dots:
        return dotsFrames;
      case SpinnerFrames.bars:
        return barsFrames;
      case SpinnerFrames.arcs:
        return arcsFrames;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INLINE TEXT STYLING
  // ──────────────────────────────────────────────────────────────────────────

  /// Applies accent color to text.
  String accent(String text) => '${theme.accent}$text${theme.reset}';

  /// Applies highlight color to text.
  String highlight(String text) => '${theme.highlight}$text${theme.reset}';

  /// Applies selection color to text.
  String selection(String text) => '${theme.selection}$text${theme.reset}';

  /// Applies dim styling to text.
  String dim(String text) => '${theme.dim}$text${theme.reset}';

  /// Applies bold styling to text.
  String bold(String text) => '${theme.bold}$text${theme.reset}';

  /// Applies gray color to text.
  String gray(String text) => '${theme.gray}$text${theme.reset}';

  /// Applies info color to text.
  String info(String text) => '${theme.info}$text${theme.reset}';

  /// Applies warn color to text.
  String warn(String text) => '${theme.warn}$text${theme.reset}';

  /// Applies error color to text.
  String error(String text) => '${theme.error}$text${theme.reset}';

  /// Applies inverse styling to text.
  String inverse(String text) => '${theme.inverse}$text${theme.reset}';

  // ──────────────────────────────────────────────────────────────────────────
  // INLINE ICONS
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns a styled icon with the given tone color.
  String icon(String char, {StatTone tone = StatTone.accent}) {
    final color = toneColor(tone, theme);
    return '${theme.bold}$color$char${theme.reset}';
  }

  /// Success icon (✔).
  String successIcon() => icon('✔', tone: StatTone.success);

  /// Error icon (✖).
  String errorIcon() => icon('✖', tone: StatTone.error);

  /// Warning icon (⚠).
  String warnIcon() => icon('⚠', tone: StatTone.warn);

  /// Info icon (ℹ).
  String infoIcon() => icon('ℹ', tone: StatTone.info);

  // ──────────────────────────────────────────────────────────────────────────
  // PROGRESS INDICATORS
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates an inline progress bar: ████░░░░ 75%
  String progressBar(
    double ratio, {
    int width = 10,
    bool showPercent = true,
    String filledChar = '█',
    String emptyChar = '░',
  }) {
    final clamped = ratio.clamp(0.0, 1.0);
    final filled = (clamped * width).round();
    final bar =
        '${theme.accent}${filledChar * filled}${theme.reset}${theme.dim}${emptyChar * (width - filled)}${theme.reset}';
    if (showPercent) {
      final pct = (clamped * 100).round();
      return '$bar ${dim('$pct%')}';
    }
    return bar;
  }

  String _badgeToneColor(BadgeTone tone) {
    switch (tone) {
      case BadgeTone.neutral:
        return theme.gray;
      case BadgeTone.info:
        return theme.accent;
      case BadgeTone.success:
        return theme.checkboxOn;
      case BadgeTone.warning:
        return theme.highlight;
      case BadgeTone.danger:
        return theme.highlight;
    }
  }
}

/// Returns the ANSI color for a [StatTone].
String toneColor(StatTone tone, PromptTheme theme) {
  switch (tone) {
    case StatTone.info:
      return theme.info;
    case StatTone.warn:
      return theme.warn;
    case StatTone.error:
      return theme.error;
    case StatTone.accent:
      return theme.accent;
    case StatTone.success:
      return theme.checkboxOn;
    case StatTone.neutral:
      return theme.gray;
  }
}
