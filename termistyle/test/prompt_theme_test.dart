import 'package:test/test.dart';
import 'package:termistyle/termistyle.dart';

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // Constructor defaults
  // ══════════════════════════════════════════════════════════════════════════

  group('constructor defaults', () {
    test('default constructor uses dark colors', () {
      const theme = PromptTheme();
      expect(identical(theme.colors, TerminalColors.dark), isTrue);
    });

    test('default constructor uses unicode glyphs', () {
      const theme = PromptTheme();
      expect(identical(theme.glyphs, TerminalGlyphs.unicode), isTrue);
    });

    test('default constructor uses standard features', () {
      const theme = PromptTheme();
      expect(identical(theme.features, DisplayFeatures.standard), isTrue);
    });

    test('custom constructor stores provided components', () {
      const theme = PromptTheme(
        colors: TerminalColors.matrix,
        glyphs: TerminalGlyphs.rounded,
        features: DisplayFeatures.minimal,
      );
      expect(identical(theme.colors, TerminalColors.matrix), isTrue);
      expect(identical(theme.glyphs, TerminalGlyphs.rounded), isTrue);
      expect(identical(theme.features, DisplayFeatures.minimal), isTrue);
    });

    test('can be const-constructed', () {
      const a = PromptTheme();
      const b = PromptTheme();
      expect(identical(a, b), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // copyWith
  // ══════════════════════════════════════════════════════════════════════════

  group('copyWith', () {
    test('returns identical theme when no arguments provided', () {
      const original = PromptTheme();
      final copy = original.copyWith();
      expect(copy.colors.accent, equals(original.colors.accent));
      expect(copy.glyphs.arrow, equals(original.glyphs.arrow));
      expect(copy.features.showBorders, equals(original.features.showBorders));
    });

    test('replaces colors only', () {
      final copy = PromptTheme.dark.copyWith(colors: TerminalColors.ocean);
      expect(identical(copy.colors, TerminalColors.ocean), isTrue);
      expect(identical(copy.glyphs, TerminalGlyphs.unicode), isTrue);
      expect(identical(copy.features, DisplayFeatures.standard), isTrue);
    });

    test('replaces glyphs only', () {
      final copy = PromptTheme.dark.copyWith(glyphs: TerminalGlyphs.ascii);
      expect(identical(copy.colors, TerminalColors.dark), isTrue);
      expect(identical(copy.glyphs, TerminalGlyphs.ascii), isTrue);
      expect(identical(copy.features, DisplayFeatures.standard), isTrue);
    });

    test('replaces features only', () {
      final copy = PromptTheme.dark.copyWith(features: DisplayFeatures.verbose);
      expect(identical(copy.colors, TerminalColors.dark), isTrue);
      expect(identical(copy.glyphs, TerminalGlyphs.unicode), isTrue);
      expect(identical(copy.features, DisplayFeatures.verbose), isTrue);
    });

    test('replaces all three components at once', () {
      final copy = PromptTheme.dark.copyWith(
        colors: TerminalColors.fire,
        glyphs: TerminalGlyphs.heavy,
        features: DisplayFeatures.compact,
      );
      expect(identical(copy.colors, TerminalColors.fire), isTrue);
      expect(identical(copy.glyphs, TerminalGlyphs.heavy), isTrue);
      expect(identical(copy.features, DisplayFeatures.compact), isTrue);
    });

    test('does not mutate the original theme', () {
      const original = PromptTheme();
      original.copyWith(colors: TerminalColors.neon);
      expect(identical(original.colors, TerminalColors.dark), isTrue);
    });

    test('chained copyWith composes correctly', () {
      final result = PromptTheme.dark
          .copyWith(colors: TerminalColors.pastel)
          .copyWith(glyphs: TerminalGlyphs.dotted)
          .copyWith(features: DisplayFeatures.focus);
      expect(identical(result.colors, TerminalColors.pastel), isTrue);
      expect(identical(result.glyphs, TerminalGlyphs.dotted), isTrue);
      expect(identical(result.features, DisplayFeatures.focus), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Convenience getters — Colors
  // ══════════════════════════════════════════════════════════════════════════

  group('color convenience getters', () {
    const theme = PromptTheme(colors: TerminalColors.dark);

    test('reset delegates to colors.reset', () {
      expect(theme.reset, equals(theme.colors.reset));
      expect(theme.reset, equals('\x1B[0m'));
    });

    test('bold delegates to colors.bold', () {
      expect(theme.bold, equals(theme.colors.bold));
      expect(theme.bold, equals('\x1B[1m'));
    });

    test('dim delegates to colors.dim', () {
      expect(theme.dim, equals(theme.colors.dim));
      expect(theme.dim, equals('\x1B[2m'));
    });

    test('gray delegates to colors.gray', () {
      expect(theme.gray, equals(theme.colors.gray));
    });

    test('accent delegates to colors.accent', () {
      expect(theme.accent, equals(theme.colors.accent));
    });

    test('keyAccent delegates to colors.keyAccent', () {
      expect(theme.keyAccent, equals(theme.colors.keyAccent));
    });

    test('highlight delegates to colors.highlight', () {
      expect(theme.highlight, equals(theme.colors.highlight));
    });

    test('selection delegates to colors.selection', () {
      expect(theme.selection, equals(theme.colors.selection));
    });

    test('checkboxOn delegates to colors.checkboxOn', () {
      expect(theme.checkboxOn, equals(theme.colors.checkboxOn));
    });

    test('checkboxOff delegates to colors.checkboxOff', () {
      expect(theme.checkboxOff, equals(theme.colors.checkboxOff));
    });

    test('inverse delegates to colors.inverse', () {
      expect(theme.inverse, equals(theme.colors.inverse));
      expect(theme.inverse, equals('\x1B[7m'));
    });

    test('info delegates to colors.info', () {
      expect(theme.info, equals(theme.colors.info));
    });

    test('warn delegates to colors.warn', () {
      expect(theme.warn, equals(theme.colors.warn));
    });

    test('error delegates to colors.error', () {
      expect(theme.error, equals(theme.colors.error));
    });

    test('getters reflect the active color palette', () {
      const matrixTheme = PromptTheme(colors: TerminalColors.matrix);
      expect(matrixTheme.accent, equals(TerminalColors.matrix.accent));
      expect(matrixTheme.accent, equals('\x1B[32m'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Convenience getters — Glyphs
  // ══════════════════════════════════════════════════════════════════════════

  group('glyph convenience getters', () {
    const theme = PromptTheme(glyphs: TerminalGlyphs.unicode);

    test('borderTop delegates to glyphs.borderTop', () {
      expect(theme.borderTop, equals(theme.glyphs.borderTop));
      expect(theme.borderTop, equals('┌'));
    });

    test('borderBottom delegates to glyphs.borderBottom', () {
      expect(theme.borderBottom, equals(theme.glyphs.borderBottom));
      expect(theme.borderBottom, equals('└'));
    });

    test('borderVertical delegates to glyphs.borderVertical', () {
      expect(theme.borderVertical, equals(theme.glyphs.borderVertical));
      expect(theme.borderVertical, equals('│'));
    });

    test('borderConnector delegates to glyphs.borderConnector', () {
      expect(theme.borderConnector, equals(theme.glyphs.borderConnector));
      expect(theme.borderConnector, equals('├'));
    });

    test('borderHorizontal delegates to glyphs.borderHorizontal', () {
      expect(theme.borderHorizontal, equals(theme.glyphs.borderHorizontal));
      expect(theme.borderHorizontal, equals('─'));
    });

    test('arrow delegates to glyphs.arrow', () {
      expect(theme.arrow, equals(theme.glyphs.arrow));
      expect(theme.arrow, equals('▶'));
    });

    test('checkboxOnSymbol delegates to glyphs.checkboxOnSymbol', () {
      expect(theme.checkboxOnSymbol, equals(theme.glyphs.checkboxOnSymbol));
      expect(theme.checkboxOnSymbol, equals('■'));
    });

    test('checkboxOffSymbol delegates to glyphs.checkboxOffSymbol', () {
      expect(theme.checkboxOffSymbol, equals(theme.glyphs.checkboxOffSymbol));
      expect(theme.checkboxOffSymbol, equals('□'));
    });

    test('getters reflect the active glyph set', () {
      const asciiTheme = PromptTheme(glyphs: TerminalGlyphs.ascii);
      expect(asciiTheme.arrow, equals('>'));
      expect(asciiTheme.borderTop, equals('+'));
      expect(asciiTheme.checkboxOnSymbol, equals('[x]'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Convenience getters — Features
  // ══════════════════════════════════════════════════════════════════════════

  group('feature convenience getters', () {
    test('standard features: borders on, bold on, inverse on, bullets', () {
      const theme = PromptTheme(features: DisplayFeatures.standard);
      expect(theme.showBorders, isTrue);
      expect(theme.boldTitles, isTrue);
      expect(theme.useInverseHighlight, isTrue);
      expect(theme.showConnector, isFalse);
      expect(theme.hintStyle, equals(HintStyle.bullets));
    });

    test('minimal features: borders off, bold off, inverse off, inline', () {
      const theme = PromptTheme(features: DisplayFeatures.minimal);
      expect(theme.showBorders, isFalse);
      expect(theme.boldTitles, isFalse);
      expect(theme.useInverseHighlight, isFalse);
      expect(theme.showConnector, isFalse);
      expect(theme.hintStyle, equals(HintStyle.inline));
    });

    test('compact features: borders on, hints none', () {
      const theme = PromptTheme(features: DisplayFeatures.compact);
      expect(theme.showBorders, isTrue);
      expect(theme.boldTitles, isTrue);
      expect(theme.hintStyle, equals(HintStyle.none));
    });

    test('verbose features: borders on, connector on, grid hints', () {
      const theme = PromptTheme(features: DisplayFeatures.verbose);
      expect(theme.showBorders, isTrue);
      expect(theme.showConnector, isTrue);
      expect(theme.hintStyle, equals(HintStyle.grid));
    });

    test('getters delegate to features object', () {
      const features = DisplayFeatures(
        showBorders: false,
        boldTitles: false,
        useInverseHighlight: false,
        showConnector: true,
        hintStyle: HintStyle.grid,
      );
      const theme = PromptTheme(features: features);
      expect(theme.showBorders, equals(features.showBorders));
      expect(theme.boldTitles, equals(features.boldTitles));
      expect(theme.useInverseHighlight, equals(features.useInverseHighlight));
      expect(theme.showConnector, equals(features.showConnector));
      expect(theme.hintStyle, equals(features.hintStyle));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Built-in theme presets
  // ══════════════════════════════════════════════════════════════════════════

  group('built-in themes', () {
    test('dark uses default components', () {
      expect(identical(PromptTheme.dark.colors, TerminalColors.dark), isTrue);
      expect(
          identical(PromptTheme.dark.glyphs, TerminalGlyphs.unicode), isTrue);
      expect(identical(PromptTheme.dark.features, DisplayFeatures.standard),
          isTrue);
    });

    test('minimal uses minimal features with default colors and glyphs', () {
      expect(
          identical(PromptTheme.minimal.colors, TerminalColors.dark), isTrue);
      expect(identical(PromptTheme.minimal.glyphs, TerminalGlyphs.unicode),
          isTrue);
      expect(identical(PromptTheme.minimal.features, DisplayFeatures.minimal),
          isTrue);
    });

    test('compact uses compact features with default colors and glyphs', () {
      expect(
          identical(PromptTheme.compact.colors, TerminalColors.dark), isTrue);
      expect(identical(PromptTheme.compact.glyphs, TerminalGlyphs.unicode),
          isTrue);
      expect(identical(PromptTheme.compact.features, DisplayFeatures.compact),
          isTrue);
    });

    test('matrix uses matrix colors and rounded glyphs', () {
      expect(
          identical(PromptTheme.matrix.colors, TerminalColors.matrix), isTrue);
      expect(
          identical(PromptTheme.matrix.glyphs, TerminalGlyphs.rounded), isTrue);
      expect(identical(PromptTheme.matrix.features, DisplayFeatures.standard),
          isTrue);
    });

    test('fire uses fire colors and double glyphs', () {
      expect(identical(PromptTheme.fire.colors, TerminalColors.fire), isTrue);
      expect(identical(PromptTheme.fire.glyphs, TerminalGlyphs.double), isTrue);
      expect(identical(PromptTheme.fire.features, DisplayFeatures.standard),
          isTrue);
    });

    test('pastel uses pastel colors with default glyphs', () {
      expect(
          identical(PromptTheme.pastel.colors, TerminalColors.pastel), isTrue);
      expect(
          identical(PromptTheme.pastel.glyphs, TerminalGlyphs.unicode), isTrue);
      expect(identical(PromptTheme.pastel.features, DisplayFeatures.standard),
          isTrue);
    });

    test('ocean uses ocean colors and dotted glyphs', () {
      expect(identical(PromptTheme.ocean.colors, TerminalColors.ocean), isTrue);
      expect(
          identical(PromptTheme.ocean.glyphs, TerminalGlyphs.dotted), isTrue);
      expect(identical(PromptTheme.ocean.features, DisplayFeatures.standard),
          isTrue);
    });

    test('monochrome uses monochrome colors and ascii glyphs', () {
      expect(
          identical(PromptTheme.monochrome.colors, TerminalColors.monochrome),
          isTrue);
      expect(identical(PromptTheme.monochrome.glyphs, TerminalGlyphs.ascii),
          isTrue);
      expect(
          identical(PromptTheme.monochrome.features, DisplayFeatures.standard),
          isTrue);
    });

    test('neon uses neon colors and heavy glyphs', () {
      expect(identical(PromptTheme.neon.colors, TerminalColors.neon), isTrue);
      expect(identical(PromptTheme.neon.glyphs, TerminalGlyphs.heavy), isTrue);
      expect(identical(PromptTheme.neon.features, DisplayFeatures.standard),
          isTrue);
    });

    test('arcane uses arcane colors and arcane glyphs', () {
      expect(
          identical(PromptTheme.arcane.colors, TerminalColors.arcane), isTrue);
      expect(
          identical(PromptTheme.arcane.glyphs, TerminalGlyphs.arcane), isTrue);
      expect(identical(PromptTheme.arcane.features, DisplayFeatures.standard),
          isTrue);
    });

    test('phantom uses phantom colors and phantom glyphs', () {
      expect(identical(PromptTheme.phantom.colors, TerminalColors.phantom),
          isTrue);
      expect(identical(PromptTheme.phantom.glyphs, TerminalGlyphs.phantom),
          isTrue);
      expect(identical(PromptTheme.phantom.features, DisplayFeatures.standard),
          isTrue);
    });

    test('all 11 built-in themes are distinct objects', () {
      final themes = [
        PromptTheme.dark,
        PromptTheme.minimal,
        PromptTheme.compact,
        PromptTheme.matrix,
        PromptTheme.fire,
        PromptTheme.pastel,
        PromptTheme.ocean,
        PromptTheme.monochrome,
        PromptTheme.neon,
        PromptTheme.arcane,
        PromptTheme.phantom,
      ];
      for (var i = 0; i < themes.length; i++) {
        for (var j = i + 1; j < themes.length; j++) {
          final a = themes[i];
          final b = themes[j];
          final same = identical(a.colors, b.colors) &&
              identical(a.glyphs, b.glyphs) &&
              identical(a.features, b.features);
          expect(same, isFalse,
              reason:
                  'theme $i and $j should differ in at least one component');
        }
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Getters reflect copyWith changes
  // ══════════════════════════════════════════════════════════════════════════

  group('getters reflect copyWith changes', () {
    test('color getters update after copyWith(colors:)', () {
      final theme = PromptTheme.dark.copyWith(colors: TerminalColors.matrix);
      expect(theme.accent, equals(TerminalColors.matrix.accent));
      expect(theme.accent, equals('\x1B[32m'));
    });

    test('glyph getters update after copyWith(glyphs:)', () {
      final theme = PromptTheme.dark.copyWith(glyphs: TerminalGlyphs.ascii);
      expect(theme.arrow, equals('>'));
      expect(theme.borderTop, equals('+'));
    });

    test('feature getters update after copyWith(features:)', () {
      final theme =
          PromptTheme.dark.copyWith(features: DisplayFeatures.minimal);
      expect(theme.showBorders, isFalse);
      expect(theme.boldTitles, isFalse);
      expect(theme.hintStyle, equals(HintStyle.inline));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Nested copyWith (theme → component → field)
  // ══════════════════════════════════════════════════════════════════════════

  group('nested copyWith composition', () {
    test('theme.copyWith with colors.copyWith overrides a single color', () {
      final theme = PromptTheme.dark.copyWith(
        colors: TerminalColors.dark.copyWith(accent: '\x1B[95m'),
      );
      expect(theme.accent, equals('\x1B[95m'));
      expect(theme.reset, equals('\x1B[0m'));
      expect(theme.bold, equals('\x1B[1m'));
    });

    test('theme.copyWith with glyphs.copyWith overrides a single glyph', () {
      final theme = PromptTheme.dark.copyWith(
        glyphs: TerminalGlyphs.unicode.copyWith(arrow: '→'),
      );
      expect(theme.arrow, equals('→'));
      expect(theme.borderTop, equals('┌'));
    });

    test('theme.copyWith with features.copyWith overrides a single feature',
        () {
      final theme = PromptTheme.dark.copyWith(
        features: DisplayFeatures.standard.copyWith(showBorders: false),
      );
      expect(theme.showBorders, isFalse);
      expect(theme.boldTitles, isTrue);
      expect(theme.hintStyle, equals(HintStyle.bullets));
    });

    test('deep override preserves unrelated fields across all components', () {
      final theme = PromptTheme.matrix.copyWith(
        colors: TerminalColors.matrix.copyWith(error: '\x1B[91m'),
        glyphs: TerminalGlyphs.rounded.copyWith(arrow: '⇒'),
        features: DisplayFeatures.standard.copyWith(showConnector: true),
      );
      expect(theme.error, equals('\x1B[91m'));
      expect(theme.accent, equals(TerminalColors.matrix.accent));
      expect(theme.arrow, equals('⇒'));
      expect(theme.borderTop, equals(TerminalGlyphs.rounded.borderTop));
      expect(theme.showConnector, isTrue);
      expect(theme.showBorders, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Cross-component consistency
  // ══════════════════════════════════════════════════════════════════════════

  group('cross-component consistency', () {
    test('all built-in themes produce valid ANSI reset sequences', () {
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
        expect(t.reset, equals('\x1B[0m'));
        expect(t.bold, equals('\x1B[1m'));
        expect(t.dim, equals('\x1B[2m'));
      }
    });

    test('all built-in themes have non-empty accent and highlight', () {
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
        expect(t.accent.isNotEmpty, isTrue);
        expect(t.highlight.isNotEmpty, isTrue);
        expect(t.accent, startsWith('\x1B['));
        expect(t.highlight, startsWith('\x1B['));
      }
    });

    test('all built-in themes with borders have non-empty border glyphs', () {
      final borderedThemes = [
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
      for (final t in borderedThemes) {
        expect(t.borderTop.isNotEmpty, isTrue);
        expect(t.borderBottom.isNotEmpty, isTrue);
        expect(t.borderVertical.isNotEmpty, isTrue);
        expect(t.borderHorizontal.isNotEmpty, isTrue);
      }
    });

    test('all built-in themes have non-empty arrow glyph', () {
      final themes = [
        PromptTheme.dark,
        PromptTheme.minimal,
        PromptTheme.compact,
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
        expect(t.arrow.isNotEmpty, isTrue);
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Styled string output
  // ══════════════════════════════════════════════════════════════════════════

  group('styled string output', () {
    test('theme produces correct styled string via getters', () {
      const theme = PromptTheme();
      final styled = '${theme.accent}Hello${theme.reset}';
      expect(styled, contains('\x1B[36m'));
      expect(styled, contains('\x1B[0m'));
      expect(stripAnsi(styled), equals('Hello'));
    });

    test('styled text has correct visible length', () {
      const theme = PromptTheme(colors: TerminalColors.matrix);
      final styled = '${theme.bold}${theme.accent}Status${theme.reset}';
      expect(visibleLength(styled), equals(6));
    });

    test('different themes produce different ANSI sequences for same text', () {
      final darkStyled = '${PromptTheme.dark.accent}X${PromptTheme.dark.reset}';
      final matrixStyled =
          '${PromptTheme.matrix.accent}X${PromptTheme.matrix.reset}';
      expect(stripAnsi(darkStyled), equals(stripAnsi(matrixStyled)));
      expect(darkStyled, isNot(equals(matrixStyled)));
    });

    test('border glyph output matches the glyph set', () {
      const theme = PromptTheme(glyphs: TerminalGlyphs.rounded);
      final line = '${theme.borderTop}${theme.borderHorizontal}'
          '${theme.borderHorizontal}${theme.glyphs.matchingCorner(theme.borderTop)}';
      expect(line, equals('╭──╮'));
    });

    test('ascii theme produces pure ASCII border output', () {
      const theme = PromptTheme(glyphs: TerminalGlyphs.ascii);
      final line = '${theme.borderTop}${theme.borderHorizontal}'
          '${theme.borderHorizontal}${theme.glyphs.matchingCorner(theme.borderTop)}';
      expect(line, equals('+--+'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Edge cases
  // ══════════════════════════════════════════════════════════════════════════

  group('edge cases', () {
    test('theme with fully custom colors produces usable styled output', () {
      const custom = TerminalColors(
        reset: '[R]',
        bold: '[B]',
        dim: '[D]',
        gray: '[G]',
        accent: '[A]',
        keyAccent: '[K]',
        highlight: '[H]',
        selection: '[S]',
        checkboxOn: '[+]',
        checkboxOff: '[-]',
        inverse: '[I]',
        info: '[i]',
        warn: '[w]',
        error: '[e]',
      );
      const theme = PromptTheme(colors: custom);
      expect(theme.accent, equals('[A]'));
      expect(theme.reset, equals('[R]'));
      expect('${theme.bold}Title${theme.reset}', equals('[B]Title[R]'));
    });

    test('theme with fully custom glyphs produces correct border', () {
      const custom = TerminalGlyphs(
        borderTop: 'T',
        borderBottom: 'B',
        borderVertical: 'V',
        borderConnector: 'C',
        borderHorizontal: 'H',
        arrow: 'A',
        checkboxOnSymbol: 'Y',
        checkboxOffSymbol: 'N',
      );
      const theme = PromptTheme(glyphs: custom);
      expect(theme.borderTop, equals('T'));
      expect(theme.arrow, equals('A'));
      expect(theme.checkboxOnSymbol, equals('Y'));
    });

    test('minimal theme with minimal features has no borders', () {
      expect(PromptTheme.minimal.showBorders, isFalse);
      expect(PromptTheme.minimal.boldTitles, isFalse);
      expect(PromptTheme.minimal.useInverseHighlight, isFalse);
    });

    test(
        'copyWith on a preset preserves preset identity for untouched components',
        () {
      final derived = PromptTheme.arcane.copyWith(
        features: DisplayFeatures.compact,
      );
      expect(identical(derived.colors, TerminalColors.arcane), isTrue);
      expect(identical(derived.glyphs, TerminalGlyphs.arcane), isTrue);
      expect(identical(derived.features, DisplayFeatures.compact), isTrue);
    });
  });
}
