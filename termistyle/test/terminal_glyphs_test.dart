import 'package:test/test.dart';
import 'package:termistyle/termistyle.dart';

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // Default constructor
  // ══════════════════════════════════════════════════════════════════════════

  group('default constructor', () {
    test('uses standard Unicode box-drawing defaults', () {
      const g = TerminalGlyphs();
      expect(g.borderTop, equals('┌'));
      expect(g.borderBottom, equals('└'));
      expect(g.borderVertical, equals('│'));
      expect(g.borderConnector, equals('├'));
      expect(g.borderHorizontal, equals('─'));
      expect(g.arrow, equals('▶'));
      expect(g.checkboxOnSymbol, equals('■'));
      expect(g.checkboxOffSymbol, equals('□'));
    });

    test('matches the unicode preset exactly', () {
      const defaults = TerminalGlyphs();
      const unicode = TerminalGlyphs.unicode;
      expect(defaults.borderTop, equals(unicode.borderTop));
      expect(defaults.borderBottom, equals(unicode.borderBottom));
      expect(defaults.borderVertical, equals(unicode.borderVertical));
      expect(defaults.borderConnector, equals(unicode.borderConnector));
      expect(defaults.borderHorizontal, equals(unicode.borderHorizontal));
      expect(defaults.arrow, equals(unicode.arrow));
      expect(defaults.checkboxOnSymbol, equals(unicode.checkboxOnSymbol));
      expect(defaults.checkboxOffSymbol, equals(unicode.checkboxOffSymbol));
    });

    test('allows overriding individual parameters', () {
      const g = TerminalGlyphs(arrow: '>', borderTop: '+');
      expect(g.arrow, equals('>'));
      expect(g.borderTop, equals('+'));
      expect(g.borderBottom, equals('└'));
      expect(g.borderVertical, equals('│'));
    });

    test('allows overriding all parameters', () {
      const g = TerminalGlyphs(
        borderTop: 'A',
        borderBottom: 'B',
        borderVertical: 'C',
        borderConnector: 'D',
        borderHorizontal: 'E',
        arrow: 'F',
        checkboxOnSymbol: 'G',
        checkboxOffSymbol: 'H',
      );
      expect(g.borderTop, equals('A'));
      expect(g.borderBottom, equals('B'));
      expect(g.borderVertical, equals('C'));
      expect(g.borderConnector, equals('D'));
      expect(g.borderHorizontal, equals('E'));
      expect(g.arrow, equals('F'));
      expect(g.checkboxOnSymbol, equals('G'));
      expect(g.checkboxOffSymbol, equals('H'));
    });

    test('supports empty strings', () {
      const g = TerminalGlyphs(borderTop: '', borderBottom: '', arrow: '');
      expect(g.borderTop, equals(''));
      expect(g.borderBottom, equals(''));
      expect(g.arrow, equals(''));
    });

    test('supports multi-character strings', () {
      const g = TerminalGlyphs(
        checkboxOnSymbol: '[x]',
        checkboxOffSymbol: '[ ]',
      );
      expect(g.checkboxOnSymbol, equals('[x]'));
      expect(g.checkboxOffSymbol, equals('[ ]'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // copyWith
  // ══════════════════════════════════════════════════════════════════════════

  group('copyWith', () {
    test('returns identical copy when called with no arguments', () {
      const original = TerminalGlyphs();
      final copy = original.copyWith();
      expect(copy.borderTop, equals(original.borderTop));
      expect(copy.borderBottom, equals(original.borderBottom));
      expect(copy.borderVertical, equals(original.borderVertical));
      expect(copy.borderConnector, equals(original.borderConnector));
      expect(copy.borderHorizontal, equals(original.borderHorizontal));
      expect(copy.arrow, equals(original.arrow));
      expect(copy.checkboxOnSymbol, equals(original.checkboxOnSymbol));
      expect(copy.checkboxOffSymbol, equals(original.checkboxOffSymbol));
    });

    test('overrides borderTop only', () {
      const original = TerminalGlyphs();
      final copy = original.copyWith(borderTop: '╭');
      expect(copy.borderTop, equals('╭'));
      expect(copy.borderBottom, equals(original.borderBottom));
      expect(copy.arrow, equals(original.arrow));
    });

    test('overrides borderBottom only', () {
      const original = TerminalGlyphs();
      final copy = original.copyWith(borderBottom: '╰');
      expect(copy.borderBottom, equals('╰'));
      expect(copy.borderTop, equals(original.borderTop));
    });

    test('overrides borderVertical only', () {
      const original = TerminalGlyphs();
      final copy = original.copyWith(borderVertical: '┃');
      expect(copy.borderVertical, equals('┃'));
      expect(copy.borderHorizontal, equals(original.borderHorizontal));
    });

    test('overrides borderConnector only', () {
      const original = TerminalGlyphs();
      final copy = original.copyWith(borderConnector: '┣');
      expect(copy.borderConnector, equals('┣'));
      expect(copy.borderVertical, equals(original.borderVertical));
    });

    test('overrides borderHorizontal only', () {
      const original = TerminalGlyphs();
      final copy = original.copyWith(borderHorizontal: '━');
      expect(copy.borderHorizontal, equals('━'));
      expect(copy.borderVertical, equals(original.borderVertical));
    });

    test('overrides arrow only', () {
      const original = TerminalGlyphs();
      final copy = original.copyWith(arrow: '❯');
      expect(copy.arrow, equals('❯'));
      expect(copy.checkboxOnSymbol, equals(original.checkboxOnSymbol));
    });

    test('overrides checkboxOnSymbol only', () {
      const original = TerminalGlyphs();
      final copy = original.copyWith(checkboxOnSymbol: '✓');
      expect(copy.checkboxOnSymbol, equals('✓'));
      expect(copy.checkboxOffSymbol, equals(original.checkboxOffSymbol));
    });

    test('overrides checkboxOffSymbol only', () {
      const original = TerminalGlyphs();
      final copy = original.copyWith(checkboxOffSymbol: '·');
      expect(copy.checkboxOffSymbol, equals('·'));
      expect(copy.checkboxOnSymbol, equals(original.checkboxOnSymbol));
    });

    test('overrides multiple properties at once', () {
      const original = TerminalGlyphs();
      final copy = original.copyWith(
        borderTop: '╔',
        borderBottom: '╚',
        arrow: '➤',
      );
      expect(copy.borderTop, equals('╔'));
      expect(copy.borderBottom, equals('╚'));
      expect(copy.arrow, equals('➤'));
      expect(copy.borderVertical, equals(original.borderVertical));
      expect(copy.borderHorizontal, equals(original.borderHorizontal));
      expect(copy.borderConnector, equals(original.borderConnector));
      expect(copy.checkboxOnSymbol, equals(original.checkboxOnSymbol));
      expect(copy.checkboxOffSymbol, equals(original.checkboxOffSymbol));
    });

    test('overrides all properties', () {
      const original = TerminalGlyphs();
      final copy = original.copyWith(
        borderTop: 'T',
        borderBottom: 'B',
        borderVertical: 'V',
        borderConnector: 'C',
        borderHorizontal: 'H',
        arrow: 'A',
        checkboxOnSymbol: 'ON',
        checkboxOffSymbol: 'OFF',
      );
      expect(copy.borderTop, equals('T'));
      expect(copy.borderBottom, equals('B'));
      expect(copy.borderVertical, equals('V'));
      expect(copy.borderConnector, equals('C'));
      expect(copy.borderHorizontal, equals('H'));
      expect(copy.arrow, equals('A'));
      expect(copy.checkboxOnSymbol, equals('ON'));
      expect(copy.checkboxOffSymbol, equals('OFF'));
    });

    test('does not mutate the original', () {
      const original = TerminalGlyphs();
      original.copyWith(borderTop: 'X', arrow: 'Y');
      expect(original.borderTop, equals('┌'));
      expect(original.arrow, equals('▶'));
    });

    test('is chainable', () {
      const original = TerminalGlyphs();
      final result = original
          .copyWith(borderTop: '╭')
          .copyWith(borderBottom: '╰')
          .copyWith(arrow: '❯');
      expect(result.borderTop, equals('╭'));
      expect(result.borderBottom, equals('╰'));
      expect(result.arrow, equals('❯'));
      expect(result.borderVertical, equals(original.borderVertical));
    });

    test('works on presets', () {
      final copy = TerminalGlyphs.ascii.copyWith(arrow: '>>');
      expect(copy.arrow, equals('>>'));
      expect(copy.borderTop, equals('+'));
      expect(copy.borderVertical, equals('|'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // matchingCorner
  // ══════════════════════════════════════════════════════════════════════════

  group('matchingCorner', () {
    const g = TerminalGlyphs();

    test('matches rounded top-left to top-right', () {
      expect(g.matchingCorner('╭'), equals('╮'));
    });

    test('matches rounded bottom-left to bottom-right', () {
      expect(g.matchingCorner('╰'), equals('╯'));
    });

    test('matches double top-left to top-right', () {
      expect(g.matchingCorner('╔'), equals('╗'));
    });

    test('matches double bottom-left to bottom-right', () {
      expect(g.matchingCorner('╚'), equals('╝'));
    });

    test('matches standard top-left to top-right', () {
      expect(g.matchingCorner('┌'), equals('┐'));
    });

    test('matches standard bottom-left to bottom-right', () {
      expect(g.matchingCorner('└'), equals('┘'));
    });

    test('matches heavy top-left to top-right', () {
      expect(g.matchingCorner('┏'), equals('┓'));
    });

    test('matches heavy bottom-left to bottom-right', () {
      expect(g.matchingCorner('┗'), equals('┛'));
    });

    test('matches ASCII plus to plus', () {
      expect(g.matchingCorner('+'), equals('+'));
    });

    test('matches arcane top-left to top-right', () {
      expect(g.matchingCorner('⸢'), equals('⸣'));
    });

    test('matches arcane bottom-left to bottom-right', () {
      expect(g.matchingCorner('⸤'), equals('⸥'));
    });

    test('matches phantom top-left to top-right', () {
      expect(g.matchingCorner('⌜'), equals('⌝'));
    });

    test('matches phantom bottom-left to bottom-right', () {
      expect(g.matchingCorner('⌞'), equals('⌟'));
    });

    test('returns the input for unknown glyphs', () {
      expect(g.matchingCorner('X'), equals('X'));
      expect(g.matchingCorner('?'), equals('?'));
      expect(g.matchingCorner('#'), equals('#'));
    });

    test('returns the input for empty string', () {
      expect(g.matchingCorner(''), equals(''));
    });

    test('works regardless of which instance is used', () {
      expect(TerminalGlyphs.ascii.matchingCorner('╭'), equals('╮'));
      expect(TerminalGlyphs.heavy.matchingCorner('┌'), equals('┐'));
      expect(TerminalGlyphs.minimal.matchingCorner('╔'), equals('╗'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Built-in presets
  // ══════════════════════════════════════════════════════════════════════════

  group('presets', () {
    group('unicode', () {
      test('uses standard box-drawing characters', () {
        const g = TerminalGlyphs.unicode;
        expect(g.borderTop, equals('┌'));
        expect(g.borderBottom, equals('└'));
        expect(g.borderVertical, equals('│'));
        expect(g.borderConnector, equals('├'));
        expect(g.borderHorizontal, equals('─'));
        expect(g.arrow, equals('▶'));
        expect(g.checkboxOnSymbol, equals('■'));
        expect(g.checkboxOffSymbol, equals('□'));
      });
    });

    group('ascii', () {
      test('uses only ASCII-safe characters', () {
        const g = TerminalGlyphs.ascii;
        expect(g.borderTop, equals('+'));
        expect(g.borderBottom, equals('+'));
        expect(g.borderVertical, equals('|'));
        expect(g.borderConnector, equals('+'));
        expect(g.borderHorizontal, equals('-'));
        expect(g.arrow, equals('>'));
        expect(g.checkboxOnSymbol, equals('[x]'));
        expect(g.checkboxOffSymbol, equals('[ ]'));
      });

      test('all characters are 7-bit ASCII', () {
        const g = TerminalGlyphs.ascii;
        for (final ch in [
          g.borderTop,
          g.borderBottom,
          g.borderVertical,
          g.borderConnector,
          g.borderHorizontal,
          g.arrow,
        ]) {
          for (final rune in ch.runes) {
            expect(rune, lessThan(128),
                reason: '"$ch" contains non-ASCII rune $rune');
          }
        }
      });
    });

    group('rounded', () {
      test('uses rounded corner characters', () {
        const g = TerminalGlyphs.rounded;
        expect(g.borderTop, equals('╭'));
        expect(g.borderBottom, equals('╰'));
        expect(g.borderVertical, equals('│'));
        expect(g.borderConnector, equals('├'));
        expect(g.borderHorizontal, equals('─'));
        expect(g.arrow, equals('❯'));
        expect(g.checkboxOnSymbol, equals('◉'));
        expect(g.checkboxOffSymbol, equals('○'));
      });
    });

    group('double', () {
      test('uses double-line border characters', () {
        const g = TerminalGlyphs.double;
        expect(g.borderTop, equals('╔'));
        expect(g.borderBottom, equals('╚'));
        expect(g.borderVertical, equals('║'));
        expect(g.borderConnector, equals('╟'));
        expect(g.borderHorizontal, equals('═'));
        expect(g.arrow, equals('➤'));
        expect(g.checkboxOnSymbol, equals('■'));
        expect(g.checkboxOffSymbol, equals('□'));
      });
    });

    group('heavy', () {
      test('uses heavy/thick border characters', () {
        const g = TerminalGlyphs.heavy;
        expect(g.borderTop, equals('┏'));
        expect(g.borderBottom, equals('┗'));
        expect(g.borderVertical, equals('┃'));
        expect(g.borderConnector, equals('┣'));
        expect(g.borderHorizontal, equals('━'));
        expect(g.arrow, equals('>'));
        expect(g.checkboxOnSymbol, equals('◈'));
        expect(g.checkboxOffSymbol, equals('◇'));
      });
    });

    group('dotted', () {
      test('uses dotted vertical lines with rounded corners', () {
        const g = TerminalGlyphs.dotted;
        expect(g.borderTop, equals('╭'));
        expect(g.borderBottom, equals('╰'));
        expect(g.borderVertical, equals('┊'));
        expect(g.borderConnector, equals('├'));
        expect(g.borderHorizontal, equals('─'));
        expect(g.arrow, equals('▸'));
        expect(g.checkboxOnSymbol, equals('●'));
        expect(g.checkboxOffSymbol, equals('○'));
      });
    });

    group('arcane', () {
      test('uses mystical/arcane symbols', () {
        const g = TerminalGlyphs.arcane;
        expect(g.borderTop, equals('⸢'));
        expect(g.borderBottom, equals('⸤'));
        expect(g.borderVertical, equals('⁞'));
        expect(g.borderConnector, equals('⊢'));
        expect(g.borderHorizontal, equals('─'));
        expect(g.arrow, equals('⊳'));
        expect(g.checkboxOnSymbol, equals('⬢'));
        expect(g.checkboxOffSymbol, equals('⬡'));
      });
    });

    group('phantom', () {
      test('uses floating corner characters', () {
        const g = TerminalGlyphs.phantom;
        expect(g.borderTop, equals('⌜'));
        expect(g.borderBottom, equals('⌞'));
        expect(g.borderVertical, equals('¦'));
        expect(g.borderConnector, equals('·'));
        expect(g.borderHorizontal, equals('─'));
        expect(g.arrow, equals('›'));
        expect(g.checkboxOnSymbol, equals('◉'));
        expect(g.checkboxOffSymbol, equals('◌'));
      });
    });

    group('minimal', () {
      test('uses empty borders and simple symbols', () {
        const g = TerminalGlyphs.minimal;
        expect(g.borderTop, equals(''));
        expect(g.borderBottom, equals(''));
        expect(g.borderVertical, equals(''));
        expect(g.borderConnector, equals(''));
        expect(g.borderHorizontal, equals(''));
        expect(g.arrow, equals('›'));
        expect(g.checkboxOnSymbol, equals('✓'));
        expect(g.checkboxOffSymbol, equals('·'));
      });

      test('border characters are all empty strings', () {
        const g = TerminalGlyphs.minimal;
        expect(g.borderTop.isEmpty, isTrue);
        expect(g.borderBottom.isEmpty, isTrue);
        expect(g.borderVertical.isEmpty, isTrue);
        expect(g.borderConnector.isEmpty, isTrue);
        expect(g.borderHorizontal.isEmpty, isTrue);
      });

      test('non-border glyphs are still present', () {
        const g = TerminalGlyphs.minimal;
        expect(g.arrow.isNotEmpty, isTrue);
        expect(g.checkboxOnSymbol.isNotEmpty, isTrue);
        expect(g.checkboxOffSymbol.isNotEmpty, isTrue);
      });
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Preset consistency
  // ══════════════════════════════════════════════════════════════════════════

  group('preset consistency', () {
    final allPresets = {
      'unicode': TerminalGlyphs.unicode,
      'ascii': TerminalGlyphs.ascii,
      'rounded': TerminalGlyphs.rounded,
      'double': TerminalGlyphs.double,
      'heavy': TerminalGlyphs.heavy,
      'dotted': TerminalGlyphs.dotted,
      'arcane': TerminalGlyphs.arcane,
      'phantom': TerminalGlyphs.phantom,
      'minimal': TerminalGlyphs.minimal,
    };

    test('9 presets are available', () {
      expect(allPresets.length, equals(9));
    });

    test('every non-minimal preset has non-empty border characters', () {
      for (final entry in allPresets.entries) {
        if (entry.key == 'minimal') continue;
        final g = entry.value;
        expect(g.borderTop.isNotEmpty, isTrue,
            reason: '${entry.key}.borderTop should be non-empty');
        expect(g.borderBottom.isNotEmpty, isTrue,
            reason: '${entry.key}.borderBottom should be non-empty');
        expect(g.borderVertical.isNotEmpty, isTrue,
            reason: '${entry.key}.borderVertical should be non-empty');
        expect(g.borderConnector.isNotEmpty, isTrue,
            reason: '${entry.key}.borderConnector should be non-empty');
        expect(g.borderHorizontal.isNotEmpty, isTrue,
            reason: '${entry.key}.borderHorizontal should be non-empty');
      }
    });

    test('every preset has a non-empty arrow', () {
      for (final entry in allPresets.entries) {
        expect(entry.value.arrow.isNotEmpty, isTrue,
            reason: '${entry.key}.arrow should be non-empty');
      }
    });

    test('every preset has non-empty checkbox symbols', () {
      for (final entry in allPresets.entries) {
        expect(entry.value.checkboxOnSymbol.isNotEmpty, isTrue,
            reason: '${entry.key}.checkboxOnSymbol should be non-empty');
        expect(entry.value.checkboxOffSymbol.isNotEmpty, isTrue,
            reason: '${entry.key}.checkboxOffSymbol should be non-empty');
      }
    });

    test('checkbox on and off symbols are distinct within each preset', () {
      for (final entry in allPresets.entries) {
        final g = entry.value;
        expect(g.checkboxOnSymbol, isNot(equals(g.checkboxOffSymbol)),
            reason:
                '${entry.key} should have distinct on/off checkbox symbols');
      }
    });

    test('every preset with non-empty borderTop has a valid matching corner',
        () {
      for (final entry in allPresets.entries) {
        final g = entry.value;
        if (g.borderTop.isEmpty) continue;
        final rightCorner = g.matchingCorner(g.borderTop);
        expect(rightCorner.isNotEmpty, isTrue,
            reason:
                '${entry.key}.matchingCorner(borderTop) should be non-empty');
      }
    });

    test('every preset with non-empty borderBottom has a valid matching corner',
        () {
      for (final entry in allPresets.entries) {
        final g = entry.value;
        if (g.borderBottom.isEmpty) continue;
        final rightCorner = g.matchingCorner(g.borderBottom);
        expect(rightCorner.isNotEmpty, isTrue,
            reason:
                '${entry.key}.matchingCorner(borderBottom) should be non-empty');
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // matchingCorner exhaustive pairs
  // ══════════════════════════════════════════════════════════════════════════

  group('matchingCorner all known pairs', () {
    const g = TerminalGlyphs();
    final knownPairs = {
      '╭': '╮',
      '╰': '╯',
      '╔': '╗',
      '╚': '╝',
      '┌': '┐',
      '└': '┘',
      '┏': '┓',
      '┗': '┛',
      '+': '+',
      '⸢': '⸣',
      '⸤': '⸥',
      '⌜': '⌝',
      '⌞': '⌟',
    };

    for (final pair in knownPairs.entries) {
      test('${pair.key} → ${pair.value}', () {
        expect(g.matchingCorner(pair.key), equals(pair.value));
      });
    }

    test('all 13 known pairs are covered', () {
      expect(knownPairs.length, equals(13));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // const correctness
  // ══════════════════════════════════════════════════════════════════════════

  group('const correctness', () {
    test('default constructor is const', () {
      const g = TerminalGlyphs();
      expect(g, isNotNull);
    });

    test('presets are compile-time constants', () {
      const u = TerminalGlyphs.unicode;
      const a = TerminalGlyphs.ascii;
      const r = TerminalGlyphs.rounded;
      const d = TerminalGlyphs.double;
      const h = TerminalGlyphs.heavy;
      const dt = TerminalGlyphs.dotted;
      const ar = TerminalGlyphs.arcane;
      const p = TerminalGlyphs.phantom;
      const m = TerminalGlyphs.minimal;
      expect([u, a, r, d, h, dt, ar, p, m].length, equals(9));
    });

    test('custom constructor with all parameters is const', () {
      const g = TerminalGlyphs(
        borderTop: 'A',
        borderBottom: 'B',
        borderVertical: 'C',
        borderConnector: 'D',
        borderHorizontal: 'E',
        arrow: 'F',
        checkboxOnSymbol: 'G',
        checkboxOffSymbol: 'H',
      );
      expect(g.borderTop, equals('A'));
    });
  });
}
