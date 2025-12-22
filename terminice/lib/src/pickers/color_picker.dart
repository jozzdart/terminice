import 'dart:math' as math;

import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Keyboard-first `colorPicker` prompt for Terminice.
///
/// This picker renders a high-density color grid with live ANSI swatch preview,
/// curated presets, quick saturation/brightness toggles, and hex-based entry so
/// users can work visually or by exact value. It mirrors the rest of the prompt
/// catalog by reusing `FrameView`, hint grids, and prompt theming.
///
/// **Controls**
/// - Arrow keys: move selection on the grid (wraps on the X axis)
/// - Enter: confirm currently highlighted color
/// - Esc: cancel and return `null`
/// - `S`: cycle through smart saturation breakpoints
/// - `[` / `]`: fine-tune saturation
/// - `-` / `=`: adjust brightness (value) on the grid
/// - `H`: type a hex code directly
/// - `1-0`: jump to curated presets, mirroring Tailwind hues
/// - `R`: random color
/// - `X`: reset back to `initialHex` or defaults
///
/// **Usage**
/// ```dart
/// final color = terminice.colorPicker(
///   'Accent color',
///   initialHex: '#FF0000',
///   cols: 24,
///   rows: 8,
/// );
/// print(color); // -> '#F97316' or null if cancelled
/// ```
extension ColorPickerPromptExtensions on Terminice {
  /// Presents an interactive color grid with ANSI preview + hex output.
  ///
  /// Parameters:
  /// - `label`: Title rendered in the frame header.
  /// - `initialHex`: Preselects a color when provided (accepts `#RRGGBB` or `RRGGBB`).
  /// - `cols`: Number of hue columns. Higher counts provide finer hue control.
  /// - `rows`: Number of value rows. More rows increase vertical resolution.
  ///
  /// Returns the chosen hex string in uppercase `#RRGGBB` format, or `null`
  /// when the user cancels (Esc) or the prompt runner reports `PromptResult.cancelled`.
  ///
  /// The prompt automatically surfaces contextual key hints, supports frame
  /// connectors, and keeps cursor handling consistent with the broader
  /// Terminice catalog making it safe for pub.dev distribution.
  String? colorPicker(
    String label, {
    String? initialHex,
    int cols = 24,
    int rows = 8,
  }) {
    final theme = defaultTheme;

    String? promptHexSync() {
      final termInput = TerminalContext.input;
      final termOutput = TerminalContext.output;
      termOutput.writeln('');
      final prevEcho = termInput.echoMode;
      final prevLine = termInput.lineMode;
      try {
        termInput.echoMode = true;
        termInput.lineMode = true;
        TerminalControl.showCursor();
        termOutput.write('${theme.accent}Hex${theme.reset} (#RRGGBB): ');
        final input = termInput.readLineSync();
        final value = input?.trim();
        if (value == null) return null;
        return value;
      } finally {
        termInput.echoMode = prevEcho;
        termInput.lineMode = prevLine;
        TerminalControl.hideCursor();
      }
    }

    int selX = 0;
    int selY = math.max(0, rows ~/ 2 - 1);
    double saturation = 1.0;
    int presetIndex = -1;
    bool cancelled = false;
    // Curated vibrant presets (Tailwind-like palette)
    List<Map<String, String>> presets = [
      {'h': '#EF4444'}, // Red 500
      {'h': '#F97316'}, // Orange 500
      {'h': '#F59E0B'}, // Amber 500
      {'h': '#EAB308'}, // Yellow 500
      {'h': '#84CC16'}, // Lime 500
      {'h': '#22C55E'}, // Green 500
      {'h': '#14B8A6'}, // Teal 500
      {'h': '#0EA5E9'}, // Sky 500
      {'h': '#3B82F6'}, // Blue 500
      {'h': '#8B5CF6'}, // Violet 500
    ];

    void setFromHex(String hex) {
      final rgb = _hexToRgb(hex);
      final hsv = _rgbToHsv(rgb[0], rgb[1], rgb[2]);
      selX = (hsv[0] / 360 * cols).round().clamp(0, cols - 1);
      final v = hsv[2].clamp(0.0, 1.0);
      selY = ((1 - v) * (rows - 1)).round().clamp(0, rows - 1);
      saturation = hsv[1].clamp(0.0, 1.0);
    }

    String selectedHex() {
      final hsv = _cellToHsv(selX, selY, cols, rows, saturation);
      final rgb = _hsvToRgb(hsv[0], hsv[1], hsv[2]);
      return _rgbToHex(rgb[0], rgb[1], rgb[2]);
    }

    KeyBindings buildBindings() {
      return KeyBindings.directionalNavigation(
            onUp: () => selY = math.max(0, selY - 1),
            onDown: () => selY = math.min(rows - 1, selY + 1),
            onLeft: () => selX = (selX - 1 + cols) % cols,
            onRight: () => selX = (selX + 1) % cols,
          ) +
          KeyBindings([
            // Saturation controls
            KeyBinding.char(
              (c) => c == '[',
              (event) {
                saturation = (saturation - 0.1).clamp(0.0, 1.0);
                return KeyActionResult.handled;
              },
              hintLabel: '[ / ]',
              hintDescription: 'sat − / +',
            ),
            KeyBinding.char(
              (c) => c == ']',
              (event) {
                saturation = (saturation + 0.1).clamp(0.0, 1.0);
                return KeyActionResult.handled;
              },
            ),
            // Brightness controls
            KeyBinding.char(
              (c) => c == '-',
              (event) {
                selY = math.min(rows - 1, selY + 1);
                return KeyActionResult.handled;
              },
              hintLabel: '- / =',
              hintDescription: 'bright − / +',
            ),
            KeyBinding.char(
              (c) => c == '=' || c == '+',
              (event) {
                selY = math.max(0, selY - 1);
                return KeyActionResult.handled;
              },
            ),
            // Cycle saturation
            KeyBinding.char(
              (c) => c == 's' || c == 'S',
              (event) {
                if (saturation > 0.9) {
                  saturation = 0.7;
                } else if (saturation > 0.6) {
                  saturation = 0.4;
                } else {
                  saturation = 1.0;
                }
                return KeyActionResult.handled;
              },
              hintLabel: 'S',
              hintDescription: 'cycle saturation',
            ),
            // Type hex
            KeyBinding.char(
              (c) => c == 'h' || c == 'H',
              (event) {
                final value = promptHexSync();
                if (value != null && _isValidHex(value)) {
                  setFromHex(value);
                  presetIndex = -1;
                }
                return KeyActionResult.handled;
              },
              hintLabel: 'H',
              hintDescription: 'type hex',
            ),
            // Reset
            KeyBinding.char(
              (c) => c == 'x' || c == 'X',
              (event) {
                if (initialHex != null && _isValidHex(initialHex)) {
                  setFromHex(initialHex);
                } else {
                  selX = 0;
                  selY = math.max(0, rows ~/ 2 - 1);
                  saturation = 1.0;
                  presetIndex = -1;
                }
                return KeyActionResult.handled;
              },
              hintLabel: 'X',
              hintDescription: 'reset',
            ),
            // Presets (1-0)
            KeyBinding.char(
              (c) => RegExp(r'^[0-9]$').hasMatch(c),
              (event) {
                final c = event.char!;
                int idx = c == '0' ? 9 : int.parse(c) - 1;
                if (idx < presets.length) {
                  setFromHex(presets[idx]['h']!);
                  presetIndex = idx;
                }
                return KeyActionResult.handled;
              },
              hintLabel: '1-0',
              hintDescription: 'presets',
            ),
            // Random
            KeyBinding.char(
              (c) => c == 'r' || c == 'R',
              (event) {
                selX = math.Random().nextInt(cols);
                selY = math.Random().nextInt(rows);
                presetIndex = -1;
                return KeyActionResult.handled;
              },
              hintLabel: 'R',
              hintDescription: 'random',
            ),
          ]) +
          KeyBindings.confirm() +
          KeyBindings.cancel(onCancel: () => cancelled = true);
    }

    if (initialHex != null && _isValidHex(initialHex)) {
      setFromHex(initialHex);
    }

    // Build key bindings
    final bindings = buildBindings();

    // Use WidgetFrame for consistent frame rendering
    final frame = FrameView(
      title: label,
      theme: theme,
      bindings: bindings,
    );

    void render(RenderOutput out) {
      frame.render(out, (ctx) {
        // Subtitle
        ctx.gutterLine(
            '${theme.accent}Pick visually. ${theme.reset}${theme.dim}(←/→ hue, ↑/↓ brightness, S saturation)${theme.reset}');

        // Connector after subtitle
        ctx.writeConnector();

        // Caret line
        final caretColumn = selX * 2;
        final caretPad = ' ' * caretColumn;
        ctx.gutterLine('$caretPad${theme.selection}^^${theme.reset}');

        // Color grid
        for (int y = 0; y < rows; y++) {
          final line = StringBuffer();
          line.write(ctx.lb.gutter());
          for (int x = 0; x < cols; x++) {
            final hsv = _cellToHsv(x, y, cols, rows, saturation);
            final rgb = _hsvToRgb(hsv[0], hsv[1], hsv[2]);
            final isSel = (x == selX && y == selY);
            line
              ..write(_bg(rgb[0], rgb[1], rgb[2]))
              ..write(isSel ? '${theme.inverse}  ${theme.reset}' : '  ')
              ..write(theme.reset);
          }
          ctx.line(line.toString());
        }

        // Presets line
        final presetsLine = StringBuffer();
        presetsLine.write(ctx.lb.gutter());
        for (int i = 0; i < presets.length; i++) {
          final hex = presets[i]['h']!;
          final rgb = _hexToRgb(hex);
          final isCur = i == presetIndex;
          final indexLabel = ((i + 1) % 10).toString();
          final labelText =
              isCur ? '${theme.inverse}$indexLabel${theme.reset}' : indexLabel;
          presetsLine
            ..write(_bg(rgb[0], rgb[1], rgb[2]))
            ..write(' $labelText ')
            ..write(theme.reset);
        }
        ctx.line(presetsLine.toString());

        // Swatch and hex
        final hex = selectedHex();
        final rgb = _hexToRgb(hex);
        final swatch = '${_bg(rgb[0], rgb[1], rgb[2])}      ${theme.reset}';
        ctx.gutterLine('$swatch ${theme.accent}$hex${theme.reset}');
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    return (cancelled || result == PromptResult.cancelled)
        ? null
        : selectedHex();
  }
}

// ───────────────────────── Utilities ─────────────────────────

/// Returns `true` when [s] matches `RRGGBB` with an optional leading `#`.
bool _isValidHex(String s) => RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(s.trim());

/// Parses a hex string into `[r, g, b]` channel values.
List<int> _hexToRgb(String hex) {
  final h = hex.startsWith('#') ? hex.substring(1) : hex;
  final r = int.parse(h.substring(0, 2), radix: 16);
  final g = int.parse(h.substring(2, 4), radix: 16);
  final b = int.parse(h.substring(4, 6), radix: 16);
  return [r, g, b];
}

/// Formats RGB integers as an uppercase `#RRGGBB` string.
String _rgbToHex(int r, int g, int b) {
  String two(int v) => v.toRadixString(16).padLeft(2, '0');
  return '#${two(r)}${two(g)}${two(b)}'.toUpperCase();
}

/// Converts HSV (h ∈ [0, 360), s,v ∈ [0, 1]) into an RGB triple.
List<int> _hsvToRgb(double h, double s, double v) {
  final c = v * s;
  final hp = (h % 360) / 60.0;
  final x = c * (1 - (hp % 2 - 1).abs());
  double r1 = 0, g1 = 0, b1 = 0;
  if (hp < 1) {
    r1 = c;
    g1 = x;
  } else if (hp < 2) {
    r1 = x;
    g1 = c;
  } else if (hp < 3) {
    g1 = c;
    b1 = x;
  } else if (hp < 4) {
    g1 = x;
    b1 = c;
  } else if (hp < 5) {
    r1 = x;
    b1 = c;
  } else {
    r1 = c;
    b1 = x;
  }
  final m = v - c;
  final r = ((r1 + m) * 255).round().clamp(0, 255);
  final g = ((g1 + m) * 255).round().clamp(0, 255);
  final b = ((b1 + m) * 255).round().clamp(0, 255);
  return [r, g, b];
}

/// Converts RGB 0-255 values to HSV with h ∈ [0, 360), s,v ∈ [0, 1].
List<double> _rgbToHsv(int r, int g, int b) {
  final double rf = r / 255.0;
  final double gf = g / 255.0;
  final double bf = b / 255.0;
  final double maxv = [rf, gf, bf].reduce(math.max);
  final double minv = [rf, gf, bf].reduce(math.min);
  final double d = maxv - minv;
  double h = 0.0;
  if (d == 0) {
    h = 0.0;
  } else if (maxv == rf) {
    h = 60 * (((gf - bf) / d) % 6);
  } else if (maxv == gf) {
    h = 60 * (((bf - rf) / d) + 2);
  } else {
    h = 60 * (((rf - gf) / d) + 4);
  }
  if (h < 0) h += 360;
  final double s = maxv == 0.0 ? 0.0 : d / maxv;
  final double v = maxv;
  return [h, s, v];
}

/// ANSI background escape for a full-color swatch.
String _bg(int r, int g, int b) => '\x1B[48;2;$r;$g;${b}m';

/// Maps a grid cell to HSV values based on the configured cols/rows + sat.
List<double> _cellToHsv(int x, int y, int cols, int rows, double sat) {
  final hue = (x / (cols)) * 360.0;
  final s = sat.clamp(0.0, 1.0);
  // Bright at top row, darker towards bottom (min ~0.35)
  final v = 1.0 - (y / (rows - 1)) * 0.65;
  return [hue, s, v];
}
