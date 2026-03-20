import 'package:test/test.dart';
import 'package:termistyle/termistyle.dart';

/// All 14 field names in constructor order.
const _fieldNames = [
  'reset',
  'bold',
  'dim',
  'gray',
  'accent',
  'keyAccent',
  'highlight',
  'selection',
  'checkboxOn',
  'checkboxOff',
  'inverse',
  'info',
  'warn',
  'error',
];

/// Reads every field value from a [TerminalColors] in constructor order.
List<String> _allFields(TerminalColors c) => [
      c.reset,
      c.bold,
      c.dim,
      c.gray,
      c.accent,
      c.keyAccent,
      c.highlight,
      c.selection,
      c.checkboxOn,
      c.checkboxOff,
      c.inverse,
      c.info,
      c.warn,
      c.error,
    ];

/// ANSI SGR pattern: ESC [ <\params> m
final _ansiSgr = RegExp(r'^\x1B\[[0-9;]*m$');

/// Returns true if every segment of [value] (split on ESC) is a valid SGR.
bool _isValidAnsi(String value) {
  if (value.isEmpty) return true;
  final parts = value.split('\x1B');
  for (var i = 1; i < parts.length; i++) {
    if (!_ansiSgr.hasMatch('\x1B${parts[i]}')) return false;
  }
  return true;
}

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // Default constructor
  // ══════════════════════════════════════════════════════════════════════════

  group('default constructor', () {
    const c = TerminalColors();

    test('reset is ESC[0m', () {
      expect(c.reset, equals('\x1B[0m'));
    });

    test('bold is ESC[1m', () {
      expect(c.bold, equals('\x1B[1m'));
    });

    test('dim is ESC[2m', () {
      expect(c.dim, equals('\x1B[2m'));
    });

    test('gray is ESC[90m', () {
      expect(c.gray, equals('\x1B[90m'));
    });

    test('accent is ESC[36m (cyan)', () {
      expect(c.accent, equals('\x1B[36m'));
    });

    test('keyAccent is ESC[37m (white)', () {
      expect(c.keyAccent, equals('\x1B[37m'));
    });

    test('highlight is ESC[33m (yellow)', () {
      expect(c.highlight, equals('\x1B[33m'));
    });

    test('selection is ESC[35m (magenta)', () {
      expect(c.selection, equals('\x1B[35m'));
    });

    test('checkboxOn is ESC[32m (green)', () {
      expect(c.checkboxOn, equals('\x1B[32m'));
    });

    test('checkboxOff is ESC[90m (gray)', () {
      expect(c.checkboxOff, equals('\x1B[90m'));
    });

    test('inverse is ESC[7m', () {
      expect(c.inverse, equals('\x1B[7m'));
    });

    test('info is ESC[36m (cyan)', () {
      expect(c.info, equals('\x1B[36m'));
    });

    test('warn is ESC[33m (yellow)', () {
      expect(c.warn, equals('\x1B[33m'));
    });

    test('error is ESC[31m (red)', () {
      expect(c.error, equals('\x1B[31m'));
    });

    test('all 14 fields contain valid ANSI SGR sequences', () {
      for (final v in _allFields(c)) {
        expect(_isValidAnsi(v), isTrue, reason: 'Invalid ANSI: $v');
      }
    });

    test('is identical to TerminalColors.dark', () {
      final d = TerminalColors.dark;
      final defaultFields = _allFields(c);
      final darkFields = _allFields(d);
      for (var i = 0; i < _fieldNames.length; i++) {
        expect(defaultFields[i], equals(darkFields[i]),
            reason: '${_fieldNames[i]} differs');
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Custom constructor
  // ══════════════════════════════════════════════════════════════════════════

  group('custom constructor', () {
    test('accepts custom values for all fields', () {
      const c = TerminalColors(
        reset: 'R',
        bold: 'B',
        dim: 'D',
        gray: 'G',
        accent: 'A',
        keyAccent: 'K',
        highlight: 'H',
        selection: 'S',
        checkboxOn: 'ON',
        checkboxOff: 'OFF',
        inverse: 'I',
        info: 'INF',
        warn: 'W',
        error: 'E',
      );
      expect(c.reset, equals('R'));
      expect(c.bold, equals('B'));
      expect(c.dim, equals('D'));
      expect(c.gray, equals('G'));
      expect(c.accent, equals('A'));
      expect(c.keyAccent, equals('K'));
      expect(c.highlight, equals('H'));
      expect(c.selection, equals('S'));
      expect(c.checkboxOn, equals('ON'));
      expect(c.checkboxOff, equals('OFF'));
      expect(c.inverse, equals('I'));
      expect(c.info, equals('INF'));
      expect(c.warn, equals('W'));
      expect(c.error, equals('E'));
    });

    test('partial override keeps defaults for omitted fields', () {
      const c = TerminalColors(accent: '\x1B[95m');
      expect(c.accent, equals('\x1B[95m'));
      expect(c.reset, equals('\x1B[0m'));
      expect(c.bold, equals('\x1B[1m'));
      expect(c.highlight, equals('\x1B[33m'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // copyWith
  // ══════════════════════════════════════════════════════════════════════════

  group('copyWith', () {
    const base = TerminalColors();

    test('returns identical object when no arguments are given', () {
      final copy = base.copyWith();
      final baseFields = _allFields(base);
      final copyFields = _allFields(copy);
      for (var i = 0; i < _fieldNames.length; i++) {
        expect(copyFields[i], equals(baseFields[i]),
            reason: '${_fieldNames[i]} changed unexpectedly');
      }
    });

    test('overrides reset only', () {
      final copy = base.copyWith(reset: 'X');
      expect(copy.reset, equals('X'));
      expect(copy.bold, equals(base.bold));
      expect(copy.accent, equals(base.accent));
    });

    test('overrides bold only', () {
      final copy = base.copyWith(bold: 'X');
      expect(copy.bold, equals('X'));
      expect(copy.reset, equals(base.reset));
    });

    test('overrides dim only', () {
      final copy = base.copyWith(dim: 'X');
      expect(copy.dim, equals('X'));
      expect(copy.gray, equals(base.gray));
    });

    test('overrides gray only', () {
      final copy = base.copyWith(gray: 'X');
      expect(copy.gray, equals('X'));
      expect(copy.dim, equals(base.dim));
    });

    test('overrides accent only', () {
      final copy = base.copyWith(accent: 'X');
      expect(copy.accent, equals('X'));
      expect(copy.keyAccent, equals(base.keyAccent));
    });

    test('overrides keyAccent only', () {
      final copy = base.copyWith(keyAccent: 'X');
      expect(copy.keyAccent, equals('X'));
      expect(copy.accent, equals(base.accent));
    });

    test('overrides highlight only', () {
      final copy = base.copyWith(highlight: 'X');
      expect(copy.highlight, equals('X'));
      expect(copy.selection, equals(base.selection));
    });

    test('overrides selection only', () {
      final copy = base.copyWith(selection: 'X');
      expect(copy.selection, equals('X'));
      expect(copy.highlight, equals(base.highlight));
    });

    test('overrides checkboxOn only', () {
      final copy = base.copyWith(checkboxOn: 'X');
      expect(copy.checkboxOn, equals('X'));
      expect(copy.checkboxOff, equals(base.checkboxOff));
    });

    test('overrides checkboxOff only', () {
      final copy = base.copyWith(checkboxOff: 'X');
      expect(copy.checkboxOff, equals('X'));
      expect(copy.checkboxOn, equals(base.checkboxOn));
    });

    test('overrides inverse only', () {
      final copy = base.copyWith(inverse: 'X');
      expect(copy.inverse, equals('X'));
      expect(copy.info, equals(base.info));
    });

    test('overrides info only', () {
      final copy = base.copyWith(info: 'X');
      expect(copy.info, equals('X'));
      expect(copy.warn, equals(base.warn));
    });

    test('overrides warn only', () {
      final copy = base.copyWith(warn: 'X');
      expect(copy.warn, equals('X'));
      expect(copy.error, equals(base.error));
    });

    test('overrides error only', () {
      final copy = base.copyWith(error: 'X');
      expect(copy.error, equals('X'));
      expect(copy.warn, equals(base.warn));
    });

    test('overrides multiple fields at once', () {
      final copy = base.copyWith(
        accent: '\x1B[95m',
        highlight: '\x1B[96m',
        error: '\x1B[91m',
      );
      expect(copy.accent, equals('\x1B[95m'));
      expect(copy.highlight, equals('\x1B[96m'));
      expect(copy.error, equals('\x1B[91m'));
      expect(copy.reset, equals(base.reset));
      expect(copy.bold, equals(base.bold));
      expect(copy.selection, equals(base.selection));
    });

    test('chained copyWith applies all overrides', () {
      final copy = base
          .copyWith(accent: 'A1')
          .copyWith(highlight: 'H1')
          .copyWith(error: 'E1');
      expect(copy.accent, equals('A1'));
      expect(copy.highlight, equals('H1'));
      expect(copy.error, equals('E1'));
      expect(copy.reset, equals(base.reset));
    });

    test('does not mutate the original', () {
      final original = TerminalColors();
      final originalAccent = original.accent;
      original.copyWith(accent: 'changed');
      expect(original.accent, equals(originalAccent));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Built-in presets — existence, type, and ANSI validity
  // ══════════════════════════════════════════════════════════════════════════

  group('built-in presets', () {
    final presets = <String, TerminalColors>{
      'dark': TerminalColors.dark,
      'matrix': TerminalColors.matrix,
      'fire': TerminalColors.fire,
      'pastel': TerminalColors.pastel,
      'ocean': TerminalColors.ocean,
      'monochrome': TerminalColors.monochrome,
      'neon': TerminalColors.neon,
      'arcane': TerminalColors.arcane,
      'phantom': TerminalColors.phantom,
    };

    test('exactly 9 built-in presets exist', () {
      expect(presets.length, equals(9));
    });

    for (final entry in presets.entries) {
      group(entry.key, () {
        final preset = entry.value;

        test('is a TerminalColors instance', () {
          expect(preset, isA<TerminalColors>());
        });

        test('all fields are non-empty strings', () {
          for (var i = 0; i < _fieldNames.length; i++) {
            final value = _allFields(preset)[i];
            expect(value, isNotEmpty,
                reason: '${entry.key}.${_fieldNames[i]} is empty');
          }
        });

        test('all fields contain valid ANSI SGR sequences', () {
          for (var i = 0; i < _fieldNames.length; i++) {
            final value = _allFields(preset)[i];
            expect(_isValidAnsi(value), isTrue,
                reason:
                    '${entry.key}.${_fieldNames[i]} invalid ANSI: "$value"');
          }
        });

        test('reset is always ESC[0m', () {
          expect(preset.reset, equals('\x1B[0m'));
        });

        test('bold is always ESC[1m', () {
          expect(preset.bold, equals('\x1B[1m'));
        });

        test('dim is always ESC[2m', () {
          expect(preset.dim, equals('\x1B[2m'));
        });

        test('inverse is always ESC[7m', () {
          expect(preset.inverse, equals('\x1B[7m'));
        });

        test('gray is always ESC[90m', () {
          expect(preset.gray, equals('\x1B[90m'));
        });

        test('copyWith produces a valid instance', () {
          final copy = preset.copyWith(accent: '\x1B[99m');
          expect(copy.accent, equals('\x1B[99m'));
          expect(copy.reset, equals(preset.reset));
        });
      });
    }
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Preset-specific color values
  // ══════════════════════════════════════════════════════════════════════════

  group('preset-specific values', () {
    group('dark', () {
      const c = TerminalColors.dark;

      test('accent is cyan', () => expect(c.accent, equals('\x1B[36m')));
      test(
          'highlight is yellow', () => expect(c.highlight, equals('\x1B[33m')));
      test('selection is magenta',
          () => expect(c.selection, equals('\x1B[35m')));
      test('checkboxOn is green',
          () => expect(c.checkboxOn, equals('\x1B[32m')));
      test('info is cyan', () => expect(c.info, equals('\x1B[36m')));
      test('warn is yellow', () => expect(c.warn, equals('\x1B[33m')));
      test('error is red', () => expect(c.error, equals('\x1B[31m')));
    });

    group('matrix', () {
      const c = TerminalColors.matrix;

      test('accent is green', () => expect(c.accent, equals('\x1B[32m')));
      test('highlight is bright green',
          () => expect(c.highlight, equals('\x1B[92m')));
      test('selection is green', () => expect(c.selection, equals('\x1B[32m')));
      test('info is green', () => expect(c.info, equals('\x1B[32m')));
      test('warn is bright yellow', () => expect(c.warn, equals('\x1B[93m')));
      test('error is red', () => expect(c.error, equals('\x1B[31m')));
    });

    group('fire', () {
      const c = TerminalColors.fire;

      test('accent is red', () => expect(c.accent, equals('\x1B[31m')));
      test(
          'highlight is yellow', () => expect(c.highlight, equals('\x1B[33m')));
      test('selection is red', () => expect(c.selection, equals('\x1B[31m')));
      test('checkboxOn is red', () => expect(c.checkboxOn, equals('\x1B[31m')));
    });

    group('pastel', () {
      const c = TerminalColors.pastel;

      test('accent is bright magenta',
          () => expect(c.accent, equals('\x1B[95m')));
      test('highlight is bright yellow',
          () => expect(c.highlight, equals('\x1B[93m')));
      test('selection is bright blue',
          () => expect(c.selection, equals('\x1B[94m')));
      test('checkboxOn is bright cyan',
          () => expect(c.checkboxOn, equals('\x1B[96m')));
    });

    group('ocean', () {
      const c = TerminalColors.ocean;

      test('accent is bright blue', () => expect(c.accent, equals('\x1B[94m')));
      test('highlight is bright cyan',
          () => expect(c.highlight, equals('\x1B[96m')));
      test('selection is blue', () => expect(c.selection, equals('\x1B[34m')));
      test('keyAccent overrides default to cyan',
          () => expect(c.keyAccent, equals('\x1B[36m')));
    });

    group('monochrome', () {
      const c = TerminalColors.monochrome;

      test(
          'accent is bright white', () => expect(c.accent, equals('\x1B[97m')));
      test('highlight uses inverse for contrast',
          () => expect(c.highlight, equals('\x1B[7m')));
      test('selection is white', () => expect(c.selection, equals('\x1B[37m')));
      test('error combines underline and bright white',
          () => expect(c.error, equals('\x1B[4m\x1B[97m')));
    });

    group('neon', () {
      const c = TerminalColors.neon;

      test('accent is bright magenta',
          () => expect(c.accent, equals('\x1B[95m')));
      test('highlight is bright cyan',
          () => expect(c.highlight, equals('\x1B[96m')));
      test('selection is bright yellow',
          () => expect(c.selection, equals('\x1B[93m')));
    });

    group('arcane', () {
      const c = TerminalColors.arcane;

      test('uses 256-color for accent',
          () => expect(c.accent, equals('\x1B[38;5;141m')));
      test('uses 256-color for highlight',
          () => expect(c.highlight, equals('\x1B[38;5;220m')));
      test('uses 256-color for selection',
          () => expect(c.selection, equals('\x1B[38;5;99m')));
      test('uses 256-color for keyAccent',
          () => expect(c.keyAccent, equals('\x1B[38;5;178m')));
      test('uses 256-color for checkboxOn',
          () => expect(c.checkboxOn, equals('\x1B[38;5;220m')));
      test('uses 256-color for checkboxOff',
          () => expect(c.checkboxOff, equals('\x1B[38;5;240m')));
      test('uses 256-color for info',
          () => expect(c.info, equals('\x1B[38;5;147m')));
      test('uses 256-color for warn',
          () => expect(c.warn, equals('\x1B[38;5;214m')));
      test('uses 256-color for error',
          () => expect(c.error, equals('\x1B[38;5;160m')));
    });

    group('phantom', () {
      const c = TerminalColors.phantom;

      test('uses 256-color for accent',
          () => expect(c.accent, equals('\x1B[38;5;103m')));
      test('uses 256-color for highlight',
          () => expect(c.highlight, equals('\x1B[38;5;255m')));
      test('uses 256-color for selection',
          () => expect(c.selection, equals('\x1B[38;5;60m')));
      test('uses 256-color for keyAccent',
          () => expect(c.keyAccent, equals('\x1B[38;5;146m')));
      test('uses 256-color for checkboxOn',
          () => expect(c.checkboxOn, equals('\x1B[38;5;189m')));
      test('uses 256-color for checkboxOff',
          () => expect(c.checkboxOff, equals('\x1B[38;5;236m')));
      test('uses 256-color for info',
          () => expect(c.info, equals('\x1B[38;5;103m')));
      test('uses 256-color for warn',
          () => expect(c.warn, equals('\x1B[38;5;180m')));
      test('uses 256-color for error',
          () => expect(c.error, equals('\x1B[38;5;131m')));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Presets share invariant fields
  // ══════════════════════════════════════════════════════════════════════════

  group('invariant fields across all presets', () {
    final all = [
      TerminalColors.dark,
      TerminalColors.matrix,
      TerminalColors.fire,
      TerminalColors.pastel,
      TerminalColors.ocean,
      TerminalColors.monochrome,
      TerminalColors.neon,
      TerminalColors.arcane,
      TerminalColors.phantom,
    ];

    test('all presets share the same reset code', () {
      for (final c in all) {
        expect(c.reset, equals('\x1B[0m'));
      }
    });

    test('all presets share the same bold code', () {
      for (final c in all) {
        expect(c.bold, equals('\x1B[1m'));
      }
    });

    test('all presets share the same dim code', () {
      for (final c in all) {
        expect(c.dim, equals('\x1B[2m'));
      }
    });

    test('all presets share the same gray code', () {
      for (final c in all) {
        expect(c.gray, equals('\x1B[90m'));
      }
    });

    test('all presets share the same inverse code', () {
      for (final c in all) {
        expect(c.inverse, equals('\x1B[7m'));
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Each preset is distinct
  // ══════════════════════════════════════════════════════════════════════════

  group('presets are distinct', () {
    final presets = <String, TerminalColors>{
      'dark': TerminalColors.dark,
      'matrix': TerminalColors.matrix,
      'fire': TerminalColors.fire,
      'pastel': TerminalColors.pastel,
      'ocean': TerminalColors.ocean,
      'monochrome': TerminalColors.monochrome,
      'neon': TerminalColors.neon,
      'arcane': TerminalColors.arcane,
      'phantom': TerminalColors.phantom,
    };

    test('each preset has a unique (accent, highlight, selection) triple', () {
      final triples = presets.values
          .map((c) => '${c.accent}|${c.highlight}|${c.selection}')
          .toSet();
      expect(triples.length, equals(presets.length));
    });

    test('each preset has a unique accent+selection pair', () {
      final pairs =
          presets.values.map((c) => '${c.accent}|${c.selection}').toSet();
      expect(pairs.length, equals(presets.length));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Integration with stripAnsi
  // ══════════════════════════════════════════════════════════════════════════

  group('integration with text utilities', () {
    test('stripAnsi removes all preset color fields', () {
      final presets = [
        TerminalColors.dark,
        TerminalColors.matrix,
        TerminalColors.arcane,
        TerminalColors.phantom,
      ];
      for (final c in presets) {
        for (final field in _allFields(c)) {
          final styled = '${field}Hello${c.reset}';
          expect(stripAnsi(styled), equals('Hello'));
        }
      }
    });

    test('visibleLength is correct for text styled with preset colors', () {
      final c = TerminalColors.arcane;
      final styled = '${c.accent}Test${c.reset}';
      expect(visibleLength(styled), equals(4));
    });

    test('nested bold + color strips cleanly', () {
      final c = TerminalColors.neon;
      final styled = '${c.bold}${c.accent}Neon${c.reset}';
      expect(stripAnsi(styled), equals('Neon'));
      expect(visibleLength(styled), equals(4));
    });

    test('monochrome error (underline + bright white) strips cleanly', () {
      final c = TerminalColors.monochrome;
      final styled = '${c.error}Fail${c.reset}';
      expect(stripAnsi(styled), equals('Fail'));
      expect(visibleLength(styled), equals(4));
    });
  });
}
