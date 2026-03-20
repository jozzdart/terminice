import 'package:test/test.dart';
import 'package:termistyle/termistyle.dart';

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // HintStyle enum
  // ══════════════════════════════════════════════════════════════════════════

  group('HintStyle', () {
    test('has exactly 4 values', () {
      expect(HintStyle.values.length, equals(4));
    });

    test('contains all expected members', () {
      expect(HintStyle.values, contains(HintStyle.bullets));
      expect(HintStyle.values, contains(HintStyle.grid));
      expect(HintStyle.values, contains(HintStyle.inline));
      expect(HintStyle.values, contains(HintStyle.none));
    });

    test('values are in the documented order', () {
      expect(HintStyle.values[0], equals(HintStyle.bullets));
      expect(HintStyle.values[1], equals(HintStyle.grid));
      expect(HintStyle.values[2], equals(HintStyle.inline));
      expect(HintStyle.values[3], equals(HintStyle.none));
    });

    test('each value has a unique index', () {
      final indices = HintStyle.values.map((v) => v.index).toSet();
      expect(indices.length, equals(HintStyle.values.length));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Default constructor
  // ══════════════════════════════════════════════════════════════════════════

  group('default constructor', () {
    test('defaults showBorders to true', () {
      expect(const DisplayFeatures().showBorders, isTrue);
    });

    test('defaults boldTitles to true', () {
      expect(const DisplayFeatures().boldTitles, isTrue);
    });

    test('defaults useInverseHighlight to true', () {
      expect(const DisplayFeatures().useInverseHighlight, isTrue);
    });

    test('defaults showConnector to false', () {
      expect(const DisplayFeatures().showConnector, isFalse);
    });

    test('defaults hintStyle to bullets', () {
      expect(const DisplayFeatures().hintStyle, equals(HintStyle.bullets));
    });

    test('accepts all custom values', () {
      final f = DisplayFeatures(
        showBorders: false,
        boldTitles: false,
        useInverseHighlight: false,
        showConnector: true,
        hintStyle: HintStyle.grid,
      );
      expect(f.showBorders, isFalse);
      expect(f.boldTitles, isFalse);
      expect(f.useInverseHighlight, isFalse);
      expect(f.showConnector, isTrue);
      expect(f.hintStyle, equals(HintStyle.grid));
    });

    test('accepts partial overrides', () {
      final f = DisplayFeatures(showBorders: false, hintStyle: HintStyle.none);
      expect(f.showBorders, isFalse);
      expect(f.boldTitles, isTrue);
      expect(f.useInverseHighlight, isTrue);
      expect(f.showConnector, isFalse);
      expect(f.hintStyle, equals(HintStyle.none));
    });

    test('is const-constructible', () {
      const f = DisplayFeatures(showBorders: false);
      expect(f.showBorders, isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // copyWith
  // ══════════════════════════════════════════════════════════════════════════

  group('copyWith', () {
    const base = DisplayFeatures(
      showBorders: true,
      boldTitles: true,
      useInverseHighlight: true,
      showConnector: false,
      hintStyle: HintStyle.bullets,
    );

    test('returns identical instance when no parameters are passed', () {
      final copy = base.copyWith();
      expect(copy.showBorders, equals(base.showBorders));
      expect(copy.boldTitles, equals(base.boldTitles));
      expect(copy.useInverseHighlight, equals(base.useInverseHighlight));
      expect(copy.showConnector, equals(base.showConnector));
      expect(copy.hintStyle, equals(base.hintStyle));
    });

    test('overrides showBorders only', () {
      final copy = base.copyWith(showBorders: false);
      expect(copy.showBorders, isFalse);
      expect(copy.boldTitles, equals(base.boldTitles));
      expect(copy.useInverseHighlight, equals(base.useInverseHighlight));
      expect(copy.showConnector, equals(base.showConnector));
      expect(copy.hintStyle, equals(base.hintStyle));
    });

    test('overrides boldTitles only', () {
      final copy = base.copyWith(boldTitles: false);
      expect(copy.boldTitles, isFalse);
      expect(copy.showBorders, equals(base.showBorders));
    });

    test('overrides useInverseHighlight only', () {
      final copy = base.copyWith(useInverseHighlight: false);
      expect(copy.useInverseHighlight, isFalse);
      expect(copy.showBorders, equals(base.showBorders));
    });

    test('overrides showConnector only', () {
      final copy = base.copyWith(showConnector: true);
      expect(copy.showConnector, isTrue);
      expect(copy.hintStyle, equals(base.hintStyle));
    });

    test('overrides hintStyle only', () {
      final copy = base.copyWith(hintStyle: HintStyle.grid);
      expect(copy.hintStyle, equals(HintStyle.grid));
      expect(copy.showBorders, equals(base.showBorders));
    });

    test('overrides multiple properties at once', () {
      final copy = base.copyWith(
        showBorders: false,
        boldTitles: false,
        hintStyle: HintStyle.none,
      );
      expect(copy.showBorders, isFalse);
      expect(copy.boldTitles, isFalse);
      expect(copy.hintStyle, equals(HintStyle.none));
      expect(copy.useInverseHighlight, equals(base.useInverseHighlight));
      expect(copy.showConnector, equals(base.showConnector));
    });

    test('overrides all properties at once', () {
      final copy = base.copyWith(
        showBorders: false,
        boldTitles: false,
        useInverseHighlight: false,
        showConnector: true,
        hintStyle: HintStyle.inline,
      );
      expect(copy.showBorders, isFalse);
      expect(copy.boldTitles, isFalse);
      expect(copy.useInverseHighlight, isFalse);
      expect(copy.showConnector, isTrue);
      expect(copy.hintStyle, equals(HintStyle.inline));
    });

    test('does not mutate the original instance', () {
      base.copyWith(showBorders: false, hintStyle: HintStyle.none);
      expect(base.showBorders, isTrue);
      expect(base.hintStyle, equals(HintStyle.bullets));
    });

    test('chaining multiple copyWith calls works correctly', () {
      final result = base
          .copyWith(showBorders: false)
          .copyWith(boldTitles: false)
          .copyWith(hintStyle: HintStyle.grid);
      expect(result.showBorders, isFalse);
      expect(result.boldTitles, isFalse);
      expect(result.hintStyle, equals(HintStyle.grid));
      expect(result.useInverseHighlight, isTrue);
      expect(result.showConnector, isFalse);
    });

    test('setting same value via copyWith preserves it', () {
      final copy = base.copyWith(showBorders: true);
      expect(copy.showBorders, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Built-in preset: standard
  // ══════════════════════════════════════════════════════════════════════════

  group('standard preset', () {
    test('showBorders is true', () {
      expect(DisplayFeatures.standard.showBorders, isTrue);
    });

    test('boldTitles is true', () {
      expect(DisplayFeatures.standard.boldTitles, isTrue);
    });

    test('useInverseHighlight is true', () {
      expect(DisplayFeatures.standard.useInverseHighlight, isTrue);
    });

    test('showConnector is false', () {
      expect(DisplayFeatures.standard.showConnector, isFalse);
    });

    test('hintStyle is bullets', () {
      expect(DisplayFeatures.standard.hintStyle, equals(HintStyle.bullets));
    });

    test('matches default constructor', () {
      const def = DisplayFeatures();
      expect(DisplayFeatures.standard.showBorders, equals(def.showBorders));
      expect(DisplayFeatures.standard.boldTitles, equals(def.boldTitles));
      expect(DisplayFeatures.standard.useInverseHighlight,
          equals(def.useInverseHighlight));
      expect(DisplayFeatures.standard.showConnector, equals(def.showConnector));
      expect(DisplayFeatures.standard.hintStyle, equals(def.hintStyle));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Built-in preset: minimal
  // ══════════════════════════════════════════════════════════════════════════

  group('minimal preset', () {
    test('showBorders is false', () {
      expect(DisplayFeatures.minimal.showBorders, isFalse);
    });

    test('boldTitles is false', () {
      expect(DisplayFeatures.minimal.boldTitles, isFalse);
    });

    test('useInverseHighlight is false', () {
      expect(DisplayFeatures.minimal.useInverseHighlight, isFalse);
    });

    test('showConnector is false', () {
      expect(DisplayFeatures.minimal.showConnector, isFalse);
    });

    test('hintStyle is inline', () {
      expect(DisplayFeatures.minimal.hintStyle, equals(HintStyle.inline));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Built-in preset: compact
  // ══════════════════════════════════════════════════════════════════════════

  group('compact preset', () {
    test('showBorders is true', () {
      expect(DisplayFeatures.compact.showBorders, isTrue);
    });

    test('boldTitles is true', () {
      expect(DisplayFeatures.compact.boldTitles, isTrue);
    });

    test('useInverseHighlight is true (default)', () {
      expect(DisplayFeatures.compact.useInverseHighlight, isTrue);
    });

    test('showConnector is false (default)', () {
      expect(DisplayFeatures.compact.showConnector, isFalse);
    });

    test('hintStyle is none', () {
      expect(DisplayFeatures.compact.hintStyle, equals(HintStyle.none));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Built-in preset: verbose
  // ══════════════════════════════════════════════════════════════════════════

  group('verbose preset', () {
    test('showBorders is true', () {
      expect(DisplayFeatures.verbose.showBorders, isTrue);
    });

    test('boldTitles is true', () {
      expect(DisplayFeatures.verbose.boldTitles, isTrue);
    });

    test('useInverseHighlight is true (default)', () {
      expect(DisplayFeatures.verbose.useInverseHighlight, isTrue);
    });

    test('showConnector is true', () {
      expect(DisplayFeatures.verbose.showConnector, isTrue);
    });

    test('hintStyle is grid', () {
      expect(DisplayFeatures.verbose.hintStyle, equals(HintStyle.grid));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Built-in preset: clean
  // ══════════════════════════════════════════════════════════════════════════

  group('clean preset', () {
    test('showBorders is true', () {
      expect(DisplayFeatures.clean.showBorders, isTrue);
    });

    test('boldTitles is true', () {
      expect(DisplayFeatures.clean.boldTitles, isTrue);
    });

    test('useInverseHighlight is true (default)', () {
      expect(DisplayFeatures.clean.useInverseHighlight, isTrue);
    });

    test('showConnector is false (default)', () {
      expect(DisplayFeatures.clean.showConnector, isFalse);
    });

    test('hintStyle is inline', () {
      expect(DisplayFeatures.clean.hintStyle, equals(HintStyle.inline));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Built-in preset: focus
  // ══════════════════════════════════════════════════════════════════════════

  group('focus preset', () {
    test('showBorders is true', () {
      expect(DisplayFeatures.focus.showBorders, isTrue);
    });

    test('boldTitles is true', () {
      expect(DisplayFeatures.focus.boldTitles, isTrue);
    });

    test('useInverseHighlight is true (default)', () {
      expect(DisplayFeatures.focus.useInverseHighlight, isTrue);
    });

    test('showConnector is false (default)', () {
      expect(DisplayFeatures.focus.showConnector, isFalse);
    });

    test('hintStyle is none', () {
      expect(DisplayFeatures.focus.hintStyle, equals(HintStyle.none));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Preset differentiation
  // ══════════════════════════════════════════════════════════════════════════

  group('preset differentiation', () {
    test('minimal is the only preset with showBorders false', () {
      final presets = [
        DisplayFeatures.standard,
        DisplayFeatures.minimal,
        DisplayFeatures.compact,
        DisplayFeatures.verbose,
        DisplayFeatures.clean,
        DisplayFeatures.focus,
      ];
      final bordersOff = presets.where((p) => !p.showBorders).toList();
      expect(bordersOff.length, equals(1));
      expect(bordersOff.first.hintStyle, equals(HintStyle.inline));
    });

    test('minimal is the only preset with boldTitles false', () {
      final presets = [
        DisplayFeatures.standard,
        DisplayFeatures.minimal,
        DisplayFeatures.compact,
        DisplayFeatures.verbose,
        DisplayFeatures.clean,
        DisplayFeatures.focus,
      ];
      final boldOff = presets.where((p) => !p.boldTitles).toList();
      expect(boldOff.length, equals(1));
    });

    test('verbose is the only preset with showConnector true', () {
      final presets = [
        DisplayFeatures.standard,
        DisplayFeatures.minimal,
        DisplayFeatures.compact,
        DisplayFeatures.verbose,
        DisplayFeatures.clean,
        DisplayFeatures.focus,
      ];
      final connectorOn = presets.where((p) => p.showConnector).toList();
      expect(connectorOn.length, equals(1));
      expect(connectorOn.first.hintStyle, equals(HintStyle.grid));
    });

    test('every HintStyle value is used by at least one preset', () {
      final presets = [
        DisplayFeatures.standard,
        DisplayFeatures.minimal,
        DisplayFeatures.compact,
        DisplayFeatures.verbose,
        DisplayFeatures.clean,
        DisplayFeatures.focus,
      ];
      final usedStyles = presets.map((p) => p.hintStyle).toSet();
      expect(usedStyles, contains(HintStyle.bullets));
      expect(usedStyles, contains(HintStyle.grid));
      expect(usedStyles, contains(HintStyle.inline));
      expect(usedStyles, contains(HintStyle.none));
    });

    test('compact and focus share the same hintStyle', () {
      expect(DisplayFeatures.compact.hintStyle,
          equals(DisplayFeatures.focus.hintStyle));
    });

    test('minimal and clean share the same hintStyle', () {
      expect(DisplayFeatures.minimal.hintStyle,
          equals(DisplayFeatures.clean.hintStyle));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // copyWith on presets
  // ══════════════════════════════════════════════════════════════════════════

  group('copyWith on presets', () {
    test('can add borders to minimal', () {
      final custom = DisplayFeatures.minimal.copyWith(showBorders: true);
      expect(custom.showBorders, isTrue);
      expect(custom.boldTitles, isFalse);
      expect(custom.useInverseHighlight, isFalse);
      expect(custom.hintStyle, equals(HintStyle.inline));
    });

    test('can remove borders from standard', () {
      final custom = DisplayFeatures.standard.copyWith(showBorders: false);
      expect(custom.showBorders, isFalse);
      expect(custom.boldTitles, isTrue);
      expect(custom.hintStyle, equals(HintStyle.bullets));
    });

    test('can add connector to compact', () {
      final custom = DisplayFeatures.compact.copyWith(showConnector: true);
      expect(custom.showConnector, isTrue);
      expect(custom.hintStyle, equals(HintStyle.none));
    });

    test('can change hintStyle on verbose', () {
      final custom =
          DisplayFeatures.verbose.copyWith(hintStyle: HintStyle.bullets);
      expect(custom.hintStyle, equals(HintStyle.bullets));
      expect(custom.showConnector, isTrue);
    });

    test('can disable inverse highlight on focus', () {
      final custom =
          DisplayFeatures.focus.copyWith(useInverseHighlight: false);
      expect(custom.useInverseHighlight, isFalse);
      expect(custom.showBorders, isTrue);
      expect(custom.hintStyle, equals(HintStyle.none));
    });

    test('can transform clean into verbose-like', () {
      final custom = DisplayFeatures.clean.copyWith(
        showConnector: true,
        hintStyle: HintStyle.grid,
      );
      expect(custom.showBorders, isTrue);
      expect(custom.boldTitles, isTrue);
      expect(custom.showConnector, isTrue);
      expect(custom.hintStyle, equals(HintStyle.grid));
    });
  });
}
