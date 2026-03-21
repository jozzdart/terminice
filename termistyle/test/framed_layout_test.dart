import 'package:test/test.dart';
import 'package:termistyle/termistyle.dart';

void main() {
  // Shared constants for readability
  const reset = '\x1B[0m';
  const gray = '\x1B[90m';
  const selection = '\x1B[35m';

  // Default theme (dark) uses unicode glyphs and standard features
  const dark = PromptTheme.dark;
  // Minimal theme disables borders
  const minimal = PromptTheme.minimal;

  // ══════════════════════════════════════════════════════════════════════════
  // Constructor & properties
  // ══════════════════════════════════════════════════════════════════════════

  group('constructor', () {
    test('stores title', () {
      final frame = FramedLayout('Hello');
      expect(frame.title, equals('Hello'));
    });

    test('defaults to dark theme', () {
      final frame = FramedLayout('Test');
      expect(frame.theme.colors.accent, equals(dark.colors.accent));
      expect(frame.theme.glyphs.borderTop, equals('┌'));
      expect(frame.theme.features.showBorders, isTrue);
    });

    test('accepts custom theme', () {
      final frame = FramedLayout('Test', theme: PromptTheme.matrix);
      expect(frame.theme.colors.accent, equals(TerminalColors.matrix.accent));
      expect(frame.theme.glyphs.borderTop, equals('╭'));
    });

    test('glyphs getter delegates to theme', () {
      final frame = FramedLayout('T', theme: PromptTheme.fire);
      expect(frame.glyphs, same(PromptTheme.fire.glyphs));
    });

    test('features getter delegates to theme', () {
      final frame = FramedLayout('T', theme: minimal);
      expect(frame.features, same(minimal.features));
      expect(frame.features.showBorders, isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // top()
  // ══════════════════════════════════════════════════════════════════════════

  group('top()', () {
    test('returns bordered title when showBorders is true', () {
      final frame = FramedLayout('Deploy', theme: dark);
      final result = frame.top();

      final stripped = stripAnsi(result);
      expect(stripped, contains('Deploy'));
      expect(stripped, startsWith('┌'));
      expect(stripped, endsWith('┐'));
      expect(stripped, contains('─'));
    });

    test('bordered title has selection color wrapping', () {
      final frame = FramedLayout('Deploy', theme: dark);
      final result = frame.top();

      expect(result, startsWith(selection));
      expect(result, endsWith(reset));
    });

    test(
        'bordered title structure is corner-dash-space-title-space-dash-corner',
        () {
      final frame = FramedLayout('X', theme: dark);
      final stripped = stripAnsi(frame.top());
      expect(stripped, equals('┌─ X ─┐'));
    });

    test('returns plain title when showBorders is false', () {
      final frame = FramedLayout('Deploy', theme: minimal);
      final result = frame.top();

      final stripped = stripAnsi(result);
      expect(stripped, equals('Deploy'));
      expect(stripped, isNot(contains('┌')));
      expect(stripped, isNot(contains('─')));
    });

    test('plain title has selection color wrapping', () {
      final frame = FramedLayout('Deploy', theme: minimal);
      final result = frame.top();

      expect(result, equals('${selection}Deploy$reset'));
    });

    test('works with rounded glyphs', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.rounded);
      final frame = FramedLayout('Test', theme: theme);
      final stripped = stripAnsi(frame.top());

      expect(stripped, startsWith('╭'));
      expect(stripped, endsWith('╮'));
    });

    test('works with ascii glyphs', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.ascii);
      final frame = FramedLayout('Test', theme: theme);
      final stripped = stripAnsi(frame.top());

      expect(stripped, startsWith('+'));
      expect(stripped, endsWith('+'));
      expect(stripped, contains('-'));
    });

    test('works with double glyphs', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.double);
      final frame = FramedLayout('Test', theme: theme);
      final stripped = stripAnsi(frame.top());

      expect(stripped, startsWith('╔'));
      expect(stripped, endsWith('╗'));
      expect(stripped, contains('═'));
    });

    test('works with heavy glyphs', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.heavy);
      final frame = FramedLayout('Test', theme: theme);
      final stripped = stripAnsi(frame.top());

      expect(stripped, startsWith('┏'));
      expect(stripped, endsWith('┓'));
      expect(stripped, contains('━'));
    });

    test('works with arcane glyphs', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.arcane);
      final frame = FramedLayout('Test', theme: theme);
      final stripped = stripAnsi(frame.top());

      expect(stripped, startsWith('⸢'));
      expect(stripped, endsWith('⸣'));
    });

    test('works with phantom glyphs', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.phantom);
      final frame = FramedLayout('Test', theme: theme);
      final stripped = stripAnsi(frame.top());

      expect(stripped, startsWith('⌜'));
      expect(stripped, endsWith('⌝'));
    });

    test('handles empty title', () {
      final frame = FramedLayout('', theme: dark);
      final stripped = stripAnsi(frame.top());
      expect(stripped, equals('┌─  ─┐'));
    });

    test('handles long title', () {
      final title = 'A' * 100;
      final frame = FramedLayout(title, theme: dark);
      final stripped = stripAnsi(frame.top());
      expect(stripped, contains(title));
      expect(stripped, startsWith('┌'));
      expect(stripped, endsWith('┐'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // connector()
  // ══════════════════════════════════════════════════════════════════════════

  group('connector()', () {
    test('starts with connector glyph', () {
      final frame = FramedLayout('Title', theme: dark);
      final stripped = stripAnsi(frame.connector());
      expect(stripped[0], equals('├'));
    });

    test('uses horizontal dashes after connector', () {
      final frame = FramedLayout('Title', theme: dark);
      final stripped = stripAnsi(frame.connector());
      expect(stripped.substring(1), matches(RegExp(r'^─+$')));
    });

    test('connector width is title.length + 6', () {
      const title = 'Hello';
      final frame = FramedLayout(title, theme: dark);
      final stripped = stripAnsi(frame.connector());
      // connector char (1) + dashes (title.length + 6)
      expect(stripped.length, equals(1 + title.length + 6));
    });

    test('has gray color wrapping', () {
      final frame = FramedLayout('T', theme: dark);
      final result = frame.connector();
      expect(result, startsWith(gray));
      expect(result, endsWith(reset));
    });

    test('uses correct glyphs for ascii', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.ascii);
      final frame = FramedLayout('X', theme: theme);
      final stripped = stripAnsi(frame.connector());
      expect(stripped[0], equals('+'));
      expect(stripped.substring(1), matches(RegExp(r'^-+$')));
    });

    test('handles empty title', () {
      final frame = FramedLayout('', theme: dark);
      final stripped = stripAnsi(frame.connector());
      expect(stripped[0], equals('├'));
      expect(stripped.length, equals(1 + 6));
    });

    test('scales with longer titles', () {
      final short = FramedLayout('AB', theme: dark);
      final long = FramedLayout('ABCDEFGH', theme: dark);
      final shortLen = stripAnsi(short.connector()).length;
      final longLen = stripAnsi(long.connector()).length;
      expect(longLen - shortLen, equals(6));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // bottom()
  // ══════════════════════════════════════════════════════════════════════════

  group('bottom()', () {
    test('starts with bottom corner glyph', () {
      final frame = FramedLayout('Title', theme: dark);
      final stripped = stripAnsi(frame.bottom());
      expect(stripped[0], equals('└'));
    });

    test('uses horizontal dashes after corner', () {
      final frame = FramedLayout('Title', theme: dark);
      final stripped = stripAnsi(frame.bottom());
      expect(stripped.substring(1), matches(RegExp(r'^─+$')));
    });

    test(
        'bottom width is title.length + 5 dashes + 1 corner = title.length + 6',
        () {
      const title = 'Hello';
      final frame = FramedLayout(title, theme: dark);
      final stripped = stripAnsi(frame.bottom());
      expect(stripped.length, equals(1 + title.length + 5));
    });

    test('has gray color wrapping', () {
      final frame = FramedLayout('T', theme: dark);
      final result = frame.bottom();
      expect(result, startsWith(gray));
      expect(result, endsWith(reset));
    });

    test('uses correct glyphs for ascii', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.ascii);
      final frame = FramedLayout('X', theme: theme);
      final stripped = stripAnsi(frame.bottom());
      expect(stripped[0], equals('+'));
      expect(stripped.substring(1), matches(RegExp(r'^-+$')));
    });

    test('uses correct glyphs for rounded', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.rounded);
      final frame = FramedLayout('X', theme: theme);
      final stripped = stripAnsi(frame.bottom());
      expect(stripped[0], equals('╰'));
    });

    test('handles empty title', () {
      final frame = FramedLayout('', theme: dark);
      final stripped = stripAnsi(frame.bottom());
      expect(stripped[0], equals('└'));
      expect(stripped.length, equals(1 + 5));
    });

    test('scales with longer titles', () {
      final short = FramedLayout('AB', theme: dark);
      final long = FramedLayout('ABCDEFGH', theme: dark);
      final shortLen = stripAnsi(short.bottom()).length;
      final longLen = stripAnsi(long.bottom()).length;
      expect(longLen - shortLen, equals(6));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // gutter()
  // ══════════════════════════════════════════════════════════════════════════

  group('gutter()', () {
    test('returns vertical bar with trailing space when borders enabled', () {
      final frame = FramedLayout('T', theme: dark);
      final result = frame.gutter();
      final stripped = stripAnsi(result);
      expect(stripped, equals('│ '));
    });

    test('gutter has gray color on the vertical bar', () {
      final frame = FramedLayout('T', theme: dark);
      final result = frame.gutter();
      expect(result, startsWith(gray));
      expect(result, contains(reset));
    });

    test('returns empty string when borders disabled', () {
      final frame = FramedLayout('T', theme: minimal);
      expect(frame.gutter(), equals(''));
    });

    test('uses correct glyph for ascii', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.ascii);
      final frame = FramedLayout('T', theme: theme);
      final stripped = stripAnsi(frame.gutter());
      expect(stripped, equals('| '));
    });

    test('uses correct glyph for heavy', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.heavy);
      final frame = FramedLayout('T', theme: theme);
      final stripped = stripAnsi(frame.gutter());
      expect(stripped, equals('┃ '));
    });

    test('uses correct glyph for dotted', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.dotted);
      final frame = FramedLayout('T', theme: theme);
      final stripped = stripAnsi(frame.gutter());
      expect(stripped, equals('┊ '));
    });

    test('uses correct glyph for phantom', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.phantom);
      final frame = FramedLayout('T', theme: theme);
      final stripped = stripAnsi(frame.gutter());
      expect(stripped, equals('¦ '));
    });

    test('uses correct glyph for double', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.double);
      final frame = FramedLayout('T', theme: theme);
      final stripped = stripAnsi(frame.gutter());
      expect(stripped, equals('║ '));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // gutterOnly()
  // ══════════════════════════════════════════════════════════════════════════

  group('gutterOnly()', () {
    test('returns vertical bar without trailing space when borders enabled',
        () {
      final frame = FramedLayout('T', theme: dark);
      final result = frame.gutterOnly();
      final stripped = stripAnsi(result);
      expect(stripped, equals('│'));
    });

    test('gutterOnly has gray color on the vertical bar', () {
      final frame = FramedLayout('T', theme: dark);
      final result = frame.gutterOnly();
      expect(result, startsWith(gray));
      expect(result, endsWith(reset));
    });

    test('returns empty string when borders disabled', () {
      final frame = FramedLayout('T', theme: minimal);
      expect(frame.gutterOnly(), equals(''));
    });

    test('uses correct glyph for ascii', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.ascii);
      final frame = FramedLayout('T', theme: theme);
      expect(stripAnsi(frame.gutterOnly()), equals('|'));
    });

    test('is gutter minus the trailing space', () {
      final frame = FramedLayout('T', theme: dark);
      final gutterStripped = stripAnsi(frame.gutter());
      final gutterOnlyStripped = stripAnsi(frame.gutterOnly());
      expect(gutterStripped, equals('$gutterOnlyStripped '));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Theme presets produce coherent frames
  // ══════════════════════════════════════════════════════════════════════════

  group('theme presets', () {
    const title = 'Status';
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
    };

    for (final entry in themes.entries) {
      group(entry.key, () {
        test('top() contains title text', () {
          final frame = FramedLayout(title, theme: entry.value);
          expect(stripAnsi(frame.top()), contains(title));
        });

        test('top() contains ANSI codes (is styled)', () {
          final frame = FramedLayout(title, theme: entry.value);
          expect(frame.top(), isNot(equals(stripAnsi(frame.top()))));
        });

        test('connector() is non-empty', () {
          final frame = FramedLayout(title, theme: entry.value);
          expect(stripAnsi(frame.connector()), isNotEmpty);
        });

        test('bottom() is non-empty', () {
          final frame = FramedLayout(title, theme: entry.value);
          expect(stripAnsi(frame.bottom()), isNotEmpty);
        });

        test('gutter() is non-empty (all presets above have borders)', () {
          final frame = FramedLayout(title, theme: entry.value);
          expect(frame.gutter(), isNotEmpty);
        });
      });
    }

    group('minimal', () {
      test('top() is plain title without border chars', () {
        final frame = FramedLayout(title, theme: PromptTheme.minimal);
        final stripped = stripAnsi(frame.top());
        expect(stripped, equals(title));
      });

      test('gutter() is empty', () {
        final frame = FramedLayout(title, theme: PromptTheme.minimal);
        expect(frame.gutter(), isEmpty);
      });

      test('gutterOnly() is empty', () {
        final frame = FramedLayout(title, theme: PromptTheme.minimal);
        expect(frame.gutterOnly(), isEmpty);
      });
    });

    group('compact', () {
      test('has borders (compact only disables hints)', () {
        final frame = FramedLayout(title, theme: PromptTheme.compact);
        expect(frame.features.showBorders, isTrue);
        expect(stripAnsi(frame.gutter()), equals('│ '));
      });
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Consistency between top/connector/bottom widths
  // ══════════════════════════════════════════════════════════════════════════

  group('width consistency', () {
    for (final title in ['X', 'Hello', 'A longer title here', '']) {
      test('top/bottom use consistent sizing for "$title"', () {
        final frame = FramedLayout(title, theme: dark);
        final topStripped = stripAnsi(frame.top());
        final bottomStripped = stripAnsi(frame.bottom());
        final connectorStripped = stripAnsi(frame.connector());

        // Top: corner + dash + space + title + space + dash + corner
        //    = title.length + 6
        expect(topStripped.length, equals(title.length + 6));

        // Bottom: corner + (title.length + 5) dashes
        expect(bottomStripped.length, equals(title.length + 6));

        // Connector: connector + (title.length + 6) dashes
        expect(connectorStripped.length, equals(title.length + 7));
      });
    }
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Full frame assembly integration
  // ══════════════════════════════════════════════════════════════════════════

  group('full frame assembly', () {
    test('produces a visually coherent bordered frame', () {
      final frame = FramedLayout('Deploy', theme: dark);

      final lines = [
        stripAnsi(frame.top()),
        '${stripAnsi(frame.gutter())}Uploading assets...',
        '${stripAnsi(frame.gutter())}Running tests...',
        stripAnsi(frame.bottom()),
      ];

      expect(lines[0], equals('┌─ Deploy ─┐'));
      expect(lines[1], equals('│ Uploading assets...'));
      expect(lines[2], equals('│ Running tests...'));
      expect(lines[3], equals('└───────────'));
    });

    test('produces a plain frame when borders disabled', () {
      final frame = FramedLayout('Deploy', theme: minimal);

      final lines = [
        stripAnsi(frame.top()),
        '${stripAnsi(frame.gutter())}Uploading assets...',
        stripAnsi(frame.bottom()),
      ];

      expect(lines[0], equals('Deploy'));
      expect(lines[1], equals('Uploading assets...'));
    });

    test('produces a coherent ascii frame', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.ascii);
      final frame = FramedLayout('Log', theme: theme);

      final top = stripAnsi(frame.top());
      final gut = stripAnsi(frame.gutter());
      final bot = stripAnsi(frame.bottom());

      expect(top, equals('+- Log -+'));
      expect(gut, equals('| '));
      expect(bot, equals('+--------'));
    });

    test('produces a coherent rounded frame', () {
      final theme = PromptTheme(glyphs: TerminalGlyphs.rounded);
      final frame = FramedLayout('OK', theme: theme);

      final top = stripAnsi(frame.top());
      final bot = stripAnsi(frame.bottom());

      expect(top, equals('╭─ OK ─╮'));
      expect(bot, startsWith('╰'));
    });

    test('all output lines contain ANSI codes', () {
      final frame = FramedLayout('Test', theme: dark);
      expect(frame.top(), isNot(equals(stripAnsi(frame.top()))));
      expect(frame.connector(), isNot(equals(stripAnsi(frame.connector()))));
      expect(frame.bottom(), isNot(equals(stripAnsi(frame.bottom()))));
      expect(frame.gutter(), isNot(equals(stripAnsi(frame.gutter()))));
      expect(frame.gutterOnly(), isNot(equals(stripAnsi(frame.gutterOnly()))));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Custom theme composition
  // ══════════════════════════════════════════════════════════════════════════

  group('custom theme composition', () {
    test('custom glyphs appear in output', () {
      final theme = PromptTheme(
        glyphs: TerminalGlyphs(
          borderTop: '╔',
          borderBottom: '╚',
          borderVertical: '║',
          borderConnector: '╟',
          borderHorizontal: '═',
        ),
      );
      final frame = FramedLayout('Title', theme: theme);

      expect(stripAnsi(frame.top()), startsWith('╔'));
      expect(stripAnsi(frame.top()), endsWith('╗'));
      expect(stripAnsi(frame.top()), contains('═'));
      expect(stripAnsi(frame.connector())[0], equals('╟'));
      expect(stripAnsi(frame.bottom())[0], equals('╚'));
      expect(stripAnsi(frame.gutter()), startsWith('║'));
    });

    test('disabling borders via custom features', () {
      final theme = PromptTheme(
        features: DisplayFeatures(showBorders: false),
      );
      final frame = FramedLayout('Title', theme: theme);

      expect(stripAnsi(frame.top()), equals('Title'));
      expect(frame.gutter(), equals(''));
      expect(frame.gutterOnly(), equals(''));
    });

    test('custom color palette is used in output', () {
      final customAccent = '\x1B[95m';
      final theme = PromptTheme(
        colors: TerminalColors(selection: customAccent),
      );
      final frame = FramedLayout('Title', theme: theme);

      expect(frame.top(), startsWith(customAccent));
    });
  });
}
