import 'package:termistyle/termistyle.dart';
import 'package:test/test.dart';

List<String> _allFields(TerminalColors colors) {
  return [
    colors.reset,
    colors.bold,
    colors.dim,
    colors.gray,
    colors.accent,
    colors.keyAccent,
    colors.highlight,
    colors.selection,
    colors.checkboxOn,
    colors.checkboxOff,
    colors.inverse,
    colors.info,
    colors.warn,
    colors.error,
  ];
}

void main() {
  group('TerminalColors plain palettes', () {
    test('none disables every ANSI field', () {
      expect(_allFields(TerminalColors.none), everyElement(isEmpty));
    });

    test('plain exposes the same no-op field values', () {
      expect(
        _allFields(TerminalColors.plain),
        equals(_allFields(TerminalColors.none)),
      );
      expect(identical(TerminalColors.plain, TerminalColors.none), isTrue);
    });
  });

  group('TerminalCompatibility', () {
    test('modern preserves the original theme', () {
      final theme = PromptTheme.ocean;

      final compatible = theme.withCompatibility(TerminalCompatibility.modern);

      expect(identical(compatible, theme), isTrue);
    });

    test('basic keeps colors while using ASCII glyphs and simpler features',
        () {
      const theme = PromptTheme(
        colors: TerminalColors.neon,
        glyphs: TerminalGlyphs.arcane,
        features: DisplayFeatures.verbose,
      );

      final compatible = theme.withCompatibility(TerminalCompatibility.basic);

      expect(identical(compatible.colors, theme.colors), isTrue);
      expect(identical(compatible.glyphs, TerminalGlyphs.ascii), isTrue);
      expect(compatible.showBorders, isTrue);
      expect(compatible.boldTitles, isTrue);
      expect(compatible.useInverseHighlight, isFalse);
      expect(compatible.showConnector, isFalse);
      expect(compatible.hintStyle, HintStyle.inline);
    });

    test('legacy uses ASCII glyphs, no ANSI colors, and no hints', () {
      final compatible =
          PromptTheme.arcane.withCompatibility(TerminalCompatibility.legacy);

      expect(_allFields(compatible.colors), everyElement(isEmpty));
      expect(identical(compatible.glyphs, TerminalGlyphs.ascii), isTrue);
      expect(compatible.showBorders, isFalse);
      expect(compatible.boldTitles, isFalse);
      expect(compatible.useInverseHighlight, isFalse);
      expect(compatible.showConnector, isFalse);
      expect(compatible.hintStyle, HintStyle.none);
    });
  });
}
