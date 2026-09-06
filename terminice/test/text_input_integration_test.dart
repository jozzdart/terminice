import 'package:terminice/testing.dart';
import 'package:terminice/src/config_editor/focused_select.dart';
import 'package:terminice/src/config_editor/editor_loop.dart';
import 'package:test/test.dart';

TerminiceTester scripted(void Function(TerminalScriptBuilder) build) =>
    TerminiceTester.interactive(script: TerminalScript.build(build));

void main() {
  test('issue 30 confirmation preserves OVERRIDE STALE CHECKOUT', () {
    final tester = scripted((s) => s
        .text('OVERRIDE')
        .space()
        .text('STALE')
        .space()
        .text('CHECKOUT')
        .enter());
    expect(
        tester.run((t) => t.text('Confirmation')), 'OVERRIDE STALE CHECKOUT');
  });
  test('rejected confirmation retains input for correction and retry', () {
    final tester =
        scripted((s) => s.text('a /x').enter().backspace().text('b').enter());
    expect(
        tester.run((t) => t.text('Confirmation',
            validator: (value) => value == 'a /b' ? null : 'Try again')),
        'a /b');
  });
  const text = 'A / e\u0301😀👩‍👩‍👧‍👦';
  test('text decodes printable bytes and edits at the cursor', () {
    final tester = scripted((s) => s.text(text).left().text('!').enter());
    expect(tester.run((t) => t.text('Text')), 'A / e\u0301😀!👩‍👩‍👧‍👦');
  });
  test('password preserves spaces, slash and Unicode', () {
    final tester = scripted((s) => s.text(text).enter());
    expect(tester.run((t) => t.password('Password')), text);
  });
  test('password verification preserves the same printable input', () {
    final tester = scripted((s) => s.text(text).enter().text(text).enter());
    expect(tester.run((t) => t.password('Password', verify: true)), text);
  });
  test('form shares printable input editing', () {
    final tester = scripted((s) => s.text(text).enter());
    expect(
        tester
            .run((t) =>
                t.form('Form', fields: const [FormFieldConfig(label: 'Name')]))
            ?.values,
        [text]);
  });
  test('multiline splits and rejoins whole graphemes', () {
    final tester = scripted(
        (s) => s.text(text).left().enter().backspace().key(KeyEventType.ctrlD));
    expect(tester.run((t) => t.multiline('Notes')), text);
  });
  test('multiline vertical cursor rounds down to a whole grapheme', () {
    final tester = scripted((s) =>
        s.text('😀x').enter().text('a').up().text('!').key(KeyEventType.ctrlD));
    expect(tester.run((t) => t.multiline('Notes')), '!😀x\na');
  });
  test('multiline joining creates a complete combining grapheme', () {
    final tester = scripted((s) => s
        .text('e')
        .enter()
        .text('\u0301')
        .left()
        .backspace()
        .right()
        .backspace()
        .key(KeyEventType.ctrlD));
    expect(tester.run((t) => t.multiline('Notes')), '');
  });
  test('search slash activates then slash and space are literal', () {
    final tester = scripted((s) => s.text('/a /b').enter());
    expect(
        tester.run((t) => t.searchSelector(options: ['ab', 'a /b'])), ['a /b']);
  });
  test('search focus preserves filter and navigation through cursor edits', () {
    final tester = scripted((s) => s
        .text('a')
        .down()
        .left()
        .key(KeyEventType.ctrlGeneric, 'f')
        .space()
        .key(KeyEventType.ctrlGeneric, 'f')
        .enter());
    expect(
        tester.run((t) => t.searchSelector(
            options: ['ax', 'ay', 'b'], showSearch: true, multiSelect: true)),
        ['ay']);
  });
  test('focused select preserves initial filtered navigation on focus switch',
      () {
    final tester = scripted(
        (s) => s.text('a').down().key(KeyEventType.ctrlGeneric, 'f').enter());
    expect(
        tester.run((t) => focusedSelect(
            terminice: t,
            options: ['ax', 'ay', 'b'],
            title: 'Choose',
            showSearch: true)),
        'ay');
  });
  test('ranked search preserves spaces slash and result focus on left', () {
    final tester = scripted((s) => s.text('a /').down().left().enter());
    expect(
        tester.run((_) =>
            RankedListPrompt<String>(title: 'Rank', items: ['a /x', 'a /y'])
                .run(
                    rankItem: (item, query, _) => substringMatch(item, query),
                    itemLabel: (item) => item)),
        'a /y');
  });
  test('help search preserves spaces slash and preview arrow precedence', () {
    const docs = [
      HelpDoc(id: 'x', title: 'a /x', content: 'first'),
      HelpDoc(id: 'y', title: 'a /y', content: 'second')
    ];
    final tester =
        scripted((s) => s.text('a /').down().left().text('y').enter());
    expect(tester.run((t) => t.helpCenter(docs: docs)), same(docs[1]));
  });
  test('hidden original selections survive a query with no matches', () {
    final tester = scripted((s) => s.text('missing').enter());
    expect(
        tester.run((_) => SearchableListPrompt<String>(
            title: 'Select',
            items: ['a', 'b'],
            multiSelect: true,
            initialSelection: {1}).run()),
        ['b']);
  });
  test('duplicate values retain distinct original selections', () {
    final tester = scripted((s) => s
        .down()
        .space()
        .text('/b')
        .key(KeyEventType.ctrlGeneric, 'f')
        .space()
        .enter());
    expect(
        tester.run((_) => SearchableListPrompt<String>(
                title: 'Select',
                items: ['a', 'a', 'b'],
                multiSelect: true,
                searchEnabled: false)
            .run()),
        ['a', 'b']);
  });
  test('empty filtered search without explicit selections returns nothing', () {
    final tester = scripted((s) =>
        s.text('missing').key(KeyEventType.ctrlGeneric, 'f').space().enter());
    expect(
        tester.run((t) => t.searchSelector(
            options: ['a'], showSearch: true, multiSelect: true)),
        isEmpty);
  });
  test('filtered duplicate rows map back to their exact original indices', () {
    final prompt = SearchableListPrompt<String>(
        title: 'Select', items: ['other', 'a', 'a'], multiSelect: true);
    final tester = scripted((s) =>
        s.text('a').down().key(KeyEventType.ctrlGeneric, 'f').space().enter());
    expect(tester.run((_) => prompt.run()), ['a']);
    expect(prompt.selection.selectedIndices, {2});
  });
  test('config editor focus switch retains the filtered field and navigation',
      () {
    final first =
        StringConfigurable(key: 'first', label: 'First', value: 'old');
    final second =
        StringConfigurable(key: 'second', label: 'Second', value: 'old');
    final tester = scripted((s) => s
        .text('Second')
        .down()
        .key(KeyEventType.ctrlGeneric, 'f')
        .enter()
        .text('!')
        .enter()
        .up()
        .enter());
    expect(
        tester.run((t) => runEditorLoop(
            terminice: t,
            title: 'Config',
            fields: [first, second],
            isRoot: true)),
        isTrue);
    expect(first.value, 'old');
    expect(second.value, '!');
  });
  test('hex input consumes full-buffer shortcuts and vertical arrows', () {
    final baseline = scripted((s) => s.enter())
        .run((t) => t.colorPicker('Color', initialHex: '#FF0000'));
    final tester =
        scripted((s) => s.text('h//////s').up().down().enter().enter());
    expect(tester.run((t) => t.colorPicker('Color', initialHex: '#FF0000')),
        baseline);
  });
  for (final key in [KeyEventType.esc, KeyEventType.ctrlC]) {
    test('search $key cancels even with hidden selections', () {
      final tester = scripted((s) => s.text('missing').key(key));
      expect(
          tester.run((_) => SearchableListPrompt<String>(
              title: 'Select',
              items: ['a'],
              multiSelect: true,
              initialSelection: {0}).run()),
          isEmpty);
    });
  }
}
