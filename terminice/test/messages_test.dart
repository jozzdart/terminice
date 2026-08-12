import 'package:test/test.dart';
import 'package:terminice/terminice.dart';
import 'package:terminice/testing.dart'
    show
        MockTerminal,
        MockTerminalInput,
        MockTerminalOutput,
        MockTerminalSnapshotExtension,
        TerminiceTester;

void main() {
  setUp(TerminalContext.reset);
  tearDown(TerminalContext.reset);

  group('message primitives', () {
    test('public API is available from package:terminice/terminice.dart', () {
      final terminal = MockTerminal();
      final t = Terminice().fallback.withTerminal(terminal);

      _writeAllMessageKinds(t);

      expect(terminal.mockOutput.lines, equals(_plainMessageLines()));
    });

    test('writes to the configured terminal instead of a stale global terminal',
        () {
      final target = MockTerminal();
      final stale = MockTerminal();
      final t = terminice.fallback.withTerminal(target);
      terminice.fallback.withTerminal(stale).activate();

      _writeAllMessageKinds(t);
      t.newline();

      expect(target.mockOutput.lines, equals([..._plainMessageLines(), '']));
      expect(stale.mockOutput.allOutput, isEmpty);
    });

    test('TerminiceTester captures message output cleanly', () {
      final tester = TerminiceTester.fallback();

      tester.run((t) {
        t.info('captured');
        t.detail('details');
      });

      expect(tester.output.normalizedText, equals('INFO: captured\n  details'));
      expect(tester.output.containsAnsiControls, isFalse);
      expect(tester.output.isAscii, isTrue);
    });

    test('fallback output is plain ASCII and ANSI-free', () {
      final tester = TerminiceTester.fallback();

      tester.run(_writeAllMessageKinds);

      expect(tester.output.plainLines, equals(_plainMessageLines()));
      expect(tester.output.containsAnsiControls, isFalse);
      expect(tester.output.isAscii, isTrue);
    });

    test('non-interactive output is plain ASCII and ANSI-free', () {
      final tester = TerminiceTester.nonInteractive();

      tester.run(_writeAllMessageKinds);

      expect(tester.output.plainLines, equals(_plainMessageLines()));
      expect(tester.output.containsAnsiControls, isFalse);
      expect(tester.output.isAscii, isTrue);
    });

    test('explicit interactive overrides non-TTY and throwing probes', () {
      final nonTty = MockTerminal();
      nonTty.mockInput.setHasTerminal(false);
      nonTty.mockOutput.setHasTerminal(false);
      final throwing = _ThrowingProbeTerminal();

      terminice.interactive.withTerminal(nonTty).info('non-TTY');
      terminice.interactive.withTerminal(throwing).info('throwing');

      expect(nonTty.outputSnapshot.containsAnsiControls, isTrue);
      expect(throwing.mockOutput.allOutput, contains('\x1b['));
    });

    test('auto and fallback stay plain when terminal probes are unsuitable',
        () {
      final nonTty = MockTerminal();
      nonTty.mockInput.setHasTerminal(false);
      nonTty.mockOutput.setHasTerminal(false);
      final throwing = _ThrowingProbeTerminal();
      final fallback = MockTerminal();

      terminice.autoFallback.withTerminal(nonTty).info('non-TTY');
      terminice.autoFallback.withTerminal(throwing).info('throwing');
      terminice.fallback.withTerminal(fallback).info('fallback');

      expect(nonTty.outputSnapshot.containsAnsiControls, isFalse);
      expect(throwing.mockOutput.allOutput, isNot(contains('\x1b[')));
      expect(fallback.outputSnapshot.containsAnsiControls, isFalse);
    });

    test('compatibility and plain theme paths use plain ANSI-free output', () {
      final cases = <String, Terminice>{
        'basic': terminice.basic,
        'legacy': terminice.legacy,
        'noColor': terminice.withColors(TerminalColors.none),
        'ascii': terminice.withGlyphs(TerminalGlyphs.ascii),
      };

      for (final entry in cases.entries) {
        final terminal = MockTerminal();
        final t = entry.value.interactive.withTerminal(terminal);

        t.info('${entry.key} ready');

        final output = terminal.outputSnapshot;
        expect(
          output.normalizedText,
          equals('INFO: ${entry.key} ready'),
          reason: entry.key,
        );
        expect(output.containsAnsiControls, isFalse, reason: entry.key);
        expect(output.isAscii, isTrue, reason: entry.key);
      }
    });

    test('modern interactive output uses theme colors and semantic glyphs', () {
      final terminal = MockTerminal();
      final theme = PromptTheme.fire;
      final t = Terminice(defaultTheme: theme).interactive.withTerminal(
            terminal,
          );

      t.info('network');
      t.success('saved');
      t.warn('careful');
      t.error('failed');
      t.detail('quiet');

      expect(
        terminal.mockOutput.lines,
        equals([
          '${theme.info}\u2139${theme.reset} network',
          '${theme.checkboxOn}\u2713${theme.reset} saved',
          '${theme.warn}\u26A0${theme.reset} careful',
          '${theme.error}\u2717${theme.reset} failed',
          '${theme.dim}  quiet${theme.reset}',
        ]),
      );
      expect(
        terminal.outputSnapshot.plainLines,
        equals([
          '\u2139 network',
          '\u2713 saved',
          '\u26A0 careful',
          '\u2717 failed',
          '  quiet',
        ]),
      );
      expect(terminal.outputSnapshot.containsAnsiControls, isTrue);
    });

    test('err matches error behavior', () {
      final errorTerminal = MockTerminal();
      final errTerminal = MockTerminal();

      terminice.fallback.withTerminal(errorTerminal).error('same');
      terminice.fallback.withTerminal(errTerminal).err('same');

      expect(
          errTerminal.mockOutput.lines, equals(errorTerminal.mockOutput.lines));
      expect(errTerminal.mockOutput.lines, equals(['ERROR: same']));
    });

    test('newline handles default, explicit, zero, and negative counts', () {
      final terminal = MockTerminal();
      final t = terminice.fallback.withTerminal(terminal);

      t.log('before');
      t.newline();
      t.log('after default');
      t.newline(2);
      t.log('after two');
      t.newline(0);
      t.newline(-3);
      t.log('after non-positive');

      expect(
        terminal.mockOutput.lines,
        equals([
          'before',
          '',
          'after default',
          '',
          '',
          'after two',
          'after non-positive',
        ]),
      );
    });

    test('stringifies Object messages including null', () {
      final terminal = MockTerminal();
      final t = terminice.fallback.withTerminal(terminal);

      t.log(null);
      t.info(42);
      t.detail(_MessageObject('custom'));

      expect(
        terminal.mockOutput.lines,
        equals([
          'null',
          'INFO: 42',
          '  custom',
        ]),
      );
    });

    test('plain messages normalize lines and visibly escape terminal controls',
        () {
      final terminal = MockTerminal();
      final t = terminice.fallback.withTerminal(terminal);

      t.log(_MessageObject('first\n\tsecond\x1b[2J'));
      t.error('failure\x1b]0;owned\x07\rnext');

      expect(terminal.outputSnapshot.containsAnsiControls, isFalse);
      expect(
        terminal.mockOutput.lines,
        equals([
          r'first second\x1b[2J',
          r'ERROR: failure\x1b]0;owned\x07\rnext',
        ]),
      );
    });
  });
}

void _writeAllMessageKinds(Terminice t) {
  t.log('plain');
  t.info('info');
  t.success('success');
  t.warn('warn');
  t.error('error');
  t.err('err');
  t.detail('detail');
}

List<String> _plainMessageLines() {
  return const [
    'plain',
    'INFO: info',
    'OK: success',
    'WARN: warn',
    'ERROR: error',
    'ERROR: err',
    '  detail',
  ];
}

class _MessageObject {
  const _MessageObject(this.value);

  final String value;

  @override
  String toString() => value;
}

class _ThrowingProbeTerminal implements Terminal {
  final MockTerminalInput mockInput = _ThrowingProbeInput();
  final MockTerminalOutput mockOutput = _ThrowingProbeOutput();

  @override
  TerminalInput get input => mockInput;

  @override
  TerminalOutput get output => mockOutput;
}

class _ThrowingProbeInput extends MockTerminalInput {
  @override
  bool get hasTerminal => throw StateError('input probe failed');
}

class _ThrowingProbeOutput extends MockTerminalOutput {
  @override
  bool get hasTerminal => throw StateError('output probe failed');
}
