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
/// - `H`: type a hex code inline (Enter to apply, Esc to discard)
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
  String? colorPicker(
    String label, {
    String? initialHex,
    int cols = 24,
    int rows = 8,
  }) {
    final theme = defaultTheme;

    int selX = 0;
    int selY = math.max(0, rows ~/ 2 - 1);
    double saturation = 1.0;
    int presetIndex = -1;
    bool cancelled = false;

    bool hexMode = false;
    final hexInput = TextInputBuffer(maxLength: 7);

    final presets = [
      '#EF4444', // Red 500
      '#F97316', // Orange 500
      '#F59E0B', // Amber 500
      '#EAB308', // Yellow 500
      '#84CC16', // Lime 500
      '#22C55E', // Green 500
      '#14B8A6', // Teal 500
      '#0EA5E9', // Sky 500
      '#3B82F6', // Blue 500
      '#8B5CF6', // Violet 500
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

    // Hex mode intercepts all navigation/text keys while active. When
    // inactive, returns `ignored` so normal grid bindings fire instead.
    final hexModeBindings = KeyBindings([
      KeyBinding(
        keys: {
          KeyEventType.char,
          KeyEventType.space,
          KeyEventType.backspace,
          KeyEventType.arrowLeft,
          KeyEventType.arrowRight,
          KeyEventType.arrowUp,
          KeyEventType.arrowDown,
        },
        action: (event) {
          if (!hexMode) return KeyActionResult.ignored;
          hexInput.handleKey(event);
          return KeyActionResult.handled;
        },
      ),
    ]);

    final enterBinding = KeyBindings([
      KeyBinding.single(
        KeyEventType.enter,
        (event) {
          if (!hexMode) return KeyActionResult.confirmed;
          final value = hexInput.text.trim();
          if (_isValidHex(value)) {
            setFromHex(value);
            presetIndex = -1;
          }
          hexMode = false;
          return KeyActionResult.handled;
        },
        hintLabel: 'Enter',
        hintDescription: 'confirm',
      ),
    ]);

    final escBinding = KeyBindings([
      KeyBinding.multi(
        {KeyEventType.esc, KeyEventType.ctrlC},
        (event) {
          if (hexMode) {
            hexMode = false;
            return KeyActionResult.handled;
          }
          cancelled = true;
          return KeyActionResult.cancelled;
        },
        hintLabel: 'Esc',
        hintDescription: 'cancel',
      ),
    ]);

    final gridBindings = KeyBindings.directionalNavigation(
          onUp: () => selY = math.max(0, selY - 1),
          onDown: () => selY = math.min(rows - 1, selY + 1),
          onLeft: () => selX = (selX - 1 + cols) % cols,
          onRight: () => selX = (selX + 1) % cols,
        ) +
        KeyBindings([
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
          KeyBinding.char(
            (c) => c == 'h' || c == 'H',
            (event) {
              hexMode = true;
              hexInput.clear();
              hexInput.insert('#');
              return KeyActionResult.handled;
            },
            hintLabel: 'H',
            hintDescription: 'type hex',
          ),
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
          KeyBinding.char(
            (c) => RegExp(r'^[0-9]$').hasMatch(c),
            (event) {
              final c = event.char!;
              int idx = c == '0' ? 9 : int.parse(c) - 1;
              if (idx < presets.length) {
                setFromHex(presets[idx]);
                presetIndex = idx;
              }
              return KeyActionResult.handled;
            },
            hintLabel: '1-0',
            hintDescription: 'presets',
          ),
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
        ]);

    if (initialHex != null && _isValidHex(initialHex)) {
      setFromHex(initialHex);
    }

    // Hex mode bindings come first to intercept keys when active.
    final bindings = hexModeBindings + gridBindings + enterBinding + escBinding;

    // We disable hints in the frame so we can render them manually with wrapping
    // to prevent terminal line-wrapping from breaking the clear-lines count.
    final frame = FrameView(
      title: label,
      theme: theme.copyWith(
        features: theme.features.copyWith(hintStyle: HintStyle.none),
      ),
      bindings: bindings,
    );

    void render(RenderOutput out) {
      frame.render(out, (ctx) {
        ctx.gutterLine(
            '${theme.accent}Pick visually. ${theme.reset}${theme.dim}(←/→ hue, ↑/↓ brightness, S saturation)${theme.reset}');

        ctx.writeConnector();

        final caretColumn = selX * 2;
        final caretPad = ' ' * caretColumn;
        ctx.gutterLine('$caretPad${theme.selection}^^${theme.reset}');

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

        final presetsLine = StringBuffer();
        presetsLine.write(ctx.lb.gutter());
        for (int i = 0; i < presets.length; i++) {
          final hex = presets[i];
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

        final hex = selectedHex();
        final rgb = _hexToRgb(hex);
        final swatch = '${_bg(rgb[0], rgb[1], rgb[2])}      ${theme.reset}';
        ctx.gutterLine('$swatch ${theme.accent}$hex${theme.reset}');

        if (hexMode) {
          ctx.writeConnector();
          final typed = hexInput.text.trim();
          final valid = _isValidHex(typed);
          final cursor = hexInput.textWithCursor();

          final statusColor = valid ? theme.accent : theme.dim;
          final preview = valid
              ? () {
                  final pRgb = _hexToRgb(typed);
                  return ' ${_bg(pRgb[0], pRgb[1], pRgb[2])}    ${theme.reset}';
                }()
              : '';

          ctx.gutterLine(
              '${theme.accent}Hex${theme.reset} $statusColor$cursor${theme.reset}$preview');
          ctx.gutterLine(
              '${theme.dim}Enter to apply · Esc to discard${theme.reset}');
        }
      });

      // Manually render hints to avoid terminal wrapping issues
      if (theme.features.hintStyle == HintStyle.bullets) {
        final entries = bindings.toHintEntries();
        for (var i = 0; i < entries.length; i += 4) {
          final chunk = entries.sublist(i, math.min(i + 4, entries.length));
          final segments =
              chunk.map((e) => HintFormat.hint(e[0], e[1], theme)).toList();
          out.writeln(HintFormat.bullets(segments, theme));
        }
      } else {
        switch (theme.features.hintStyle) {
          case HintStyle.grid:
            out.writeln(bindings.toHintsGrid(theme));
            break;
          case HintStyle.inline:
            final entries = bindings.toHintEntries();
            final hints = entries.map((e) => '${e[0]}: ${e[1]}').toList();
            out.writeln(HintFormat.comma(hints, theme));
            break;
          case HintStyle.bullets:
          case HintStyle.none:
            break;
        }
      }
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

bool _isValidHex(String s) => RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(s.trim());

List<int> _hexToRgb(String hex) {
  final h = hex.startsWith('#') ? hex.substring(1) : hex;
  final r = int.parse(h.substring(0, 2), radix: 16);
  final g = int.parse(h.substring(2, 4), radix: 16);
  final b = int.parse(h.substring(4, 6), radix: 16);
  return [r, g, b];
}

String _rgbToHex(int r, int g, int b) {
  String two(int v) => v.toRadixString(16).padLeft(2, '0');
  return '#${two(r)}${two(g)}${two(b)}'.toUpperCase();
}

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

String _bg(int r, int g, int b) => '\x1B[48;2;$r;$g;${b}m';

List<double> _cellToHsv(int x, int y, int cols, int rows, double sat) {
  final hue = (x / (cols)) * 360.0;
  final s = sat.clamp(0.0, 1.0);
  final v = 1.0 - (y / (rows - 1)) * 0.65;
  return [hue, s, v];
}
