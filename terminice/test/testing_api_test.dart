import 'dart:async';

import 'package:test/test.dart';
import 'package:terminice/testing.dart';

void main() {
  setUp(TerminalContext.reset);
  tearDown(TerminalContext.reset);

  group('TerminiceTester', () {
    test('runs fallback flows with typed results and captures output', () {
      final tester = TerminiceTester.fallback(lines: ['Ada', 'yes']);

      final result = tester.run(
        (t) => t
            .flow('Project')
            .text('name', 'Name')
            .confirm('create', message: 'Create project?')
            .run(),
      );

      expect(result.toMap(), equals({'name': 'Ada', 'create': true}));
      expect(result.value<String>('name'), equals('Ada'));
      expect(result.value<bool>('create'), isTrue);
      expect(tester.output.plainText, contains('Create project?'));
    });

    test('runs fallback reviewed flows with scripted review actions', () {
      final tester = TerminiceTester.fallback(lines: ['Ada', '1']);

      final result = tester.run(
        (t) => t.flow('Profile').text('name', 'Name').review().run(),
      );

      expect(result.confirmed, isTrue);
      expect(result.toMap(), equals({'name': 'Ada'}));
      expect(tester.output.plainText, contains('Review Profile'));
    });

    test('runs interactive reviewed flows with key scripts', () {
      final tester = TerminiceTester.interactive(
        script: TerminalScript.build((script) => script.enter()),
      );

      final result = tester.run(
        (t) => t
            .flow('Profile')
            .custom<String>(
              'name',
              'Name',
              includeInReview: true,
              run: (_) => 'Ada',
            )
            .review()
            .run(),
      );

      expect(result.confirmed, isTrue);
      expect(result.toMap(), equals({'name': 'Ada'}));
      expect(tester.output.plainText, contains('Review Profile'));
      expect(tester.output.plainText, contains('Name: Ada'));
    });

    test('runs interactive scripts against rich prompts', () {
      final tester = TerminiceTester.interactive(
        script: TerminalScript.build((script) => script.right().enter()),
      );

      final result = tester.run(
        (t) => t.confirm(message: 'Create project?'),
      );

      expect(result, isFalse);
      expect(tester.output.plainText, contains('Create project?'));
    });

    test('uses auto fallback for non-interactive terminals', () {
      final tester = TerminiceTester.nonInteractive(lines: ['Ada']);

      final result = tester.run((t) => t.text('Name'));

      expect(result, equals('Ada'));
      expect(tester.terminal.mockInput.hasTerminal, isFalse);
      expect(tester.terminal.mockOutput.hasTerminal, isFalse);
      expect(tester.output.plainText, contains('Name'));
    });

    test('captures async task helper output through runAsync', () async {
      final tester = TerminiceTester.nonInteractive();

      final result = await tester.runAsync(
        (t) => t.task<int>(
          'Build',
          run: () async => 7,
          success: 'built',
        ),
      );

      expect(result, equals(7));
      expect(tester.output.normalizedText, equals('OK: built'));
    });

    test('run restores the prior terminal on success and thrown errors', () {
      final previous = MockTerminal();
      TerminalContext.current = previous;

      final successTester = TerminiceTester.fallback(lines: ['Ada']);
      final result = successTester.run((t) {
        expect(TerminalContext.current, same(successTester.terminal));
        return t.text('Name');
      });

      expect(result, equals('Ada'));
      expect(TerminalContext.current, same(previous));

      final error = StateError('boom');
      final errorTester = TerminiceTester.fallback();

      expect(
        () => errorTester.run<void>((t) {
          expect(TerminalContext.current, same(errorTester.terminal));
          throw error;
        }),
        throwsA(same(error)),
      );
      expect(TerminalContext.current, same(previous));
    });

    test('runAsync restores the prior terminal on success and thrown errors',
        () async {
      final previous = MockTerminal();
      TerminalContext.current = previous;

      final successTester = TerminiceTester.fallback();
      final result = await successTester.runAsync((t) async {
        expect(TerminalContext.current, same(successTester.terminal));
        await Future<void>.delayed(Duration.zero);
        expect(TerminalContext.current, same(successTester.terminal));
        return 42;
      });

      expect(result, equals(42));
      expect(TerminalContext.current, same(previous));

      final error = StateError('async boom');
      final errorTester = TerminiceTester.fallback();

      await expectLater(
        errorTester.runAsync<void>((t) async {
          expect(TerminalContext.current, same(errorTester.terminal));
          await Future<void>.delayed(Duration.zero);
          throw error;
        }),
        throwsA(same(error)),
      );
      expect(TerminalContext.current, same(previous));
    });

    test('queue adds scripted input after construction', () {
      final tester = TerminiceTester.fallback();
      tester.queue(TerminalScript.lines(['Queued Ada']));

      final result = tester.run((t) => t.text('Name'));

      expect(result, equals('Queued Ada'));
      expect(tester.terminal.mockInput.linesRemaining, equals(0));
    });

    test('sidecar import exposes public Terminice and core testing APIs', () {
      final tester = TerminiceTester.fallback(
        base: Terminice(defaultTheme: PromptTheme.fire),
        lines: [''],
        columns: 100,
        rows: 40,
      );
      final script = TerminalScript.build((script) => script.enter());

      expect(tester.terminice.baseTheme, equals(PromptTheme.fire));
      expect(tester.terminice.terminal, same(tester.terminal));
      expect(tester.terminal.mockOutput.terminalColumns, equals(100));
      expect(tester.terminal.mockOutput.terminalLines, equals(40));
      expect(script.length, equals(1));
      expect(KeyEventType.enter, isNotNull);
    });
  });
}
