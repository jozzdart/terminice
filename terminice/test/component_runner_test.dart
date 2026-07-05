import 'package:test/test.dart';
import 'package:terminice/terminice.dart';

import 'mock_terminal.dart';

void main() {
  setUp(TerminalContext.reset);
  tearDown(TerminalContext.reset);

  group('custom component runner', () {
    test('runComponent passes the configured context', () {
      final terminal = MockTerminal();
      terminal.mockOutput.setHasTerminal(false);
      final previous = MockTerminal();
      TerminalContext.current = previous;

      final terminice = Terminice(defaultTheme: PromptTheme.ocean)
          .compact
          .basic
          .autoFallback
          .withTerminal(terminal);
      TerminalContext.current = previous;

      final snapshot = terminice.runComponent(_ContextProbeComponent());

      expect(snapshot.terminice, same(terminice));
      expect(snapshot.configuration, same(terminice.configuration));
      expect(snapshot.theme, equals(terminice.defaultTheme));
      expect(snapshot.terminal, same(terminal));
      expect(snapshot.input, same(terminal.input));
      expect(snapshot.output, same(terminal.output));
      expect(snapshot.shouldUseFallback, equals(terminice.shouldUseFallback));
      expect(snapshot.activeTerminal, same(terminal));
      expect(snapshot.shouldUseFallback, isTrue);
    });

    test('runWithComponent adapts callbacks with concise syntax', () {
      final terminal = MockTerminal();
      final terminice = Terminice(defaultTheme: PromptTheme.fire)
          .fallback
          .withTerminal(terminal);

      final result = terminice.runWithComponent((context) {
        context.output.writeln('component callback');
        return context.runWithFallback(
          interactive: () => 'interactive',
          fallback: () => 'fallback:${context.theme.colors}',
        );
      });

      expect(result, equals('fallback:${PromptTheme.fire.colors}'));
      expect(terminal.mockOutput.contains('component callback'), isTrue);
    });

    test('TerminiceComponent.from creates reusable callback components', () {
      final terminal = MockTerminal();
      final terminice = terminiceFor(terminal);
      final component = TerminiceComponent<int>.from((context) {
        context.output.writeln('factory component');
        return context.terminal == terminal ? 7 : -1;
      });

      final result = terminice.runComponent(component);

      expect(result, equals(7));
      expect(terminal.mockOutput.contains('factory component'), isTrue);
    });

    test('captured terminal access survives global terminal changes', () {
      final terminal = MockTerminal();
      final intruder = MockTerminal();
      final terminice = terminiceFor(terminal);

      final result = terminice.runWithComponent((context) {
        expect(TerminalContext.current, same(terminal));

        context.output.writeln('captured before');
        TerminalContext.current = intruder;
        TerminalContext.output.writeln('global intruder');

        expect(context.terminal, same(terminal));
        expect(context.output, same(terminal.output));
        context.output.writeln('captured after');

        context.activate();
        expect(TerminalContext.current, same(terminal));

        TerminalContext.current = intruder;
        final activeResult = context.withActiveTerminal(() {
          expect(TerminalContext.current, same(terminal));
          TerminalContext.output.writeln('active terminal');
          return context.terminal;
        });

        expect(activeResult, same(terminal));
        expect(TerminalContext.current, same(intruder));
        return 'done';
      });

      expect(result, equals('done'));
      expect(terminal.mockOutput.contains('captured before'), isTrue);
      expect(terminal.mockOutput.contains('captured after'), isTrue);
      expect(terminal.mockOutput.contains('active terminal'), isTrue);
      expect(intruder.mockOutput.contains('global intruder'), isTrue);
      expect(intruder.mockOutput.contains('captured after'), isFalse);
    });

    test('runWithFallback uses the same fallback decision as Terminice', () {
      expect(
        _fallbackChoice(
          terminiceFor(MockTerminal()).interactive,
        ),
        equals('interactive:false'),
      );

      final autoInteractive = terminiceFor(MockTerminal()).autoFallback;
      expect(_fallbackChoice(autoInteractive), equals('interactive:false'));

      final nonInteractive = MockTerminal();
      nonInteractive.mockInput.setHasTerminal(false);
      nonInteractive.mockOutput.setHasTerminal(false);
      expect(
        _fallbackChoice(terminiceFor(nonInteractive).autoFallback),
        equals('fallback:true'),
      );

      final forcedFallback = terminiceFor(MockTerminal()).fallback;
      expect(_fallbackChoice(forcedFallback), equals('fallback:true'));
    });

    test('runWithFallback branches run with the captured terminal active', () {
      for (final scenario in <_FallbackScenario>[
        _FallbackScenario(
          label: 'interactive',
          terminice: terminiceFor(MockTerminal()).interactive,
          expected: 'interactive',
        ),
        _FallbackScenario(
          label: 'fallback',
          terminice: terminiceFor(MockTerminal()).fallback,
          expected: 'fallback',
        ),
      ]) {
        final componentTerminal = scenario.terminice.terminal as MockTerminal;
        final intruder = MockTerminal();

        final result = scenario.terminice.runWithComponent((context) {
          TerminalContext.current = intruder;

          return context.runWithFallback(
            interactive: () {
              expect(TerminalContext.current, same(componentTerminal));
              TerminalContext.output.writeln('${scenario.label}:interactive');
              return 'interactive';
            },
            fallback: () {
              expect(TerminalContext.current, same(componentTerminal));
              TerminalContext.output.writeln('${scenario.label}:fallback');
              return 'fallback';
            },
          );
        });

        expect(result, scenario.expected);
        expect(TerminalContext.current, same(intruder));
        expect(
          componentTerminal.outputSnapshot.plainText,
          contains('${scenario.label}:${scenario.expected}'),
        );
        expect(
          intruder.outputSnapshot.plainText,
          isNot(contains('${scenario.label}:${scenario.expected}')),
        );
      }
    });
  });
}

Terminice terminiceFor(MockTerminal terminal) {
  return Terminice().withTerminal(terminal);
}

String _fallbackChoice(Terminice terminice) {
  return terminice.runWithComponent(
    (context) {
      expect(context.shouldUseFallback, equals(terminice.shouldUseFallback));
      return context.runWithFallback(
        interactive: () => 'interactive:${context.shouldUseFallback}',
        fallback: () => 'fallback:${context.shouldUseFallback}',
      );
    },
  );
}

class _FallbackScenario {
  const _FallbackScenario({
    required this.label,
    required this.terminice,
    required this.expected,
  });

  final String label;
  final Terminice terminice;
  final String expected;
}

class _ContextProbeComponent extends TerminiceComponent<_ContextSnapshot> {
  @override
  _ContextSnapshot run(TerminiceComponentContext context) {
    return _ContextSnapshot(
      terminice: context.terminice,
      configuration: context.configuration,
      theme: context.theme,
      terminal: context.terminal,
      input: context.input,
      output: context.output,
      shouldUseFallback: context.shouldUseFallback,
      activeTerminal: TerminalContext.current,
    );
  }
}

class _ContextSnapshot {
  _ContextSnapshot({
    required this.terminice,
    required this.configuration,
    required this.theme,
    required this.terminal,
    required this.input,
    required this.output,
    required this.shouldUseFallback,
    required this.activeTerminal,
  });

  final Terminice terminice;
  final TerminiceConfig configuration;
  final PromptTheme theme;
  final Terminal terminal;
  final TerminalInput input;
  final TerminalOutput output;
  final bool shouldUseFallback;
  final Terminal activeTerminal;
}
