import 'dart:io';

import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart' show FormFieldConfig;
import 'package:test/test.dart';

import 'mock_terminal.dart';

void main() {
  setUp(TerminalContext.reset);
  tearDown(TerminalContext.reset);

  group('built-in execution modes', () {
    test('line mode invokes every prompt, selector, and picker surface', () {
      final directory =
          Directory.systemTemp.createTempSync('terminice-matrix-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File.fromUri(directory.uri.resolve('sample.txt'))
        ..writeAsStringSync('x');
      final terminal = MockTerminal();
      final t = terminice.fallback.withTerminal(terminal);

      terminal.mockInput.queueLine('Ada');
      expect(t.text('Text'), 'Ada');
      terminal.mockInput.queueLine('secret');
      expect(t.password('Password'), 'secret');
      terminal.mockInput.queueLines(['same', 'same']);
      expect(t.password('Verified', verify: true), 'same');
      terminal.mockInput.queueLines(['Ada', 'Lovelace']);
      expect(
        t.form(
          'Form',
          fields: const [
            FormFieldConfig(label: 'First'),
            FormFieldConfig(label: 'Last'),
          ],
        )?.values,
        ['Ada', 'Lovelace'],
      );
      terminal.mockInput.queueLine('');
      expect(t.confirm(message: 'Default confirmation'), isFalse);
      terminal.mockInput.queueLine('');
      expect(
        t.confirm(message: 'Explicit positive default', defaultYes: true),
        isTrue,
      );
      terminal.mockInput.queueLines(['first', 'second', '.']);
      expect(t.multiline('Multiline'), 'first\nsecond');
      terminal.mockInput.queueLine('2026-08-12');
      expect(t.date('Date'), DateTime(2026, 8, 12));
      terminal.mockInput.queueLine('4');
      expect(t.slider('Slider', min: 0, max: 10), 4);
      terminal.mockInput.queueLines(['2', '8']);
      final range = t.range('Range', min: 0, max: 10);
      expect((range.start, range.end), (2, 8));
      terminal.mockInput.queueLine('4');
      expect(t.rating('Rating'), 4);

      terminal.mockInput.queueLine('2');
      expect(
        t.searchSelector(prompt: 'Search', options: const ['a', 'b']),
        ['b'],
      );
      terminal.mockInput.queueLine('1');
      expect(t.gridSelector(prompt: 'Grid', options: const ['a', 'b']), ['a']);
      terminal.mockInput.queueLine('1');
      expect(t.checkboxSelector('Checkbox', options: const ['a', 'b']), ['a']);
      terminal.mockInput.queueLine('2');
      expect(
        t.choiceSelector(
          'Choice',
          items: const [ChoiceItem('a'), ChoiceItem('b')],
        ),
        ['b'],
      );
      terminal.mockInput.queueLine('1');
      expect(t.tagSelector(prompt: 'Tags', tags: const ['a', 'b']), ['a']);
      terminal.mockInput.queueLine('2');
      expect(
        t.toggleGroup(
          'Toggles',
          items: const [ToggleItem('a'), ToggleItem('b')],
        ),
        {'a': false, 'b': true},
      );
      terminal.mockInput.queueLine('1');
      expect(
        t.commandPalette(
          'Commands',
          commands: const [CommandEntry(id: 'run', title: 'Run')],
        )?.id,
        'run',
      );

      terminal.mockInput.queueLine('2026-08-12');
      expect(t.datePicker('Date picker'), DateTime(2026, 8, 12));
      terminal.mockInput.queueLine('a1b2c3');
      expect(t.colorPicker('Color picker'), '#A1B2C3');
      terminal.mockInput.queueLine('sample.txt');
      expect(
        t.filePicker('File picker', startDirectory: directory),
        file.absolute.path,
      );
      terminal.mockInput.queueLine('');
      expect(
        t.pathPicker('Path picker', startDirectory: directory),
        directory.absolute.path,
      );

      expect(terminal.mockInput.linesRemaining, 0);
      _expectPlainLineIo(terminal);
    });

    test('line mode invokes flow and every message primitive', () {
      final terminal = MockTerminal();
      terminal.mockInput.queueLines(['Ada', '']);
      final t = terminice.fallback.withTerminal(terminal);

      final result = t
          .flow('Flow')
          .text('name', 'Name')
          .confirm('ready', message: 'Ready?')
          .run();
      expect(result.string('name'), 'Ada');
      expect(result.flag('ready'), isFalse);

      t
        ..log('log')
        ..info('info')
        ..success('success')
        ..warn('warn')
        ..error('error')
        ..err('err')
        ..detail('detail')
        ..newline();

      _expectPlainLineIo(terminal);
    });

    test('line mode invokes task and progressTask surfaces', () async {
      final terminal = MockTerminal();
      final t = terminice.fallback.withTerminal(terminal);

      expect(await t.task<int>('Task', run: () => 7), 7);
      expect(
        await t.progressTask<int>(
          'Progress task',
          total: 2,
          run: (progress) {
            progress.increment();
            progress.increment();
            return progress.current;
          },
        ),
        2,
      );

      expect(terminal.mockOutput.lineCount, lessThanOrEqualTo(4));
      _expectPlainLineIo(terminal);
    });

    test('rich confirmation defaults to No and honors explicit Yes', () {
      final defaultTerminal = MockTerminal()..mockInput.queueByte(13);
      final explicitTerminal = MockTerminal()..mockInput.queueByte(13);

      expect(
        terminice.interactive
            .withTerminal(defaultTerminal)
            .confirm(message: 'Default?'),
        isFalse,
      );
      expect(
        terminice.interactive.withTerminal(explicitTerminal).confirm(
              message: 'Explicit?',
              defaultYes: true,
            ),
        isTrue,
      );
    });

    test('date line mode rejects invalid dates then accepts strict ISO', () {
      final terminal = MockTerminal();
      terminal.mockInput.queueLines(['2026-02-30', '2026-02-28']);

      final result = terminice.fallback.withTerminal(terminal).date('Date');

      expect(result, DateTime(2026, 2, 28));
      expect(terminal.mockOutput.contains('real date'), isTrue);
      _expectPlainLineIo(terminal);
    });

    test('date picker blank preserves a valid initial date', () {
      final terminal = MockTerminal();
      terminal.mockInput.queueLine('');
      final initial = DateTime(2026, 8, 12, 15);

      final result = terminice.fallback
          .withTerminal(terminal)
          .datePicker('Date', initialDate: initial);

      expect(result, DateTime(2026, 8, 12));
      _expectPlainLineIo(terminal);
    });

    test('color line mode retries and normalizes confirmed hex', () {
      final terminal = MockTerminal();
      terminal.mockInput.queueLines(['blue', 'a1b2c3']);

      final result =
          terminice.fallback.withTerminal(terminal).colorPicker('Accent');

      expect(result, '#A1B2C3');
      expect(terminal.mockOutput.contains('hex color'), isTrue);
      _expectPlainLineIo(terminal);
    });

    test('multiline uses submit and cancel sentinels', () {
      final submitted = MockTerminal();
      submitted.mockInput.queueLines(['one', 'two', '.']);
      final cancelled = MockTerminal();
      cancelled.mockInput.queueLines(['one', ':cancel']);

      expect(
        terminice.fallback.withTerminal(submitted).multiline('Notes'),
        'one\ntwo',
      );
      expect(
        terminice.fallback.withTerminal(cancelled).multiline('Notes'),
        isNull,
      );
      _expectPlainLineIo(submitted);
      _expectPlainLineIo(cancelled);
    });

    test('path line mode resolves relative paths against start directory', () {
      final directory = Directory.systemTemp.createTempSync('terminice-path-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File.fromUri(directory.uri.resolve('sample.txt'))
        ..writeAsStringSync('x');
      final terminal = MockTerminal();
      terminal.mockInput.queueLine('sample.txt');

      final result = terminice.fallback.withTerminal(terminal).filePicker(
            'File',
            startDirectory: directory,
          );

      expect(result, file.absolute.path);
      _expectPlainLineIo(terminal);
    });

    test('file picker foldersOnly line mode accepts existing directories', () {
      final directory = Directory.systemTemp.createTempSync('terminice-dir-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final child = Directory.fromUri(directory.uri.resolve('child'))
        ..createSync();
      final terminal = MockTerminal();
      terminal.mockInput.queueLine('child');

      final result = terminice.fallback.withTerminal(terminal).filePicker(
            'Folder',
            startDirectory: directory,
            foldersOnly: true,
          );

      expect(result, child.absolute.path);
      _expectPlainLineIo(terminal);
    });

    test('multi-select blank confirms no selection unless initialized', () {
      final emptyTerminal = MockTerminal();
      emptyTerminal.mockInput.queueLine('');
      final initialTerminal = MockTerminal();
      initialTerminal.mockInput.queueLine('');

      expect(
        terminice.fallback.withTerminal(emptyTerminal).checkboxSelector(
          'Features',
          options: const ['one', 'two'],
        ),
        isEmpty,
      );
      expect(
        terminice.fallback.withTerminal(initialTerminal).checkboxSelector(
          'Features',
          options: const ['one', 'two'],
          initialSelected: {1},
        ),
        ['two'],
      );
    });

    test('slider line mode rejects values not aligned to step', () {
      final terminal = MockTerminal();
      terminal.mockInput.queueLines(['3', '4']);

      final result = terminice.fallback.withTerminal(terminal).slider(
            'Even',
            min: 0,
            max: 10,
            step: 2,
          );

      expect(result, 4);
      expect(terminal.mockOutput.contains('increments of 2'), isTrue);
      _expectPlainLineIo(terminal);
    });

    test('range line mode validates step for both endpoints', () {
      final terminal = MockTerminal();
      terminal.mockInput.queueLines(['3', '4', '9', '8']);

      final result = terminice.fallback.withTerminal(terminal).range(
            'Even range',
            min: 0,
            max: 10,
            step: 2,
          );

      expect(result.start, 4);
      expect(result.end, 8);
      expect(terminal.mockOutput.allOutput.split('increments of 2').length, 3);
      _expectPlainLineIo(terminal);
    });

    test('slider and range reject non-positive steps in every mode', () {
      expect(
        () => terminice.fallback.slider('Invalid', step: 0),
        throwsArgumentError,
      );
      expect(
        () => terminice.interactive.range('Invalid', step: -1),
        throwsArgumentError,
      );
    });

    test('unattended input built-ins do not consume queued line input', () {
      final terminal = MockTerminal();
      terminal.mockInput
        ..setHasTerminal(false)
        ..queueLines(['yes', '1', '#ffffff'])
        ..queueByte(13);
      terminal.mockOutput.setHasTerminal(false);
      final t = terminice.autoFallback.withTerminal(terminal);

      expect(t.text('Text'), isNull);
      expect(t.password('Password'), isNull);
      expect(
        t.form(
          'Form',
          fields: const [FormFieldConfig(label: 'Optional', required: false)],
        )?.values,
        [''],
      );
      expect(t.confirm(message: 'Proceed?'), isFalse);
      expect(
        t.confirm(message: 'Still safe?', defaultYes: true),
        isFalse,
      );
      expect(t.multiline('Multiline'), '');
      expect(t.date('Date', initial: DateTime(2026, 8, 12)),
          DateTime(2026, 8, 12));
      expect(t.slider('Slider', initial: 4), 4);
      final range = t.range('Range', startInitial: 2, endInitial: 8);
      expect((range.start, range.end), (2, 8));
      expect(t.rating('Rating', initial: 4), 4);
      expect(t.searchSelector(options: const ['a']), isEmpty);
      expect(
        t.gridSelector(
          options: const ['zero', 'one', 'two'],
          initialSelection: const {2, -1, 1, 99},
        ),
        ['one'],
      );
      expect(
        t.gridSelector(
          options: const ['zero', 'one', 'two'],
          multiSelect: true,
          initialSelection: const {2, -1, 1, 99},
        ),
        ['one', 'two'],
      );
      expect(
        t.checkboxSelector(
          'Checkbox',
          options: const ['zero', 'one', 'two'],
          initialSelected: const {2, -1, 1, 99},
        ),
        ['one', 'two'],
      );
      expect(
        t.choiceSelector('Choice', items: const [ChoiceItem('a')]),
        isEmpty,
      );
      expect(t.tagSelector(tags: const ['a']), isEmpty);
      expect(
        t.toggleGroup('Toggle',
            items: const [ToggleItem('a', initialOn: true)]),
        {'a': true},
      );
      expect(
          t.commandPalette('Command', commands: const [
            CommandEntry(id: 'run', title: 'Run'),
          ]),
          isNull);
      expect(
        t.datePicker('Date picker', initialDate: DateTime(2026, 8, 12)),
        DateTime(2026, 8, 12),
      );
      expect(t.colorPicker('Color'), isNull);
      expect(t.filePicker('File'), isNull);
      expect(t.pathPicker('Path'), Directory.current.absolute.path);
      expect(terminal.mockInput.linesRemaining, 3);
      expect(terminal.mockInput.bytesRemaining, 1);
      expect(terminal.mockOutput.allOutput, isEmpty);
      _expectPlainLineIo(terminal);
    });
  });
}

void _expectPlainLineIo(MockTerminal terminal) {
  expect(terminal.mockInput.lineMode, isTrue);
  expect(terminal.mockInput.echoMode, isTrue);
  expect(terminal.mockOutput.allOutput, isNot(contains('\x1B[')));
}
