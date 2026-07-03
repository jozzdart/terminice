import 'package:test/test.dart';
import 'package:terminice/terminice.dart';

import 'mock_terminal.dart';

void main() {
  group('Terminice API', () {
    setUp(() {
      // Reset to clean state before each test
      TerminalContext.reset();
    });

    tearDown(() {
      // Clean up after each test
      TerminalContext.reset();
    });

    group('Constructor', () {
      test('creates with default theme', () {
        final t = Terminice();
        expect(t.defaultTheme, equals(PromptTheme.dark));
        expect(t.baseTheme, equals(PromptTheme.dark));
      });

      test('creates with custom theme', () {
        final t = Terminice(defaultTheme: PromptTheme.fire);
        expect(t.defaultTheme, equals(PromptTheme.fire));
        expect(t.baseTheme, equals(PromptTheme.fire));
      });

      test('creates with explicit config', () {
        const config = TerminiceConfig(
          baseTheme: PromptTheme.fire,
          featureOverride: DisplayFeatures.compact,
          compatibility: TerminalCompatibility.basic,
          fallbackMode: TerminiceFallbackMode.auto,
        );

        final t = Terminice(
          defaultTheme: PromptTheme.ocean,
          config: config,
        );

        expect(t.configuration, same(config));
        expect(t.baseTheme, equals(PromptTheme.fire));
        expect(t.featureOverride, equals(DisplayFeatures.compact));
        expect(t.compatibility, equals(TerminalCompatibility.basic));
        expect(t.fallbackMode, equals(TerminiceFallbackMode.auto));
      });

      test('creates with null terminal (uses default)', () {
        final t = Terminice(terminal: null);
        expect(t.terminal, isNull);
      });

      test('creates with custom terminal', () {
        final mock = MockTerminal();
        final t = Terminice(terminal: mock);
        expect(t.terminal, same(mock));
      });

      test('setting terminal in constructor updates TerminalContext', () {
        final mock = MockTerminal();
        Terminice(terminal: mock);
        expect(TerminalContext.current, same(mock));
      });
    });

    group('withTerminal', () {
      test('returns new instance with terminal', () {
        final mock = MockTerminal();
        final original = Terminice();
        final withTerm = original.withTerminal(mock);

        expect(withTerm.terminal, same(mock));
        expect(original.terminal, isNull);
      });

      test('preserves theme', () {
        final mock = MockTerminal();
        final original = Terminice(defaultTheme: PromptTheme.neon);
        final withTerm = original.withTerminal(mock);

        expect(withTerm.defaultTheme, equals(PromptTheme.neon));
        expect(withTerm.baseTheme, equals(PromptTheme.neon));
      });

      test('preserves config', () {
        final mock = MockTerminal();
        final original = terminice.fire.compact.legacy.autoFallback;
        final withTerm = original.withTerminal(mock);

        expect(withTerm.terminal, same(mock));
        expect(withTerm.baseTheme, equals(PromptTheme.fire));
        expect(withTerm.featureOverride, equals(DisplayFeatures.compact));
        expect(withTerm.compatibility, equals(TerminalCompatibility.legacy));
        expect(withTerm.fallbackMode, equals(TerminiceFallbackMode.auto));
      });

      test('sets TerminalContext when created', () {
        final mock = MockTerminal();
        terminice.withTerminal(mock);
        expect(TerminalContext.current, same(mock));
      });

      test('chaining withTerminal creates independent instances', () {
        final mock1 = MockTerminal();
        final mock2 = MockTerminal();

        final t1 = terminice.withTerminal(mock1);
        final t2 = terminice.withTerminal(mock2);

        expect(t1.terminal, same(mock1));
        expect(t2.terminal, same(mock2));
      });
    });

    group('themed', () {
      test('returns new instance with theme', () {
        final original = Terminice();
        final themed = original.themed(PromptTheme.matrix);

        expect(themed.defaultTheme, equals(PromptTheme.matrix));
        expect(themed.baseTheme, equals(PromptTheme.matrix));
      });

      test('preserves terminal', () {
        final mock = MockTerminal();
        final original = Terminice(terminal: mock);
        final themed = original.themed(PromptTheme.fire);

        expect(themed.terminal, same(mock));
      });

      test('themed and withTerminal can be chained', () {
        final mock = MockTerminal();
        final result = terminice.withTerminal(mock).fire;

        expect(result.terminal, same(mock));
        expect(result.defaultTheme, equals(PromptTheme.fire));
      });

      test('preserves compatibility, fallback mode, and display override', () {
        final mock = MockTerminal();
        final original = Terminice(terminal: mock).compact.legacy.autoFallback;
        final result = original.themed(PromptTheme.ocean);

        expect(result.terminal, same(mock));
        expect(result.baseTheme, equals(PromptTheme.ocean));
        expect(result.featureOverride, equals(DisplayFeatures.compact));
        expect(result.compatibility, equals(TerminalCompatibility.legacy));
        expect(result.fallbackMode, equals(TerminiceFallbackMode.auto));
        expect(result.defaultTheme.colors, equals(TerminalColors.none));
        expect(result.defaultTheme.glyphs, equals(TerminalGlyphs.ascii));
        expect(result.defaultTheme.features.hintStyle, equals(HintStyle.none));
      });
    });

    group('TerminiceConfig', () {
      test('defaults preserve existing Terminice behavior', () {
        const config = TerminiceConfig();

        expect(config.baseTheme, equals(PromptTheme.dark));
        expect(config.featureOverride, isNull);
        expect(config.compatibility, equals(TerminalCompatibility.modern));
        expect(config.fallbackMode, equals(TerminiceFallbackMode.interactive));
        expect(config.effectiveTheme, equals(PromptTheme.dark));
      });

      test('effective theme applies feature override before compatibility', () {
        const config = TerminiceConfig(
          baseTheme: PromptTheme.ocean,
          featureOverride: DisplayFeatures.verbose,
          compatibility: TerminalCompatibility.basic,
        );

        final theme = config.effectiveTheme;

        expect(theme.colors, equals(TerminalColors.ocean));
        expect(theme.glyphs, equals(TerminalGlyphs.ascii));
        expect(theme.features.showBorders, isTrue);
        expect(theme.features.boldTitles, isTrue);
        expect(theme.features.useInverseHighlight, isFalse);
        expect(theme.features.showConnector, isFalse);
        expect(theme.features.hintStyle, equals(HintStyle.inline));
      });

      test('legacy compatibility strips colors and rich display', () {
        const config = TerminiceConfig(
          baseTheme: PromptTheme.fire,
          featureOverride: DisplayFeatures.verbose,
          compatibility: TerminalCompatibility.legacy,
        );

        final theme = config.effectiveTheme;

        expect(theme.colors, equals(TerminalColors.none));
        expect(theme.glyphs, equals(TerminalGlyphs.ascii));
        expect(theme.features.showBorders, isFalse);
        expect(theme.features.boldTitles, isFalse);
        expect(theme.features.useInverseHighlight, isFalse);
        expect(theme.features.showConnector, isFalse);
        expect(theme.features.hintStyle, equals(HintStyle.none));
      });

      test('copyWith can clear a feature override', () {
        const config = TerminiceConfig(
          baseTheme: PromptTheme.fire,
          featureOverride: DisplayFeatures.compact,
        );

        final cleared = config.copyWith(clearFeatureOverride: true);

        expect(cleared.baseTheme, equals(PromptTheme.fire));
        expect(cleared.featureOverride, isNull);
        expect(cleared.effectiveTheme, equals(PromptTheme.fire));
      });
    });

    group('Fallback modes', () {
      test('interactive never requests fallback', () {
        final mock = MockTerminal();

        expect(
          TerminiceFallbackMode.interactive.shouldUseFallback(mock),
          isFalse,
        );
      });

      test('fallback always requests fallback', () {
        final mock = MockTerminal();

        expect(
          TerminiceFallbackMode.fallback.shouldUseFallback(mock),
          isTrue,
        );
      });

      test('auto requests fallback when input is not a terminal', () {
        final mock = MockTerminal();
        mock.mockInput.setHasTerminal(false);

        expect(TerminiceFallbackMode.auto.shouldUseFallback(mock), isTrue);
      });

      test('auto requests fallback when output is not a terminal', () {
        final mock = MockTerminal();
        mock.mockOutput.setHasTerminal(false);

        expect(TerminiceFallbackMode.auto.shouldUseFallback(mock), isTrue);
      });

      test('auto keeps rich prompts when input and output are terminals', () {
        final mock = MockTerminal();

        expect(TerminiceFallbackMode.auto.shouldUseFallback(mock), isFalse);
      });

      test('Terminice exposes fallback decision for preserved terminal', () {
        final mock = MockTerminal();
        mock.mockOutput.setHasTerminal(false);

        final t = Terminice(terminal: mock).autoFallback;

        expect(t.terminal, same(mock));
        expect(t.shouldUseFallback, isTrue);
      });
    });

    group('Theme presets', () {
      test('dark preset', () {
        expect(terminice.dark.defaultTheme, equals(PromptTheme.dark));
      });

      test('matrix preset', () {
        expect(terminice.matrix.defaultTheme, equals(PromptTheme.matrix));
      });

      test('fire preset', () {
        expect(terminice.fire.defaultTheme, equals(PromptTheme.fire));
      });

      test('pastel preset', () {
        expect(terminice.pastel.defaultTheme, equals(PromptTheme.pastel));
      });

      test('ocean preset', () {
        expect(terminice.ocean.defaultTheme, equals(PromptTheme.ocean));
      });

      test('monochrome preset', () {
        expect(
            terminice.monochrome.defaultTheme, equals(PromptTheme.monochrome));
      });

      test('neon preset', () {
        expect(terminice.neon.defaultTheme, equals(PromptTheme.neon));
      });

      test('arcane preset', () {
        expect(terminice.arcane.defaultTheme, equals(PromptTheme.arcane));
      });

      test('phantom preset', () {
        expect(terminice.phantom.defaultTheme, equals(PromptTheme.phantom));
      });

      test('theme presets preserve terminal', () {
        final mock = MockTerminal();
        final withTerm = terminice.withTerminal(mock);

        expect(withTerm.dark.terminal, same(mock));
        expect(withTerm.matrix.terminal, same(mock));
        expect(withTerm.fire.terminal, same(mock));
        expect(withTerm.pastel.terminal, same(mock));
        expect(withTerm.ocean.terminal, same(mock));
        expect(withTerm.monochrome.terminal, same(mock));
        expect(withTerm.neon.terminal, same(mock));
        expect(withTerm.arcane.terminal, same(mock));
        expect(withTerm.phantom.terminal, same(mock));
      });

      test('display modes preserve active colors and glyphs', () {
        final compactOcean = terminice.ocean.compact;
        final minimalFire = terminice.fire.minimal;
        final verbosePhantom = terminice.phantom.verbose;

        expect(compactOcean.defaultTheme.colors, equals(TerminalColors.ocean));
        expect(compactOcean.defaultTheme.glyphs, equals(TerminalGlyphs.dotted));
        expect(
          compactOcean.defaultTheme.features,
          equals(DisplayFeatures.compact),
        );

        expect(minimalFire.defaultTheme.colors, equals(TerminalColors.fire));
        expect(minimalFire.defaultTheme.glyphs, equals(TerminalGlyphs.double));
        expect(
          minimalFire.defaultTheme.features,
          equals(DisplayFeatures.minimal),
        );

        expect(
          verbosePhantom.defaultTheme.colors,
          equals(TerminalColors.phantom),
        );
        expect(
          verbosePhantom.defaultTheme.glyphs,
          equals(TerminalGlyphs.phantom),
        );
        expect(
          verbosePhantom.defaultTheme.features,
          equals(DisplayFeatures.verbose),
        );
      });

      test('color and display chaining is order-insensitive', () {
        final oceanCompact = terminice.ocean.compact;
        final compactOcean = terminice.compact.ocean;

        expect(oceanCompact.baseTheme, equals(PromptTheme.ocean));
        expect(compactOcean.baseTheme, equals(PromptTheme.ocean));
        expect(
          oceanCompact.featureOverride,
          equals(DisplayFeatures.compact),
        );
        expect(
          compactOcean.featureOverride,
          equals(DisplayFeatures.compact),
        );
        expect(
          oceanCompact.defaultTheme.colors,
          equals(compactOcean.defaultTheme.colors),
        );
        expect(
          oceanCompact.defaultTheme.glyphs,
          equals(compactOcean.defaultTheme.glyphs),
        );
        expect(
          oceanCompact.defaultTheme.features,
          equals(compactOcean.defaultTheme.features),
        );
      });

      test('color presets preserve compatibility and fallback settings', () {
        final configured = terminice.compact.legacy.autoFallback.ocean;

        expect(configured.baseTheme, equals(PromptTheme.ocean));
        expect(configured.featureOverride, equals(DisplayFeatures.compact));
        expect(configured.compatibility, equals(TerminalCompatibility.legacy));
        expect(configured.fallbackMode, equals(TerminiceFallbackMode.auto));
        expect(configured.defaultTheme.colors, equals(TerminalColors.none));
        expect(configured.defaultTheme.glyphs, equals(TerminalGlyphs.ascii));
        expect(
            configured.defaultTheme.features.hintStyle, equals(HintStyle.none));
      });

      test('custom colors preserve display override', () {
        final themed = terminice.compact.withColors(TerminalColors.neon);

        expect(themed.baseTheme.colors, equals(TerminalColors.neon));
        expect(themed.featureOverride, equals(DisplayFeatures.compact));
        expect(themed.defaultTheme.colors, equals(TerminalColors.neon));
        expect(themed.defaultTheme.features, equals(DisplayFeatures.compact));
      });
    });

    group('activate', () {
      test('sets terminal as current context', () {
        final mock = MockTerminal();
        final t = Terminice(terminal: mock);

        // Change to something else
        TerminalContext.current = MockTerminal();

        // Re-activate
        t.activate();

        expect(TerminalContext.current, same(mock));
      });

      test('resets to default when terminal is null', () {
        final t = Terminice(terminal: null);
        TerminalContext.current = MockTerminal();

        t.activate();

        expect(TerminalContext.current, isA<DartTerminal>());
      });

      test('allows switching between instances', () {
        final mock1 = MockTerminal();
        final mock2 = MockTerminal();

        final t1 = Terminice(terminal: mock1);
        final t2 = Terminice(terminal: mock2);

        t1.activate();
        expect(TerminalContext.current, same(mock1));

        t2.activate();
        expect(TerminalContext.current, same(mock2));

        t1.activate();
        expect(TerminalContext.current, same(mock1));
      });
    });

    group('resetTerminal', () {
      test('resets to default DartTerminal', () {
        TerminalContext.current = MockTerminal();

        Terminice.resetTerminal();

        expect(TerminalContext.current, isA<DartTerminal>());
      });

      test('can be called multiple times safely', () {
        Terminice.resetTerminal();
        Terminice.resetTerminal();
        Terminice.resetTerminal();

        expect(TerminalContext.current, isA<DartTerminal>());
      });
    });

    group('currentTerminal', () {
      test('returns current TerminalContext terminal', () {
        final mock = MockTerminal();
        TerminalContext.current = mock;

        expect(Terminice.currentTerminal, same(mock));
      });

      test('returns DartTerminal by default', () {
        TerminalContext.reset();
        expect(Terminice.currentTerminal, isA<DartTerminal>());
      });
    });

    group('Global terminice instance', () {
      test('exists and uses default theme', () {
        expect(terminice.defaultTheme, equals(PromptTheme.dark));
      });

      test('has null terminal (uses default)', () {
        expect(terminice.terminal, isNull);
      });
    });
  });

  group('Terminal Integration', () {
    late MockTerminal mockTerminal;

    setUp(() {
      mockTerminal = MockTerminal();
      TerminalContext.reset();
    });

    tearDown(() {
      TerminalContext.reset();
    });

    test('output goes to custom terminal', () {
      TerminalContext.current = mockTerminal;
      TerminalContext.output.writeln('Test output');

      expect(mockTerminal.mockOutput.contains('Test output'), isTrue);
    });

    test('creating Terminice with terminal routes output there', () {
      Terminice(terminal: mockTerminal);

      // Now terminal context should use mock
      TerminalContext.output.writeln('Via context');

      expect(mockTerminal.mockOutput.contains('Via context'), isTrue);
    });

    test('withTerminal routes output to new terminal', () {
      final mock1 = MockTerminal();
      final mock2 = MockTerminal();

      terminice.withTerminal(mock1);
      TerminalContext.output.write('To mock1');

      terminice.withTerminal(mock2);
      TerminalContext.output.write('To mock2');

      expect(mock1.mockOutput.contains('To mock1'), isTrue);
      expect(mock2.mockOutput.contains('To mock2'), isTrue);
    });

    test('terminal dimensions come from mock', () {
      mockTerminal.mockOutput.setDimensions(columns: 200, rows: 100);
      TerminalContext.current = mockTerminal;

      expect(TerminalContext.output.terminalColumns, equals(200));
      expect(TerminalContext.output.terminalLines, equals(100));
    });

    test('terminal input modes can be controlled', () {
      TerminalContext.current = mockTerminal;

      TerminalContext.input.echoMode = false;
      TerminalContext.input.lineMode = false;

      expect(mockTerminal.mockInput.echoMode, isFalse);
      expect(mockTerminal.mockInput.lineMode, isFalse);
    });
  });

  group('Export Verification', () {
    test('Terminal is exported', () {
      expect(Terminal, isNotNull);
    });

    test('TerminalInput is exported', () {
      expect(TerminalInput, isNotNull);
    });

    test('TerminalOutput is exported', () {
      expect(TerminalOutput, isNotNull);
    });

    test('DartTerminal is exported', () {
      expect(DartTerminal, isNotNull);
    });

    test('DartTerminalInput is exported', () {
      expect(DartTerminalInput, isNotNull);
    });

    test('DartTerminalOutput is exported', () {
      expect(DartTerminalOutput, isNotNull);
    });

    test('TerminalContext is exported', () {
      expect(TerminalContext, isNotNull);
    });

    test('TerminalCompatibility is exported', () {
      expect(TerminalCompatibility.modern, isNotNull);
    });

    test('TerminalColors.none is exported', () {
      expect(TerminalColors.none.reset, isEmpty);
    });

    test('TerminiceConfig is exported', () {
      expect(const TerminiceConfig(), isA<TerminiceConfig>());
    });

    test('TerminiceFallbackMode is exported', () {
      expect(TerminiceFallbackMode.interactive, isNotNull);
    });
  });

  group('Complex Workflows', () {
    setUp(() {
      TerminalContext.reset();
    });

    tearDown(() {
      TerminalContext.reset();
    });

    test('theme + terminal + switch workflow', () {
      final testTerminal = MockTerminal();

      // Create themed instance with custom terminal
      final fireTerminice = terminice.fire.withTerminal(testTerminal);

      expect(fireTerminice.defaultTheme, equals(PromptTheme.fire));
      expect(fireTerminice.terminal, same(testTerminal));
      expect(TerminalContext.current, same(testTerminal));

      // Switch to different terminal
      final anotherTerminal = MockTerminal();
      final oceanTerminice = fireTerminice.ocean.withTerminal(anotherTerminal);

      expect(oceanTerminice.defaultTheme, equals(PromptTheme.ocean));
      expect(oceanTerminice.terminal, same(anotherTerminal));

      // Original should still have its terminal
      expect(fireTerminice.terminal, same(testTerminal));

      // Re-activate original
      fireTerminice.activate();
      expect(TerminalContext.current, same(testTerminal));
    });

    test('multiple independent terminice instances', () {
      final term1 = MockTerminal();
      final term2 = MockTerminal();
      final term3 = MockTerminal();

      final t1 = Terminice(defaultTheme: PromptTheme.dark, terminal: term1);
      final t2 = Terminice(defaultTheme: PromptTheme.fire, terminal: term2);
      final t3 = Terminice(defaultTheme: PromptTheme.neon, terminal: term3);

      // Last one should be active
      expect(TerminalContext.current, same(term3));

      // Activate each and verify
      t1.activate();
      expect(TerminalContext.current, same(term1));

      t2.activate();
      expect(TerminalContext.current, same(term2));

      t3.activate();
      expect(TerminalContext.current, same(term3));

      // Verify all themes are preserved
      expect(t1.defaultTheme, equals(PromptTheme.dark));
      expect(t2.defaultTheme, equals(PromptTheme.fire));
      expect(t3.defaultTheme, equals(PromptTheme.neon));
    });

    test('reset and start fresh', () {
      final mock = MockTerminal();
      terminice.withTerminal(mock);

      expect(TerminalContext.current, same(mock));

      Terminice.resetTerminal();

      expect(TerminalContext.current, isA<DartTerminal>());
      expect(TerminalContext.current, isNot(same(mock)));
    });
  });
}
