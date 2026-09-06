import 'package:characters/characters.dart';

import 'package:terminice_core/terminice_core.dart';

/// Manages text input state with cursor positioning.
///
/// Encapsulates the common pattern found in text-based terminal prompts:
/// - Text buffer with cursor position
/// - Character insertion at cursor
/// - Backspace/delete operations
/// - Cursor movement (left/right, home/end)
/// - Optional max length enforcement
///
/// **Usage:**
/// ```dart
/// final input = TextInputBuffer();
///
/// // Handle key events
/// if (input.handleKey(event)) {
///   // Input was modified, re-render
/// }
///
/// // Or use individual operations
/// input.insert('a');
/// input.backspace();
/// input.moveCursor(-1);
///
/// // Access state
/// final text = input.text;
/// final cursor = input.cursorPosition;
/// ```
///
/// **Key features:**
/// - Cursor-aware text editing
/// - Efficient StringBuffer-based storage
/// - Key event handling helper
/// - Selection support (future-ready)
/// - Zero boilerplate in prompts
class TextInputBuffer {
  final StringBuffer _buffer = StringBuffer();

  /// Current cursor position (0 = before first char, length = after last char).
  int _cursorPosition = 0;

  /// Optional maximum UTF-16 length; truncation preserves whole graphemes.
  final int? maxLength;

  /// Creates a new text input buffer.
  ///
  /// [initialText] sets the starting content (truncated to [maxLength] if set).
  /// [maxLength] optionally limits input length.
  TextInputBuffer({
    String initialText = '',
    this.maxLength,
  }) {
    if (maxLength != null && maxLength! < 0) {
      throw ArgumentError.value(maxLength, 'maxLength', 'Must be non-negative');
    }
    setText(initialText);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GETTERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Current text content.
  String get text => _buffer.toString();

  /// Current cursor position in UTF-16 code units, always at a grapheme boundary.
  int get cursorPosition => _cursorPosition;

  /// Length of the current text in UTF-16 code units.
  int get length => _buffer.length;

  /// Whether the buffer is empty.
  bool get isEmpty => _buffer.isEmpty;

  /// Whether the buffer is not empty.
  bool get isNotEmpty => _buffer.isNotEmpty;

  /// Whether the cursor is at the start.
  bool get cursorAtStart => _cursorPosition == 0;

  /// Whether the cursor is at the end.
  bool get cursorAtEnd => _cursorPosition == _buffer.length;

  /// Text before the cursor.
  String get textBeforeCursor => text.substring(0, _cursorPosition);

  /// Text after the cursor (including char at cursor).
  String get textAfterCursor => text.substring(_cursorPosition);

  /// Whole grapheme at cursor position, or null if cursor is at end.
  String? get charAtCursor => _cursorPosition < _buffer.length
      ? textAfterCursor.characters.first
      : null;

  // ──────────────────────────────────────────────────────────────────────────
  // MUTATIONS
  // ──────────────────────────────────────────────────────────────────────────

  /// Inserts text, returning whether any text was inserted.
  bool insert(String text) => insertText(text) > 0;

  /// Inserts the longest whole-grapheme prefix that fits [maxLength].
  /// Returns the number of UTF-16 code units inserted.
  int insertText(String value) {
    final inserted = _truncate(
        value, maxLength == null ? value.length : maxLength! - length);
    if (inserted.isEmpty) return 0;
    final position = _cursorPosition + inserted.length;
    _replace('$textBeforeCursor$inserted$textAfterCursor', position,
        roundUp: true);
    return inserted.length;
  }

  /// Deletes the complete grapheme before the cursor.
  bool backspace() {
    if (cursorAtStart) return false;
    final start = _boundaries.lastWhere((p) => p < _cursorPosition);
    _replace(text.substring(0, start) + textAfterCursor, start);
    return true;
  }

  /// Deletes the complete grapheme at the cursor.
  bool delete() {
    if (cursorAtEnd) return false;
    final end = _boundaries.firstWhere((p) => p > _cursorPosition);
    _replace(textBeforeCursor + text.substring(end), _cursorPosition);
    return true;
  }

  /// Deletes the word before the cursor, including trailing spaces.
  bool backspaceWord() {
    final end = _cursorPosition;
    moveCursorWordLeft();
    if (end == _cursorPosition) return false;
    _replace(textBeforeCursor + text.substring(end), _cursorPosition);
    return true;
  }

  static String _truncate(String value, int limit) {
    var length = 0;
    final result = StringBuffer();
    for (final grapheme in value.characters) {
      if (length + grapheme.length > limit) break;
      result.write(grapheme);
      length += grapheme.length;
    }
    return result.toString();
  }

  List<int> get _boundaries {
    var position = 0;
    return [
      0,
      for (final grapheme in text.characters) position += grapheme.length
    ];
  }

  void _replace(String value, int position, {bool roundUp = false}) {
    _buffer.clear();
    _buffer.write(value);
    final target = position.clamp(0, length);
    _cursorPosition = roundUp
        ? _boundaries.firstWhere((p) => p >= target)
        : _boundaries.lastWhere((p) => p <= target);
  }

  /// Clears all text and resets cursor to start.
  void clear() {
    _buffer.clear();
    _cursorPosition = 0;
  }

  /// Sets the buffer to new text, cursor at end.
  void setText(String newText) {
    final value = _truncate(newText, maxLength ?? newText.length);
    _replace(value, value.length);
  }

  /// Moves by grapheme positions (negative = left, positive = right).
  /// The public cursor offset remains measured in UTF-16 code units.
  void moveCursor(int delta) {
    final boundaries = _boundaries;
    final index = boundaries.indexOf(_cursorPosition);
    _cursorPosition =
        boundaries[(index + delta).clamp(0, boundaries.length - 1)];
  }

  /// Moves cursor to the start.
  void moveCursorToStart() {
    _cursorPosition = 0;
  }

  /// Moves cursor to the end.
  void moveCursorToEnd() {
    _cursorPosition = _buffer.length;
  }

  /// Sets a UTF-16 offset, clamped and rounded down to a grapheme boundary.
  void setCursorPosition(int position) {
    _cursorPosition =
        _boundaries.lastWhere((p) => p <= position.clamp(0, length));
  }

  /// Moves cursor to the start of the previous word.
  void moveCursorWordLeft() {
    if (_cursorPosition == 0) return;

    final graphemes = textBeforeCursor.characters.toList();
    var index = graphemes.length;
    while (index > 0 && graphemes[index - 1] == ' ') {
      index--;
    }
    while (index > 0 && graphemes[index - 1] != ' ') {
      index--;
    }
    _cursorPosition = graphemes.take(index).join().length;
  }

  /// Moves cursor past the current word and following spaces.
  void moveCursorWordRight() {
    final graphemes = textAfterCursor.characters.toList();
    var index = 0;
    while (index < graphemes.length && graphemes[index] != ' ') {
      index++;
    }
    while (index < graphemes.length && graphemes[index] == ' ') {
      index++;
    }
    _cursorPosition += graphemes.take(index).join().length;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // KEY EVENT HANDLING
  // ──────────────────────────────────────────────────────────────────────────

  /// Handles a key event for text input.
  ///
  /// Returns true if text or cursor state changed (useful for re-rendering).
  /// Handles typing, backspace and horizontal arrows. Recognized no-op keys
  /// return false here; text bindings consume them to prevent command fallthrough.
  ///
  /// Does NOT handle: Enter, Esc, Tab (these are typically handled by the parent prompt).
  bool handleKey(KeyEvent event) {
    final printable = event.printableText;
    if (printable != null) return insert(printable);
    switch (event.type) {
      case KeyEventType.backspace:
        return backspace();

      case KeyEventType.arrowLeft:
        if (cursorAtStart) return false;
        moveCursor(-1);
        return true;

      case KeyEventType.arrowRight:
        if (cursorAtEnd) return false;
        moveCursor(1);
        return true;

      default:
        return false;
    }
  }

  /// Handles a key event with extended controls (word movement, etc.).
  ///
  /// Ctrl+Left/Right for word movement, Ctrl+Backspace for word delete.
  /// Returns true if the input was modified.
  bool handleKeyExtended(KeyEvent event, {bool ctrl = false}) {
    if (!ctrl) return handleKey(event);

    switch (event.type) {
      case KeyEventType.arrowLeft:
        final oldPos = _cursorPosition;
        moveCursorWordLeft();
        return _cursorPosition != oldPos;

      case KeyEventType.arrowRight:
        final oldPos = _cursorPosition;
        moveCursorWordRight();
        return _cursorPosition != oldPos;

      case KeyEventType.backspace:
        return backspaceWord();

      default:
        return handleKey(event);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // RENDERING HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the text with a cursor indicator at the current position.
  ///
  /// [cursorChar] is the character to show at cursor (e.g., '▌', '|', '_').
  /// [showCursor] can be toggled for blinking effect.
  String textWithCursor({
    String cursorChar = '▌',
    bool showCursor = true,
  }) {
    if (!showCursor) return text;

    final before = textBeforeCursor;
    final after = textAfterCursor;
    return '$before$cursorChar$after';
  }

  /// Returns text formatted for display with inverse-video cursor.
  ///
  /// Returns a record with (beforeCursor, charAtCursor, afterCursor).
  /// If cursor is at end, charAtCursor is a space for block cursor effect.
  TextWithBlockCursor textWithBlockCursor() {
    final before = textBeforeCursor;
    final cursorChar = charAtCursor ?? ' ';
    final after = _cursorPosition < _buffer.length
        ? text.substring(_cursorPosition + cursorChar.length)
        : '';

    return TextWithBlockCursor(
        before: before, cursor: cursorChar, after: after);
  }

  @override
  String toString() => text;
}

/// Extension for simpler text-only usage (no cursor tracking).
///
/// Use this when you only need simple append/backspace without cursor positioning.
extension SimpleTextInput on TextInputBuffer {
  /// Appends text to the end (ignoring cursor position).
  void append(String text) {
    moveCursorToEnd();
    insertText(text);
  }

  /// Removes the last character (ignoring cursor position).
  bool removeLast() {
    moveCursorToEnd();
    return backspace();
  }
}

extension TextInputBindingsExtensions on TextInputBuffer {
  /// Creates text input bindings that delegate to a TextInputBuffer.
  ///
  /// Handles typing, backspace, and horizontal cursor movement.
  /// Recognized no-op edits are consumed; [onInput] runs only on state changes.
  KeyBindings toTextInputBindings({
    void Function()? onInput,
  }) {
    return KeyBindings.textInput(buffer: () => this, onInput: onInput);
  }
}

class TextWithBlockCursor {
  final String before;
  final String cursor;
  final String after;

  const TextWithBlockCursor(
      {required this.before, required this.cursor, required this.after});
}
