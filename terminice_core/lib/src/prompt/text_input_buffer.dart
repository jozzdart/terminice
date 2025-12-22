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

  /// Optional maximum length for the input.
  final int? maxLength;

  /// Creates a new text input buffer.
  ///
  /// [initialText] sets the starting content (truncated to [maxLength] if set).
  /// [maxLength] optionally limits input length.
  TextInputBuffer({
    String initialText = '',
    this.maxLength,
  }) {
    if (initialText.isNotEmpty) {
      var text = initialText;
      if (maxLength != null && text.length > maxLength!) {
        text = text.substring(0, maxLength!);
      }
      _buffer.write(text);
      _cursorPosition = text.length;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GETTERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Current text content.
  String get text => _buffer.toString();

  /// Current cursor position.
  int get cursorPosition => _cursorPosition;

  /// Length of the current text.
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

  /// Character at cursor position, or null if cursor is at end.
  String? get charAtCursor =>
      _cursorPosition < _buffer.length ? text[_cursorPosition] : null;

  // ──────────────────────────────────────────────────────────────────────────
  // MUTATIONS
  // ──────────────────────────────────────────────────────────────────────────

  /// Inserts a character at the cursor position.
  ///
  /// Returns true if the character was inserted (respects maxLength).
  bool insert(String char) {
    if (char.isEmpty) return false;
    if (maxLength != null && _buffer.length >= maxLength!) return false;

    final before = text.substring(0, _cursorPosition);
    final after = text.substring(_cursorPosition);

    _buffer.clear();
    _buffer.write(before);
    _buffer.write(char);
    _buffer.write(after);

    _cursorPosition += char.length;
    return true;
  }

  /// Inserts text at the cursor position.
  ///
  /// Returns the number of characters actually inserted (respects maxLength).
  int insertText(String text) {
    if (text.isEmpty) return 0;

    var toInsert = text;
    if (maxLength != null) {
      final available = maxLength! - _buffer.length;
      if (available <= 0) return 0;
      if (text.length > available) {
        toInsert = text.substring(0, available);
      }
    }

    final before = this.text.substring(0, _cursorPosition);
    final after = this.text.substring(_cursorPosition);

    _buffer.clear();
    _buffer.write(before);
    _buffer.write(toInsert);
    _buffer.write(after);

    _cursorPosition += toInsert.length;
    return toInsert.length;
  }

  /// Deletes the character before the cursor (backspace).
  ///
  /// Returns true if a character was deleted.
  bool backspace() {
    if (_cursorPosition == 0) return false;

    final before = text.substring(0, _cursorPosition - 1);
    final after = text.substring(_cursorPosition);

    _buffer.clear();
    _buffer.write(before);
    _buffer.write(after);

    _cursorPosition--;
    return true;
  }

  /// Deletes the character at the cursor (delete key).
  ///
  /// Returns true if a character was deleted.
  bool delete() {
    if (_cursorPosition >= _buffer.length) return false;

    final before = text.substring(0, _cursorPosition);
    final after = text.substring(_cursorPosition + 1);

    _buffer.clear();
    _buffer.write(before);
    _buffer.write(after);

    return true;
  }

  /// Deletes word before cursor (Ctrl+Backspace behavior).
  ///
  /// Returns true if any characters were deleted.
  bool backspaceWord() {
    if (_cursorPosition == 0) return false;

    final t = text;
    var pos = _cursorPosition - 1;

    // Skip trailing whitespace
    while (pos > 0 && t[pos] == ' ') {
      pos--;
    }

    // Delete until start of word
    while (pos > 0 && t[pos - 1] != ' ') {
      pos--;
    }

    final before = t.substring(0, pos);
    final after = t.substring(_cursorPosition);

    _buffer.clear();
    _buffer.write(before);
    _buffer.write(after);

    _cursorPosition = pos;
    return true;
  }

  /// Clears all text and resets cursor to start.
  void clear() {
    _buffer.clear();
    _cursorPosition = 0;
  }

  /// Sets the buffer to new text, cursor at end.
  void setText(String newText) {
    var text = newText;
    if (maxLength != null && text.length > maxLength!) {
      text = text.substring(0, maxLength!);
    }

    _buffer.clear();
    _buffer.write(text);
    _cursorPosition = text.length;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CURSOR MOVEMENT
  // ──────────────────────────────────────────────────────────────────────────

  /// Moves cursor by delta positions (negative = left, positive = right).
  void moveCursor(int delta) {
    _cursorPosition = (_cursorPosition + delta).clamp(0, _buffer.length);
  }

  /// Moves cursor to the start.
  void moveCursorToStart() {
    _cursorPosition = 0;
  }

  /// Moves cursor to the end.
  void moveCursorToEnd() {
    _cursorPosition = _buffer.length;
  }

  /// Moves cursor to a specific position (clamped).
  void setCursorPosition(int position) {
    _cursorPosition = position.clamp(0, _buffer.length);
  }

  /// Moves cursor to the start of the previous word.
  void moveCursorWordLeft() {
    if (_cursorPosition == 0) return;

    final t = text;
    var pos = _cursorPosition - 1;

    // Skip whitespace
    while (pos > 0 && t[pos] == ' ') {
      pos--;
    }

    // Find start of word
    while (pos > 0 && t[pos - 1] != ' ') {
      pos--;
    }

    _cursorPosition = pos;
  }

  /// Moves cursor to the end of the next word.
  void moveCursorWordRight() {
    if (_cursorPosition >= _buffer.length) return;

    final t = text;
    var pos = _cursorPosition;

    // Skip current word
    while (pos < t.length && t[pos] != ' ') {
      pos++;
    }

    // Skip whitespace
    while (pos < t.length && t[pos] == ' ') {
      pos++;
    }

    _cursorPosition = pos;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // KEY EVENT HANDLING
  // ──────────────────────────────────────────────────────────────────────────

  /// Handles a key event for text input.
  ///
  /// Returns true if the input was modified (useful for triggering re-render).
  /// Handles: typing, backspace, arrow keys, home/end.
  ///
  /// Does NOT handle: Enter, Esc, Tab (these are typically handled by the parent prompt).
  bool handleKey(KeyEvent event) {
    switch (event.type) {
      case KeyEventType.char:
        if (event.char != null) {
          return insert(event.char!);
        }
        return false;

      case KeyEventType.space:
        return insert(' ');

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
        ? text.substring(_cursorPosition + 1)
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
  /// This handles typing, backspace, delete, and cursor movement.
  /// Returns `handled` if the buffer processed the event, `ignored` otherwise.
  KeyBindings toTextInputBindings({
    void Function()? onInput,
  }) {
    return KeyBindings([
      KeyBinding(
        keys: {
          KeyEventType.char,
          KeyEventType.backspace,
          KeyEventType.arrowLeft,
          KeyEventType.arrowRight,
        },
        action: (event) {
          if (handleKey(event)) {
            onInput?.call();
            return KeyActionResult.handled;
          }
          return KeyActionResult.ignored;
        },
      ),
    ]);
  }
}

class TextWithBlockCursor {
  final String before;
  final String cursor;
  final String after;

  const TextWithBlockCursor(
      {required this.before, required this.cursor, required this.after});
}
