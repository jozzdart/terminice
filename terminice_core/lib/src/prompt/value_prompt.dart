import 'dart:math' as math;

import 'package:terminice_core/terminice_core.dart';

/// ValuePrompt – composable system for continuous value selection.
///
/// Handles patterns for numeric/continuous value input:
/// - Sliders (single value)
/// - Ratings (discrete stars)
/// - Ranges (two values with handles)
///
/// **Usage:**
/// ```dart
/// final prompt = ValuePrompt(
///   title: 'Volume',
///   min: 0,
///   max: 100,
///   initial: 50,
/// );
///
/// final value = prompt.run(
///   render: (ctx, value, ratio) {
///     ctx.sliderBar(ratio);
///     ctx.labeledAccent('Value', '$value%');
///   },
/// );
/// ```
class ValuePrompt {
  /// Title for the frame header.
  final String title;

  /// Minimum value.
  final num min;

  /// Maximum value.
  final num max;

  /// Initial value.
  final num initial;

  /// Step size for adjustments.
  final num step;

  /// Theme for styling.
  final PromptTheme theme;

  /// Hint style for key bindings display.
  final HintStyle hintStyle;

  late num _value;
  late KeyBindings _bindings;
  bool _cancelled = false;

  ValuePrompt({
    required this.title,
    this.min = 0,
    this.max = 100,
    this.initial = 50,
    this.step = 1,
    this.theme = PromptTheme.dark,
    this.hintStyle = HintStyle.bullets,
  });

  /// Current value.
  num get value => _value;

  /// Current value as ratio (0.0 to 1.0).
  double get ratio => ((_value - min) / (max - min)).clamp(0.0, 1.0);

  /// Current key bindings.
  KeyBindings get bindings => _bindings;

  /// Whether the prompt was cancelled.
  bool get wasCancelled => _cancelled;

  /// Runs the value prompt with custom rendering.
  num run({
    required void Function(FrameContext ctx, num value, double ratio) render,
    KeyBindings? extraBindings,
    bool useNumberKeys = false,
    int numberKeyMax = 9,
  }) {
    _initState();

    _bindings = KeyBindings.horizontalNavigation(
      onLeft: () => _value = math.max(min, _value - step),
      onRight: () => _value = math.min(max, _value + step),
    );

    if (useNumberKeys) {
      _bindings = _bindings +
          KeyBindings.numbers(
            onNumber: (n) {
              if (n >= 1 && n <= numberKeyMax) {
                final normalized = (n - 1) / (numberKeyMax - 1);
                _value = min + normalized * (max - min);
              }
            },
            max: numberKeyMax,
            hintLabel: '1–$numberKeyMax',
            hintDescription: 'set value',
          );
    }

    _bindings =
        _bindings + KeyBindings.prompt(onCancel: () => _cancelled = true);

    if (extraBindings != null) {
      _bindings = _bindings + extraBindings;
    }

    final frame = FrameView(
      title: title,
      theme: theme,
      bindings: _bindings,
      hintStyle: hintStyle,
    );

    void renderFrame(RenderOutput out) {
      frame.render(out, (ctx) {
        render(ctx, _value, ratio);
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: renderFrame,
      bindings: _bindings,
    );

    return (result == PromptResult.cancelled || _cancelled) ? initial : _value;
  }

  void _initState() {
    _cancelled = false;
    _value = initial.clamp(min, max);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DISCRETE VALUE PROMPT (Rating style)
// ════════════════════════════════════════════════════════════════════════════

/// DiscreteValuePrompt – for discrete value selection (ratings, stars).
class DiscreteValuePrompt {
  /// Title for the frame header.
  final String title;

  /// Maximum value (1 to maxValue).
  final int maxValue;

  /// Initial value.
  final int initial;

  /// Theme for styling.
  final PromptTheme theme;

  /// Hint style for key bindings display.
  final HintStyle hintStyle;

  late int _value;
  late KeyBindings _bindings;
  bool _cancelled = false;

  DiscreteValuePrompt({
    required this.title,
    this.maxValue = 5,
    this.initial = 3,
    this.theme = PromptTheme.dark,
    this.hintStyle = HintStyle.grid,
  }) : assert(maxValue > 0);

  /// Current value.
  int get value => _value;

  /// Current key bindings.
  KeyBindings get bindings => _bindings;

  /// Whether the prompt was cancelled.
  bool get wasCancelled => _cancelled;

  /// Runs the discrete value prompt.
  int run({
    required void Function(FrameContext ctx, int value, int maxValue) render,
    KeyBindings? extraBindings,
  }) {
    _initState();

    _bindings = KeyBindings.horizontalNavigation(
          onLeft: () => _value = (_value - 1).clamp(1, maxValue),
          onRight: () => _value = (_value + 1).clamp(1, maxValue),
        ) +
        KeyBindings.numbers(
          onNumber: (n) {
            if (n >= 1 && n <= maxValue) _value = n;
          },
          max: maxValue,
          hintLabel: '1–$maxValue',
          hintDescription: 'set exact',
        ) +
        KeyBindings.prompt(onCancel: () => _cancelled = true);

    if (extraBindings != null) {
      _bindings = _bindings + extraBindings;
    }

    final frame = FrameView(
      title: title,
      theme: theme,
      bindings: _bindings,
      showConnector: true,
      hintStyle: hintStyle,
    );

    void renderFrame(RenderOutput out) {
      frame.render(out, (ctx) {
        render(ctx, _value, maxValue);
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: renderFrame,
      bindings: _bindings,
    );

    return (result == PromptResult.cancelled || _cancelled)
        ? initial.clamp(1, maxValue)
        : _value;
  }

  void _initState() {
    _cancelled = false;
    _value = initial.clamp(1, maxValue);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// RANGE VALUE PROMPT (Two handles)
// ════════════════════════════════════════════════════════════════════════════

/// RangeValuePrompt – for selecting a range with two handles.
class RangeValuePrompt {
  /// Title for the frame header.
  final String title;

  /// Minimum value.
  final num min;

  /// Maximum value.
  final num max;

  /// Initial start value.
  final num startInitial;

  /// Initial end value.
  final num endInitial;

  /// Step size for adjustments.
  final num step;

  /// Theme for styling.
  final PromptTheme theme;

  /// Hint style for key bindings display.
  final HintStyle hintStyle;

  late num _start;
  late num _end;
  late bool _editingStart;
  late KeyBindings _bindings;
  bool _cancelled = false;

  RangeValuePrompt({
    required this.title,
    this.min = 0,
    this.max = 100,
    this.startInitial = 20,
    this.endInitial = 80,
    this.step = 1,
    this.theme = PromptTheme.dark,
    this.hintStyle = HintStyle.bullets,
  });

  /// Current start value.
  num get start => _start;

  /// Current end value.
  num get end => _end;

  /// Whether currently editing start (vs end).
  bool get editingStart => _editingStart;

  /// Current key bindings.
  KeyBindings get bindings => _bindings;

  /// Whether the prompt was cancelled.
  bool get wasCancelled => _cancelled;

  /// Runs the range value prompt.
  (num start, num end) run({
    required void Function(
      FrameContext ctx,
      num start,
      num end,
      bool editingStart,
    ) render,
    KeyBindings? extraBindings,
  }) {
    _initState();

    _bindings = KeyBindings([
          KeyBinding.multi(
            {KeyEventType.arrowUp, KeyEventType.arrowDown, KeyEventType.space},
            (event) {
              _editingStart = !_editingStart;
              return KeyActionResult.handled;
            },
            hintLabel: '↑/↓/Space',
            hintDescription: 'toggle handle',
          ),
        ]) +
        KeyBindings.horizontalNavigation(
          onLeft: () {
            if (_editingStart) {
              _start = math.max(min, _start - step);
              if (_start > _end) _end = _start;
            } else {
              _end = math.max(min, _end - step);
              if (_end < _start) _start = _end;
            }
            _start = _start.clamp(min, max);
            _end = _end.clamp(min, max);
          },
          onRight: () {
            if (_editingStart) {
              _start = math.min(max, _start + step);
              if (_start > _end) _end = _start;
            } else {
              _end = math.min(max, _end + step);
              if (_end < _start) _start = _end;
            }
            _start = _start.clamp(min, max);
            _end = _end.clamp(min, max);
          },
        ) +
        KeyBindings.prompt(onCancel: () => _cancelled = true);

    if (extraBindings != null) {
      _bindings = _bindings + extraBindings;
    }

    final frame = FrameView(
      title: title,
      theme: theme,
      bindings: _bindings,
      hintStyle: hintStyle,
    );

    void renderFrame(RenderOutput out) {
      frame.render(out, (ctx) {
        render(ctx, _start, _end, _editingStart);
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: renderFrame,
      bindings: _bindings,
    );

    return (result == PromptResult.cancelled || _cancelled)
        ? (startInitial, endInitial)
        : (_start, _end);
  }

  void _initState() {
    _cancelled = false;
    _start = math.min(startInitial, endInitial).clamp(min, max);
    _end = math.max(startInitial, endInitial).clamp(min, max);
    _editingStart = true;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// RENDERING HELPERS
// ════════════════════════════════════════════════════════════════════════════

/// Helper extension for rendering value prompts.
extension ValuePromptRendering on FrameContext {
  /// Renders a slider bar with head indicator.
  void sliderBar(
    double ratio, {
    int width = 28,
    String filledChar = '█',
    String emptyChar = '·',
    String? headChar,
    bool showPercent = true,
  }) {
    final clamped = ratio.clamp(0.0, 1.0);
    final filled = (clamped * width).round();
    final pct = (clamped * 100).round();

    final filledPart = '${theme.accent}${filledChar * filled}${theme.reset}';
    final head = headChar ?? (pct < 50 ? '◉' : '●');
    final emptyPart =
        '${theme.dim}${emptyChar * (width - filled)}${theme.reset}';

    final percentPart = showPercent ? ' ${theme.dim}$pct%${theme.reset}' : '';

    gutterLine(
        '$filledPart${theme.accent}$head${theme.reset}$emptyPart$percentPart');
  }

  /// Renders star rating display.
  void starsDisplay(
    int value,
    int maxStars, {
    String filledStar = '★',
    String emptyStar = '☆',
  }) {
    final buffer = StringBuffer();
    for (int i = 1; i <= maxStars; i++) {
      final isFilled = i <= value;
      final isCurrent = i == value;
      final color =
          isCurrent ? theme.highlight : (isFilled ? theme.accent : theme.gray);
      final glyph = isFilled ? filledStar : emptyStar;
      final star = isCurrent ? '${theme.bold}$glyph${theme.reset}' : glyph;
      buffer.write('$color$star${theme.reset}');
      if (i < maxStars) buffer.write(' ');
    }
    gutterLine(buffer.toString());
  }

  /// Renders numeric scale display.
  void numericScale(int value, int max) {
    final buffer = StringBuffer();
    for (int i = 1; i <= max; i++) {
      final color = i == value ? theme.accent : theme.dim;
      buffer.write('$color$i${theme.reset}');
      if (i < max) buffer.write(' ');
    }
    gutterLine(
        '$buffer   ${theme.dim}(${theme.reset}${theme.accent}$value${theme.reset}${theme.dim}/$max)${theme.reset}');
  }
}
