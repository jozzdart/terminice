import 'package:terminice/terminice.dart';
import 'package:test/test.dart';

import 'mock_terminal.dart';

void main() {
  setUp(TerminalContext.reset);
  tearDown(TerminalContext.reset);

  group('plain guides', () {
    test('static guides render once without reading input or ANSI', () {
      final terminal = _unattendedTerminal(['queued']);
      final t = terminice.autoFallback.withTerminal(terminal);

      t.cheatSheet(
        'Commands',
        columns: const ['Key', 'Action'],
        entries: const [
          ['q', 'Quit'],
        ],
      );
      t.hotkeyGuide(
        title: 'Keys',
        shortcuts: const [
          ['Ctrl+S', 'Save'],
        ],
      );
      t.themeDemo();

      expect(terminal.mockInput.linesRemaining, 1);
      expect(terminal.mockOutput.contains('Commands'), isTrue);
      expect(terminal.mockOutput.contains('q   | Quit'), isTrue);
      expect(terminal.mockOutput.contains('Ctrl+S | Save'), isTrue);
      expect(terminal.mockOutput.contains('Terminice theme catalogue'), isTrue);
      _expectPlainIo(terminal);
    });

    test('help line mode selects and prints document content literally', () {
      final terminal = MockTerminal()..mockInput.queueLine('2');
      const docs = [
        HelpDoc(id: 'one', title: 'First', content: 'First body'),
        HelpDoc(
          id: 'two',
          title: 'Second\x1b[31m',
          content: 'Line one\nLine two\x1b[0m',
          category: 'Guide',
        ),
      ];

      final selected = terminice.fallback.withTerminal(terminal).helpCenter(
            title: 'Docs',
            docs: docs,
          );

      expect(selected, same(docs[1]));
      expect(terminal.mockOutput.contains('Line one\nLine two'), isTrue);
      expect(terminal.mockOutput.contains(r'\x1b[31m'), isTrue);
      _expectPlainIo(terminal);
    });

    test('help unattended prints documents, returns null, and does not read',
        () {
      final terminal = _unattendedTerminal(['1']);

      final selected = terminice.autoFallback.withTerminal(terminal).helpCenter(
        docs: const [
          HelpDoc(
              id: 'start', title: 'Getting started', content: 'Install it.'),
        ],
      );

      expect(selected, isNull);
      expect(terminal.mockInput.linesRemaining, 1);
      expect(terminal.mockOutput.contains('Getting started'), isTrue);
      expect(terminal.mockOutput.contains('Install it.'), isTrue);
      _expectPlainIo(terminal);
    });
  });

  group('line config editor', () {
    test('edits every built-in field type and saves nested values', () {
      final terminal = MockTerminal();
      terminal.mockInput.queueLines([
        '1',
        'yes',
        '2',
        'new name',
        '3',
        'new-secret',
        '4',
        '4',
        '5',
        '2',
        '6',
        '3',
        '7',
        '7',
        '5',
        '8',
        '2',
        '9',
        'line one',
        'line two',
        '.',
        '10',
        '1',
        'nested value',
        'b',
        's',
      ]);
      final fields = <Configurable>[
        BoolConfigurable(key: 'enabled', label: 'Enabled'),
        StringConfigurable(key: 'name', label: 'Name', value: 'old'),
        PasswordConfigurable(
          key: 'secret',
          label: 'Secret',
          value: 'old-secret',
        ),
        NumberConfigurable(
          key: 'count',
          label: 'Count',
          value: 2,
          min: 0,
          max: 10,
          useSlider: true,
          integerOnly: true,
        ),
        EnumConfigurable(
          key: 'mode',
          label: 'Mode',
          value: 'a',
          options: const ['a', 'b'],
        ),
        RangeConfigurable(
          key: 'range',
          label: 'Range',
          start: 1,
          end: 9,
          min: 0,
          max: 10,
        ),
        RatingConfigurable(key: 'rating', label: 'Rating'),
        ThemeConfigurable(key: 'theme', label: 'Theme'),
        StringConfigurable(
          key: 'notes',
          label: 'Notes',
          value: 'old note',
          multiline: true,
        ),
        GroupConfigurable(
          key: 'advanced',
          label: 'Advanced',
          children: [
            StringConfigurable(key: 'nested', label: 'Nested'),
          ],
        ),
      ];

      final result = terminice.fallback.withTerminal(terminal).configEditor(
            'Settings',
            fields: fields,
          );

      expect(result, isNotNull);
      expect(result!.toMap(), containsPair('enabled', true));
      expect(result.toMap(), containsPair('name', 'new name'));
      expect(result.toMap(), containsPair('secret', 'new-secret'));
      expect(result.toMap(), containsPair('count', 4));
      expect(result.toMap(), containsPair('mode', 'b'));
      expect(result.toMap()['range'], {'start': 3, 'end': 7});
      expect(result.toMap(), containsPair('rating', 5));
      expect(result.toMap(), containsPair('theme', 'matrix'));
      expect(result.toMap(), containsPair('notes', 'line one\nline two'));
      expect(result.toMap()['advanced'], {'nested': 'nested value'});
      expect(terminal.mockOutput.allOutput, isNot(contains('old-secret')));
      _expectPlainIo(terminal);
    });

    test('multiline field uses the line sentinel flow', () {
      final terminal = MockTerminal();
      terminal.mockInput.queueLines(['1', 'first', 'second', '.', 's']);
      final notes = StringConfigurable(
        key: 'notes',
        label: 'Notes',
        multiline: true,
      );

      final result = terminice.fallback.withTerminal(terminal).configEditor(
        'Settings',
        fields: [notes],
      );

      expect(result, isNotNull);
      expect(notes.value, 'first\nsecond');
      _expectPlainIo(terminal);
    });

    test('cancel restores root and nested mutable values transactionally', () {
      final terminal = MockTerminal();
      terminal.mockInput.queueLines([
        '1',
        '1',
        'changed',
        '2',
        '2',
        '8',
        'b',
        '2',
        'changed root',
        'c',
      ]);
      final nestedName =
          StringConfigurable(key: 'name', label: 'Nested name', value: 'old');
      final range = RangeConfigurable(
        key: 'range',
        label: 'Nested range',
        start: 1,
        end: 9,
        min: 0,
        max: 10,
      );
      final rootName =
          StringConfigurable(key: 'root', label: 'Root name', value: 'root');
      final fields = <Configurable>[
        GroupConfigurable(
          key: 'group',
          label: 'Group',
          children: [nestedName, range],
        ),
        rootName,
      ];

      final result = terminice.fallback.withTerminal(terminal).configEditor(
            'Settings',
            fields: fields,
          );

      expect(result, isNull);
      expect(nestedName.value, 'old');
      expect(range.value, RangeValue(1, 9));
      expect(rootName.value, 'root');
      _expectPlainIo(terminal);
    });

    test('invalid commands and validation errors retry with explanations', () {
      final terminal = MockTerminal();
      terminal.mockInput.queueLines(['wat', 's', '1', 'valid', 's']);
      final field = StringConfigurable(
        key: 'value',
        label: 'Value',
        value: '',
        validator: (value) => value.isEmpty ? 'Required' : null,
      );

      final result = terminice.fallback.withTerminal(terminal).configEditor(
        'Settings',
        fields: [field],
      );

      expect(result, isNotNull);
      expect(terminal.mockOutput.contains('listed command'), isTrue);
      expect(
          terminal.mockOutput.contains('Cannot save: Value: Required'), isTrue);
    });

    test('direct group editing remains line-safe', () {
      final terminal = MockTerminal()..mockInput.queueLine('b');
      final group = GroupConfigurable(
        key: 'group',
        label: 'Group',
        children: [StringConfigurable(key: 'value', label: 'Value')],
      );

      group.edit(terminice.fallback.withTerminal(terminal));

      _expectPlainIo(terminal);
    });
  });

  group('unattended config editor', () {
    test('returns a valid snapshot without reads, output, or mutation', () {
      final terminal = _unattendedTerminal(['c']);
      final field = StringConfigurable(
        key: 'name',
        label: 'Name',
        value: 'Ada',
        validator: (value) => value.isEmpty ? 'Required' : null,
      );

      final result = terminice.autoFallback.withTerminal(terminal).configEditor(
        'Settings',
        fields: [field],
      );

      expect(result?.toMap(), {'name': 'Ada'});
      expect(field.value, 'Ada');
      expect(terminal.mockInput.linesRemaining, 1);
      expect(terminal.mockOutput.allOutput, isEmpty);
      _expectPlainIo(terminal);
    });

    test('returns null when validation needs user resolution', () {
      final terminal = _unattendedTerminal(['value']);
      final field = StringConfigurable(
        key: 'name',
        label: 'Name',
        value: '',
        validator: (value) => value.isEmpty ? 'Required' : null,
      );

      final result = terminice.autoFallback.withTerminal(terminal).configEditor(
        'Settings',
        fields: [field],
      );

      expect(result, isNull);
      expect(field.value, isEmpty);
      expect(terminal.mockInput.linesRemaining, 1);
      expect(terminal.mockOutput.allOutput, isEmpty);
    });
  });
}

MockTerminal _unattendedTerminal(List<String> queuedLines) {
  final terminal = MockTerminal();
  terminal.mockInput
    ..setHasTerminal(false)
    ..queueLines(queuedLines);
  terminal.mockOutput.setHasTerminal(false);
  return terminal;
}

void _expectPlainIo(MockTerminal terminal) {
  expect(terminal.mockInput.lineMode, isTrue);
  expect(terminal.mockInput.echoMode, isTrue);
  expect(terminal.mockOutput.allOutput, isNot(contains('\x1b')));
}
