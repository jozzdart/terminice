/// Spinner frame styles.
enum SpinnerFrames { dots, bars, arcs }

/// Unicode dot-style spinner frames (braille characters).
const List<String> dotsFrames = [
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

/// Unicode bar-style spinner frames (block elements).
const List<String> barsFrames = [
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

/// Unicode arc-style spinner frames (quarter-circle characters).
const List<String> arcsFrames = ['◜', '◠', '◝', '◞', '◡', '◟'];

/// Returns the frame list for the given [SpinnerFrames] style.
List<String> spinnerFramesList(SpinnerFrames style) {
  switch (style) {
    case SpinnerFrames.dots:
      return dotsFrames;
    case SpinnerFrames.bars:
      return barsFrames;
    case SpinnerFrames.arcs:
      return arcsFrames;
  }
}
