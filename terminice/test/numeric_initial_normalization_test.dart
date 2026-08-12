import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';
import 'package:test/test.dart';

import 'mock_terminal.dart';

void main() {
  setUp(TerminalContext.reset);
  tearDown(TerminalContext.reset);

  test('slider uses one normalized initial in rich, line, and unattended modes',
      () {
    final richConfirm = MockTerminal()..mockInput.queueKey(KeyEventType.enter);
    final richCancel = MockTerminal()..mockInput.queueKey(KeyEventType.esc);
    final lineBlank = MockTerminal()..mockInput.queueLine('');
    final lineEof = MockTerminal();
    final unattended = MockTerminal();
    unattended.mockInput.setHasTerminal(false);
    unattended.mockOutput.setHasTerminal(false);

    num run(Terminice value) => value.slider(
          'Value',
          min: 0,
          max: 9,
          initial: 99,
          step: 2,
        );

    expect(run(terminice.interactive.withTerminal(richConfirm)), 8);
    expect(run(terminice.interactive.withTerminal(richCancel)), 8);
    expect(run(terminice.fallback.withTerminal(lineBlank)), 8);
    expect(run(terminice.fallback.withTerminal(lineEof)), 8);
    expect(run(terminice.autoFallback.withTerminal(unattended)), 8);
  });

  test('range uses one ordered normalized initial in every mode', () {
    final richConfirm = MockTerminal()..mockInput.queueKey(KeyEventType.enter);
    final richCancel = MockTerminal()..mockInput.queueKey(KeyEventType.esc);
    final lineBlank = MockTerminal()..mockInput.queueLines(['', '']);
    final lineEof = MockTerminal();
    final unattended = MockTerminal();
    unattended.mockInput.setHasTerminal(false);
    unattended.mockOutput.setHasTerminal(false);

    (num, num) run(Terminice value) {
      final result = value.range(
        'Range',
        min: 0,
        max: 9,
        startInitial: 10,
        endInitial: 2,
        step: 2,
      );
      return (result.start, result.end);
    }

    expect(run(terminice.interactive.withTerminal(richConfirm)), (2, 8));
    expect(run(terminice.interactive.withTerminal(richCancel)), (2, 8));
    expect(run(terminice.fallback.withTerminal(lineBlank)), (2, 8));
    expect(run(terminice.fallback.withTerminal(lineEof)), (2, 8));
    expect(run(terminice.autoFallback.withTerminal(unattended)), (2, 8));
  });

  test('decimal ties use the same higher-step rule in every mode', () {
    final line = MockTerminal()..mockInput.queueLine('');
    final unattended = MockTerminal();
    unattended.mockInput.setHasTerminal(false);
    unattended.mockOutput.setHasTerminal(false);

    expect(
      terminice.fallback.withTerminal(line).slider(
            'Decimal',
            min: 0.1,
            max: 0.9,
            initial: 0.4,
            step: 0.2,
          ),
      closeTo(0.5, 1e-12),
    );
    expect(
      terminice.autoFallback.withTerminal(unattended).slider(
            'Decimal',
            min: 0.1,
            max: 0.9,
            initial: 0.4,
            step: 0.2,
          ),
      closeTo(0.5, 1e-12),
    );
  });

  test('just-below-half initials choose the nearer lower step in every mode',
      () {
    final rich = MockTerminal()..mockInput.queueKey(KeyEventType.enter);
    final line = MockTerminal()..mockInput.queueLine('');
    final unattended = MockTerminal();
    unattended.mockInput.setHasTerminal(false);
    unattended.mockOutput.setHasTerminal(false);

    num run(Terminice value) => value.slider(
          'Nearest',
          min: 0.1,
          max: 0.9,
          initial: 0.3999999999,
          step: 0.2,
        );

    expect(run(terminice.interactive.withTerminal(rich)), closeTo(0.3, 1e-12));
    expect(run(terminice.fallback.withTerminal(line)), closeTo(0.3, 1e-12));
    expect(
      run(terminice.autoFallback.withTerminal(unattended)),
      closeTo(0.3, 1e-12),
    );
  });

  test('on-grid decimal maxima remain available in every mode', () {
    final rich = MockTerminal()..mockInput.queueKey(KeyEventType.enter);
    final line = MockTerminal()..mockInput.queueLine('');
    final unattended = MockTerminal();
    unattended.mockInput.setHasTerminal(false);
    unattended.mockOutput.setHasTerminal(false);

    num run(Terminice value) => value.slider(
          'Maximum',
          min: 0.1,
          max: 0.7,
          initial: 0.7,
          step: 0.2,
        );

    expect(run(terminice.interactive.withTerminal(rich)), closeTo(0.7, 1e-12));
    expect(run(terminice.fallback.withTerminal(line)), closeTo(0.7, 1e-12));
    expect(
      run(terminice.autoFallback.withTerminal(unattended)),
      closeTo(0.7, 1e-12),
    );
  });

  test('slider rejects non-finite values and bounds before I/O in every mode',
      () {
    final configurations = <Terminice Function(MockTerminal)>[
      (terminal) => terminice.interactive.withTerminal(terminal),
      (terminal) => terminice.fallback.withTerminal(terminal),
      (terminal) {
        terminal.mockInput.setHasTerminal(false);
        terminal.mockOutput.setHasTerminal(false);
        return terminice.autoFallback.withTerminal(terminal);
      },
    ];

    for (final configure in configurations) {
      for (final run in <num Function(Terminice)>[
        (value) => value.slider('Invalid', initial: double.nan),
        (value) => value.slider('Invalid', initial: double.infinity),
        (value) => value.slider('Invalid', initial: double.negativeInfinity),
        (value) => value.slider('Invalid', min: double.nan),
        (value) => value.slider('Invalid', min: double.infinity),
        (value) => value.slider('Invalid', min: double.negativeInfinity),
        (value) => value.slider('Invalid', max: double.nan),
        (value) => value.slider('Invalid', max: double.infinity),
        (value) => value.slider('Invalid', max: double.negativeInfinity),
        (value) => value.slider('Invalid', min: 10, max: 0),
        (value) => value.slider(
              'Invalid',
              min: -1.7976931348623157e308,
              max: 1.7976931348623157e308,
              step: 0.1,
            ),
      ]) {
        final terminal = MockTerminal();
        expect(() => run(configure(terminal)), throwsArgumentError);
        expect(terminal.mockOutput.allOutput, isEmpty);
      }
    }
  });

  test('range rejects non-finite values and bounds before I/O in every mode',
      () {
    final configurations = <Terminice Function(MockTerminal)>[
      (terminal) => terminice.interactive.withTerminal(terminal),
      (terminal) => terminice.fallback.withTerminal(terminal),
      (terminal) {
        terminal.mockInput.setHasTerminal(false);
        terminal.mockOutput.setHasTerminal(false);
        return terminice.autoFallback.withTerminal(terminal);
      },
    ];

    for (final configure in configurations) {
      for (final run in <RangeResult Function(Terminice)>[
        (value) => value.range('Invalid', startInitial: double.nan),
        (value) => value.range('Invalid', endInitial: double.infinity),
        (value) => value.range(
              'Invalid',
              startInitial: double.negativeInfinity,
            ),
        (value) => value.range('Invalid', min: double.nan),
        (value) => value.range('Invalid', min: double.infinity),
        (value) => value.range('Invalid', min: double.negativeInfinity),
        (value) => value.range('Invalid', max: double.nan),
        (value) => value.range('Invalid', max: double.infinity),
        (value) => value.range('Invalid', max: double.negativeInfinity),
        (value) => value.range('Invalid', min: 10, max: 0),
        (value) => value.range(
              'Invalid',
              min: -1.7976931348623157e308,
              max: 1.7976931348623157e308,
              step: 0.1,
            ),
      ]) {
        final terminal = MockTerminal();
        expect(() => run(configure(terminal)), throwsArgumentError);
        expect(terminal.mockOutput.allOutput, isEmpty);
      }
    }
  });
}
