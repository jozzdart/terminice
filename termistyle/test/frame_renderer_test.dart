import 'package:test/test.dart';
import 'package:termistyle/termistyle.dart';

/// ANSI code constants for the default dark theme.
const _reset = '\x1B[0m';
const _selection = '\x1B[35m';
const _gray = '\x1B[90m';

/// Default unicode glyphs.
const _top = '┌';
const _bottom = '└';
const _vertical = '│';
const _connector = '├';
const _horizontal = '─';

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // FrameRenderer
  // ══════════════════════════════════════════════════════════════════════════

  group('FrameRenderer', () {
    // ────────────────────────────────────────────────────────────────────────
    // titleWithBorders
    // ────────────────────────────────────────────────────────────────────────

    group('titleWithBorders', () {
      test('produces balanced top-left and top-right corners', () {
        final result = FrameRenderer.titleWithBorders('Test', PromptTheme.dark);
        final stripped = stripAnsi(result);
        expect(stripped, startsWith(_top));
        expect(stripped, endsWith('┐'));
      });

      test('contains the title text between borders', () {
        final result =
            FrameRenderer.titleWithBorders('Hello', PromptTheme.dark);
        final stripped = stripAnsi(result);
        expect(stripped, contains('Hello'));
      });

      test('wraps title with horizontal dashes and spaces', () {
        final result = FrameRenderer.titleWithBorders('X', PromptTheme.dark);
        final stripped = stripAnsi(result);
        // Format: ┌─ X ─┐
        expect(stripped, equals('$_top$_horizontal X $_horizontal┐'));
      });

      test('uses selection color from theme', () {
        final result = FrameRenderer.titleWithBorders('T', PromptTheme.dark);
        expect(result, startsWith(_selection));
        expect(result, endsWith(_reset));
      });

      test('uses rounded glyphs when theme has rounded preset', () {
        final theme = PromptTheme(glyphs: TerminalGlyphs.rounded);
        final result = FrameRenderer.titleWithBorders('Hi', theme);
        final stripped = stripAnsi(result);
        expect(stripped, startsWith('╭'));
        expect(stripped, endsWith('╮'));
      });

      test('uses double glyphs when theme has double preset', () {
        final theme = PromptTheme(glyphs: TerminalGlyphs.double);
        final result = FrameRenderer.titleWithBorders('Hi', theme);
        final stripped = stripAnsi(result);
        expect(stripped, startsWith('╔'));
        expect(stripped, endsWith('╗'));
      });

      test('uses heavy glyphs when theme has heavy preset', () {
        final theme = PromptTheme(glyphs: TerminalGlyphs.heavy);
        final result = FrameRenderer.titleWithBorders('Hi', theme);
        final stripped = stripAnsi(result);
        expect(stripped, startsWith('┏'));
        expect(stripped, endsWith('┓'));
      });

      test('uses ASCII glyphs when theme has ascii preset', () {
        final theme = PromptTheme(glyphs: TerminalGlyphs.ascii);
        final result = FrameRenderer.titleWithBorders('Hi', theme);
        final stripped = stripAnsi(result);
        expect(stripped, startsWith('+'));
        expect(stripped, endsWith('+'));
        expect(stripped, contains('-'));
      });

      test('uses arcane glyphs', () {
        final theme = PromptTheme(glyphs: TerminalGlyphs.arcane);
        final result = FrameRenderer.titleWithBorders('Hi', theme);
        final stripped = stripAnsi(result);
        expect(stripped, startsWith('⸢'));
        expect(stripped, endsWith('⸣'));
      });

      test('uses phantom glyphs', () {
        final theme = PromptTheme(glyphs: TerminalGlyphs.phantom);
        final result = FrameRenderer.titleWithBorders('Hi', theme);
        final stripped = stripAnsi(result);
        expect(stripped, startsWith('⌜'));
        expect(stripped, endsWith('⌝'));
      });

      test('handles empty title', () {
        final result = FrameRenderer.titleWithBorders('', PromptTheme.dark);
        final stripped = stripAnsi(result);
        expect(stripped, equals('$_top$_horizontal  $_horizontal┐'));
      });

      test('handles long title', () {
        final title = 'A' * 50;
        final result = FrameRenderer.titleWithBorders(title, PromptTheme.dark);
        final stripped = stripAnsi(result);
        expect(stripped, contains(title));
        expect(stripped, startsWith(_top));
        expect(stripped, endsWith('┐'));
      });

      test('uses colors from custom theme', () {
        final theme = PromptTheme(colors: TerminalColors.matrix);
        final result = FrameRenderer.titleWithBorders('Go', theme);
        expect(result, startsWith(theme.selection));
        expect(result, endsWith(theme.reset));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // titleWithBordersColored
    // ────────────────────────────────────────────────────────────────────────

    group('titleWithBordersColored', () {
      test('uses the provided custom color instead of theme selection', () {
        const custom = '\x1B[94m';
        final result = FrameRenderer.titleWithBordersColored(
            'Test', PromptTheme.dark, custom);
        expect(result, startsWith(custom));
        expect(result, endsWith(_reset));
      });

      test('still uses theme glyphs', () {
        const custom = '\x1B[94m';
        final theme = PromptTheme(glyphs: TerminalGlyphs.rounded);
        final result =
            FrameRenderer.titleWithBordersColored('Hi', theme, custom);
        final stripped = stripAnsi(result);
        expect(stripped, startsWith('╭'));
        expect(stripped, endsWith('╮'));
      });

      test('contains the title text', () {
        const custom = '\x1B[91m';
        final result = FrameRenderer.titleWithBordersColored(
            'Deploy', PromptTheme.dark, custom);
        expect(stripAnsi(result), contains('Deploy'));
      });

      test('produces same structure as titleWithBorders', () {
        final bordered =
            FrameRenderer.titleWithBorders('Same', PromptTheme.dark);
        final colored = FrameRenderer.titleWithBordersColored(
            'Same', PromptTheme.dark, _selection);
        expect(stripAnsi(colored), equals(stripAnsi(bordered)));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // plainTitle
    // ────────────────────────────────────────────────────────────────────────

    group('plainTitle', () {
      test('wraps title with selection color and reset', () {
        final result = FrameRenderer.plainTitle('Title', PromptTheme.dark);
        expect(result, equals('${_selection}Title$_reset'));
      });

      test('stripped output is just the title', () {
        final result = FrameRenderer.plainTitle('Hello', PromptTheme.dark);
        expect(stripAnsi(result), equals('Hello'));
      });

      test('handles empty title', () {
        final result = FrameRenderer.plainTitle('', PromptTheme.dark);
        expect(stripAnsi(result), equals(''));
      });

      test('uses theme-specific selection color', () {
        final theme = PromptTheme(colors: TerminalColors.ocean);
        final result = FrameRenderer.plainTitle('Nav', theme);
        expect(result, startsWith(theme.selection));
        expect(result, endsWith(theme.reset));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // plainTitleColored
    // ────────────────────────────────────────────────────────────────────────

    group('plainTitleColored', () {
      test('uses the provided custom color', () {
        const custom = '\x1B[93m';
        final result =
            FrameRenderer.plainTitleColored('Warn', PromptTheme.dark, custom);
        expect(result, equals('${custom}Warn$_reset'));
      });

      test('stripped output matches plainTitle', () {
        final plain = FrameRenderer.plainTitle('Same', PromptTheme.dark);
        final colored = FrameRenderer.plainTitleColored(
            'Same', PromptTheme.dark, '\x1B[91m');
        expect(stripAnsi(colored), equals(stripAnsi(plain)));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // connectorLine
    // ────────────────────────────────────────────────────────────────────────

    group('connectorLine', () {
      test('starts with connector glyph in gray', () {
        final result = FrameRenderer.connectorLine('Test', PromptTheme.dark);
        final stripped = stripAnsi(result);
        expect(stripped, startsWith(_connector));
      });

      test('fills with horizontal dashes', () {
        final result = FrameRenderer.connectorLine('Test', PromptTheme.dark);
        final stripped = stripAnsi(result);
        final dashes = stripped.substring(1);
        expect(dashes, equals(_horizontal * ('Test'.length + 6)));
      });

      test('dash count equals title.length + 6', () {
        const title = 'Hello';
        final result = FrameRenderer.connectorLine(title, PromptTheme.dark);
        final stripped = stripAnsi(result);
        // connector char + dashes
        expect(stripped.length, equals(1 + title.length + 6));
      });

      test('uses gray color from theme', () {
        final result = FrameRenderer.connectorLine('X', PromptTheme.dark);
        expect(result, startsWith(_gray));
        expect(result, endsWith(_reset));
      });

      test('uses theme-specific connector glyph', () {
        final theme = PromptTheme(glyphs: TerminalGlyphs.ascii);
        final result = FrameRenderer.connectorLine('Hi', theme);
        final stripped = stripAnsi(result);
        expect(stripped, startsWith('+'));
        expect(stripped.substring(1), contains('-'));
      });

      test('handles empty title', () {
        final result = FrameRenderer.connectorLine('', PromptTheme.dark);
        final stripped = stripAnsi(result);
        expect(stripped, startsWith(_connector));
        expect(stripped.length, equals(1 + 6));
      });

      test('scales with long titles', () {
        final title = 'A' * 100;
        final result = FrameRenderer.connectorLine(title, PromptTheme.dark);
        final stripped = stripAnsi(result);
        expect(stripped.length, equals(1 + title.length + 6));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // bottomLine
    // ────────────────────────────────────────────────────────────────────────

    group('bottomLine', () {
      test('starts with bottom corner glyph', () {
        final result = FrameRenderer.bottomLine('Test', PromptTheme.dark);
        final stripped = stripAnsi(result);
        expect(stripped, startsWith(_bottom));
      });

      test('fills with horizontal dashes', () {
        final result = FrameRenderer.bottomLine('Test', PromptTheme.dark);
        final stripped = stripAnsi(result);
        final dashes = stripped.substring(1);
        expect(dashes, equals(_horizontal * ('Test'.length + 5)));
      });

      test('dash count equals title.length + 5', () {
        const title = 'Hello';
        final result = FrameRenderer.bottomLine(title, PromptTheme.dark);
        final stripped = stripAnsi(result);
        expect(stripped.length, equals(1 + title.length + 5));
      });

      test('uses gray color from theme', () {
        final result = FrameRenderer.bottomLine('X', PromptTheme.dark);
        expect(result, startsWith(_gray));
        expect(result, endsWith(_reset));
      });

      test('uses theme-specific bottom glyph', () {
        final theme = PromptTheme(glyphs: TerminalGlyphs.rounded);
        final result = FrameRenderer.bottomLine('Hi', theme);
        final stripped = stripAnsi(result);
        expect(stripped, startsWith('╰'));
      });

      test('handles empty title', () {
        final result = FrameRenderer.bottomLine('', PromptTheme.dark);
        final stripped = stripAnsi(result);
        expect(stripped, startsWith(_bottom));
        expect(stripped.length, equals(1 + 5));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // bottomLineColored
    // ────────────────────────────────────────────────────────────────────────

    group('bottomLineColored', () {
      test('uses the provided custom color', () {
        const custom = '\x1B[94m';
        final result =
            FrameRenderer.bottomLineColored('Test', PromptTheme.dark, custom);
        expect(result, startsWith(custom));
        expect(result, endsWith(_reset));
      });

      test('produces same structure as bottomLine', () {
        final plain = FrameRenderer.bottomLine('Same', PromptTheme.dark);
        final colored =
            FrameRenderer.bottomLineColored('Same', PromptTheme.dark, _gray);
        expect(stripAnsi(colored), equals(stripAnsi(plain)));
      });

      test('uses theme glyphs regardless of custom color', () {
        const custom = '\x1B[91m';
        final theme = PromptTheme(glyphs: TerminalGlyphs.double);
        final result = FrameRenderer.bottomLineColored('Hi', theme, custom);
        final stripped = stripAnsi(result);
        expect(stripped, startsWith('╚'));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // Width consistency between top, connector, and bottom
    // ────────────────────────────────────────────────────────────────────────

    group('width consistency', () {
      test('top and bottom have the same visible width', () {
        const title = 'Deploy';
        final top = FrameRenderer.titleWithBorders(title, PromptTheme.dark);
        final bot = FrameRenderer.bottomLine(title, PromptTheme.dark);
        expect(visibleLength(top), equals(visibleLength(bot)));
      });

      test('connector extends 1 char beyond top line', () {
        const title = 'Deploy';
        final topW = visibleLength(
            FrameRenderer.titleWithBorders(title, PromptTheme.dark));
        final connW =
            visibleLength(FrameRenderer.connectorLine(title, PromptTheme.dark));
        expect(connW, equals(topW + 1));
      });

      test('top equals title.length + 6 visible chars', () {
        const title = 'ABCDE';
        final topW = visibleLength(
            FrameRenderer.titleWithBorders(title, PromptTheme.dark));
        expect(topW, equals(title.length + 6));
      });

      test('connector equals title.length + 7 visible chars', () {
        const title = 'ABCDE';
        final connW =
            visibleLength(FrameRenderer.connectorLine(title, PromptTheme.dark));
        expect(connW, equals(title.length + 7));
      });

      test('bottom equals title.length + 6 visible chars', () {
        const title = 'ABCDE';
        final botW =
            visibleLength(FrameRenderer.bottomLine(title, PromptTheme.dark));
        expect(botW, equals(title.length + 6));
      });

      test('top and bottom widths match across all glyph presets', () {
        final presets = [
          TerminalGlyphs.unicode,
          TerminalGlyphs.ascii,
          TerminalGlyphs.rounded,
          TerminalGlyphs.double,
          TerminalGlyphs.heavy,
          TerminalGlyphs.dotted,
        ];
        const title = 'Consistency';
        for (final glyphs in presets) {
          final theme = PromptTheme(glyphs: glyphs);
          final topW =
              visibleLength(FrameRenderer.titleWithBorders(title, theme));
          final botW = visibleLength(FrameRenderer.bottomLine(title, theme));
          final connW =
              visibleLength(FrameRenderer.connectorLine(title, theme));
          expect(topW, equals(botW), reason: 'top/bottom mismatch');
          expect(connW, equals(topW + 1),
              reason: 'connector should be top + 1');
        }
      });

      test('colored variants match non-colored widths', () {
        const title = 'Width';
        const custom = '\x1B[94m';
        final topPlain =
            FrameRenderer.titleWithBorders(title, PromptTheme.dark);
        final topColored = FrameRenderer.titleWithBordersColored(
            title, PromptTheme.dark, custom);
        expect(visibleLength(topColored), equals(visibleLength(topPlain)));

        final botPlain = FrameRenderer.bottomLine(title, PromptTheme.dark);
        final botColored =
            FrameRenderer.bottomLineColored(title, PromptTheme.dark, custom);
        expect(visibleLength(botColored), equals(visibleLength(botPlain)));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // All built-in themes produce valid output
    // ────────────────────────────────────────────────────────────────────────

    group('all built-in themes', () {
      final themes = {
        'dark': PromptTheme.dark,
        'matrix': PromptTheme.matrix,
        'fire': PromptTheme.fire,
        'pastel': PromptTheme.pastel,
        'ocean': PromptTheme.ocean,
        'monochrome': PromptTheme.monochrome,
        'neon': PromptTheme.neon,
        'arcane': PromptTheme.arcane,
        'phantom': PromptTheme.phantom,
        'minimal': PromptTheme.minimal,
        'compact': PromptTheme.compact,
      };

      for (final entry in themes.entries) {
        test('${entry.key} theme produces non-empty output', () {
          final t = entry.value;
          expect(
            FrameRenderer.titleWithBorders('X', t).isNotEmpty,
            isTrue,
          );
          expect(
            FrameRenderer.connectorLine('X', t).isNotEmpty,
            isTrue,
          );
          expect(
            FrameRenderer.bottomLine('X', t).isNotEmpty,
            isTrue,
          );
          expect(
            FrameRenderer.plainTitle('X', t).isNotEmpty,
            isTrue,
          );
        });
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // FramedLayout
  // ══════════════════════════════════════════════════════════════════════════

  group('FramedLayout', () {
    // ────────────────────────────────────────────────────────────────────────
    // Constructor & properties
    // ────────────────────────────────────────────────────────────────────────

    group('constructor', () {
      test('stores title and defaults to dark theme', () {
        final layout = FramedLayout('Hello');
        expect(layout.title, equals('Hello'));
        expect(layout.theme.colors.reset, equals(PromptTheme.dark.reset));
      });

      test('accepts a custom theme', () {
        final layout = FramedLayout('Test', theme: PromptTheme.matrix);
        expect(
            layout.theme.colors.accent, equals(TerminalColors.matrix.accent));
      });

      test('exposes glyphs shorthand', () {
        final layout = FramedLayout('T');
        expect(layout.glyphs, same(layout.theme.glyphs));
      });

      test('exposes features shorthand', () {
        final layout = FramedLayout('T');
        expect(layout.features, same(layout.theme.features));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // top()
    // ────────────────────────────────────────────────────────────────────────

    group('top', () {
      test('returns bordered title when showBorders is true', () {
        final layout = FramedLayout('Title');
        final result = layout.top();
        final stripped = stripAnsi(result);
        expect(stripped, startsWith(_top));
        expect(stripped, endsWith('┐'));
        expect(stripped, contains('Title'));
      });

      test('returns plain title when showBorders is false', () {
        final layout = FramedLayout('Title',
            theme: PromptTheme(features: DisplayFeatures.minimal));
        final result = layout.top();
        final stripped = stripAnsi(result);
        expect(stripped, equals('Title'));
      });

      test('delegates to FrameRenderer.titleWithBorders', () {
        const title = 'Check';
        final layout = FramedLayout(title);
        final direct = FrameRenderer.titleWithBorders(title, PromptTheme.dark);
        expect(layout.top(), equals(direct));
      });

      test('delegates to FrameRenderer.plainTitle for minimal features', () {
        const title = 'Check';
        final theme = PromptTheme(features: DisplayFeatures.minimal);
        final layout = FramedLayout(title, theme: theme);
        final direct = FrameRenderer.plainTitle(title, theme);
        expect(layout.top(), equals(direct));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // connector()
    // ────────────────────────────────────────────────────────────────────────

    group('connector', () {
      test('delegates to FrameRenderer.connectorLine', () {
        const title = 'Conn';
        final layout = FramedLayout(title);
        final direct = FrameRenderer.connectorLine(title, PromptTheme.dark);
        expect(layout.connector(), equals(direct));
      });

      test('extends 1 char beyond top width', () {
        final layout = FramedLayout('Width');
        expect(
          visibleLength(layout.connector()),
          equals(visibleLength(layout.top()) + 1),
        );
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // bottom()
    // ────────────────────────────────────────────────────────────────────────

    group('bottom', () {
      test('delegates to FrameRenderer.bottomLine', () {
        const title = 'Bot';
        final layout = FramedLayout(title);
        final direct = FrameRenderer.bottomLine(title, PromptTheme.dark);
        expect(layout.bottom(), equals(direct));
      });

      test('matches top width exactly', () {
        final layout = FramedLayout('Width');
        expect(
          visibleLength(layout.bottom()),
          equals(visibleLength(layout.top())),
        );
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // gutter()
    // ────────────────────────────────────────────────────────────────────────

    group('gutter', () {
      test('returns vertical bar plus space when borders enabled', () {
        final layout = FramedLayout('T');
        final result = layout.gutter();
        final stripped = stripAnsi(result);
        expect(stripped, equals('$_vertical '));
      });

      test('returns empty string when borders disabled', () {
        final layout = FramedLayout('T',
            theme: PromptTheme(features: DisplayFeatures.minimal));
        expect(layout.gutter(), equals(''));
      });

      test('uses gray color', () {
        final layout = FramedLayout('T');
        final result = layout.gutter();
        expect(result, contains(_gray));
        expect(result, contains(_reset));
      });

      test('uses theme-specific vertical glyph', () {
        final layout =
            FramedLayout('T', theme: PromptTheme(glyphs: TerminalGlyphs.ascii));
        final stripped = stripAnsi(layout.gutter());
        expect(stripped, equals('| '));
      });

      test('uses double-line vertical for double glyphs', () {
        final layout = FramedLayout('T',
            theme: PromptTheme(glyphs: TerminalGlyphs.double));
        final stripped = stripAnsi(layout.gutter());
        expect(stripped, equals('║ '));
      });

      test('uses heavy vertical for heavy glyphs', () {
        final layout =
            FramedLayout('T', theme: PromptTheme(glyphs: TerminalGlyphs.heavy));
        final stripped = stripAnsi(layout.gutter());
        expect(stripped, equals('┃ '));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // gutterOnly()
    // ────────────────────────────────────────────────────────────────────────

    group('gutterOnly', () {
      test('returns vertical bar without trailing space', () {
        final layout = FramedLayout('T');
        final stripped = stripAnsi(layout.gutterOnly());
        expect(stripped, equals(_vertical));
      });

      test('returns empty string when borders disabled', () {
        final layout = FramedLayout('T',
            theme: PromptTheme(features: DisplayFeatures.minimal));
        expect(layout.gutterOnly(), equals(''));
      });

      test('has visible length of 1 when borders enabled', () {
        final layout = FramedLayout('T');
        expect(visibleLength(layout.gutterOnly()), equals(1));
      });

      test('gutter is gutterOnly plus a space', () {
        final layout = FramedLayout('T');
        final gutterStripped = stripAnsi(layout.gutter());
        final gutterOnlyStripped = stripAnsi(layout.gutterOnly());
        expect(gutterStripped, equals('$gutterOnlyStripped '));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // Full frame assembly
    // ────────────────────────────────────────────────────────────────────────

    group('full frame assembly', () {
      test('produces a complete bordered frame with content', () {
        final frame = FramedLayout('Status');
        final lines = [
          frame.top(),
          '${frame.gutter()}Line 1',
          '${frame.gutter()}Line 2',
          frame.bottom(),
        ];
        expect(lines.length, equals(4));
        expect(stripAnsi(lines[0]), contains('Status'));
        expect(stripAnsi(lines[1]), contains('Line 1'));
        expect(stripAnsi(lines[2]), contains('Line 2'));
        expect(stripAnsi(lines[3]), startsWith(_bottom));
      });

      test('produces borderless frame with minimal features', () {
        final frame = FramedLayout('Status',
            theme: PromptTheme(features: DisplayFeatures.minimal));
        final top = frame.top();
        final gutter = frame.gutter();
        expect(stripAnsi(top), equals('Status'));
        expect(gutter, equals(''));
      });

      test('top and bottom widths match, connector extends by 1', () {
        final frame = FramedLayout('Consistent');
        final topW = visibleLength(frame.top());
        final connW = visibleLength(frame.connector());
        final botW = visibleLength(frame.bottom());
        expect(topW, equals(botW));
        expect(connW, equals(topW + 1));
      });

      test('works with every built-in theme', () {
        final themes = [
          PromptTheme.dark,
          PromptTheme.matrix,
          PromptTheme.fire,
          PromptTheme.pastel,
          PromptTheme.ocean,
          PromptTheme.monochrome,
          PromptTheme.neon,
          PromptTheme.arcane,
          PromptTheme.phantom,
        ];
        for (final t in themes) {
          final frame = FramedLayout('Frame', theme: t);
          expect(frame.top().isNotEmpty, isTrue);
          expect(frame.bottom().isNotEmpty, isTrue);
          expect(frame.gutter().isNotEmpty, isTrue);
          expect(frame.gutterOnly().isNotEmpty, isTrue);
        }
      });
    });
  });
}
