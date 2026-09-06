import 'package:terminice_core/testing.dart';
import 'package:test/test.dart';

void main() {
  tearDown(TerminalContext.reset);

  test('text-only callbacks exclude cursor changes and consumed no-op edits',
      () {
    final buffer = TextInputBuffer(maxLength: 1);
    var stateChanges = 0;
    var textChanges = 0;
    final bindings = buffer.toTextInputBindings(
      onInput: () => stateChanges++,
      onTextChanged: () => textChanges++,
    );
    for (final event in [
      const KeyEvent(KeyEventType.char, 'a'),
      const KeyEvent(KeyEventType.char, 'b'),
      const KeyEvent(KeyEventType.arrowLeft),
      const KeyEvent(KeyEventType.backspace),
      const KeyEvent(KeyEventType.arrowRight),
      const KeyEvent(KeyEventType.backspace),
    ]) {
      expect(bindings.handle(event), KeyActionResult.handled);
    }
    expect(stateChanges, 4);
    expect(textChanges, 2);
  });

  test('every decoded printable ASCII character reaches the editor', () {
    final terminal = MockTerminal();
    TerminalContext.current = terminal;
    final ascii = String.fromCharCodes(List.generate(95, (i) => i + 32));
    terminal.mockInput.queueString(ascii);
    final input = TextInputBuffer();
    final bindings = input.toTextInputBindings();
    for (var i = 0; i < ascii.length; i++) {
      expect(bindings.handle(KeyEventReader.read()), KeyActionResult.handled);
    }
    expect(input.text, ascii);
  });

  for (final grapheme in ['😀', 'e\u0301', '👩‍👩‍👧‍👦']) {
    test('movement, rendering and deletion preserve $grapheme', () {
      final input = TextInputBuffer(initialText: 'a${grapheme}b');
      input.moveCursor(-2);
      expect(input.cursorPosition, 1);
      expect(input.charAtCursor, grapheme);
      final display = input.textWithBlockCursor();
      expect([display.before, display.cursor, display.after],
          ['a', grapheme, 'b']);
      input.setCursorPosition(2);
      expect(input.cursorPosition, 1);
      input.delete();
      expect(input.text, 'ab');
      input.insert(grapheme);
      input.backspace();
      expect(input.text, 'ab');
    });
  }

  test('insertion and deletion normalize newly joined grapheme boundaries', () {
    final input = TextInputBuffer(initialText: '\u0301b');
    input.moveCursorToStart();
    input.insert('e');
    expect(input.textBeforeCursor, 'e\u0301');
    input.backspace();
    expect(input.text, 'b');
    input.setText('🇺x🇸');
    input.setCursorPosition(2);
    input.delete();
    expect(input.cursorPosition, 0);
    expect(input.charAtCursor, '🇺🇸');
  });

  test('maxLength is UTF-16 and never truncates within a grapheme', () {
    final input = TextInputBuffer(initialText: 'a😀', maxLength: 2);
    expect(input.text, 'a');
    expect(input.insert('😀z'), isFalse);
    expect(input.insertText('bc'), 1);
    expect(input.text, 'ab');
    input.setText('e\u0301z');
    expect(input.text, 'e\u0301');
    input.clear();
    expect(input.insert('abcd'), isTrue);
    expect(input.text, 'ab');
    expect(TextInputBuffer(maxLength: 0).insert('x'), isFalse);
    expect(() => TextInputBuffer(maxLength: -1), throwsArgumentError);
  });

  test('word operations preserve graphemes', () {
    final input = TextInputBuffer(initialText: '😀 e\u0301  ');
    input.moveCursorWordLeft();
    expect(input.textBeforeCursor, '😀 ');
    input.moveCursorWordRight();
    expect(input.cursorAtEnd, isTrue);
    input.backspaceWord();
    expect(input.text, '😀 ');
  });

  test('ordinary and conditional bindings agree and consume no-op edits', () {
    final first = TextInputBuffer(maxLength: 3);
    final second = TextInputBuffer(maxLength: 3);
    var enabled = true;
    var changed = 0;
    final ordinary = first.toTextInputBindings(onInput: () => changed++);
    final conditional = KeyBindings.conditionalTextInput(
        buffer: second, isEnabled: () => enabled);
    for (final event in [
      const KeyEvent(KeyEventType.backspace),
      const KeyEvent(KeyEventType.arrowLeft),
      const KeyEvent(KeyEventType.space),
      const KeyEvent(KeyEventType.slash),
      const KeyEvent(KeyEventType.char, 'ab'),
      const KeyEvent(KeyEventType.char, 'x'),
      const KeyEvent(KeyEventType.arrowRight),
    ]) {
      expect(ordinary.handle(event), KeyActionResult.handled);
      expect(conditional.handle(event), KeyActionResult.handled);
      expect(first.text, second.text);
    }
    expect(changed, 3);
    enabled = false;
    expect(conditional.handle(const KeyEvent(KeyEventType.backspace)),
        KeyActionResult.ignored);
    expect(second.text, ' /a');
    expect(ordinary.handle(const KeyEvent(KeyEventType.enter)),
        KeyActionResult.ignored);
    expect(ordinary.handle(const KeyEvent(KeyEventType.char, '\n')),
        KeyActionResult.ignored);
  });

  test('form sends printable input and grapheme edits to the focused field',
      () {
    final terminal = MockTerminal();
    TerminalContext.current = terminal;
    terminal.mockInput
      ..queueString('first /path😀')
      ..queueKey(KeyEventType.backspace)
      ..queueKey(KeyEventType.tab)
      ..queueString('second /path')
      ..queueKey(KeyEventType.enter);
    final result = FormPrompt(title: 'Paths', fields: const [
      FormFieldConfig(label: 'First'),
      FormFieldConfig(label: 'Second'),
    ]).run();
    expect(result?.values, ['first /path', 'second /path']);
  });
}
