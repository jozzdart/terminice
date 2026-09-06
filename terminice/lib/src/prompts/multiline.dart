import 'dart:math';

import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Multi-line editor prompt that emulates a lightweight terminal text area with
/// scrolling, cursor management, and full keyboard bindings.
extension MultiLineInputPromptExtensions on Terminice {
  /// Reads multiple lines, returning `null` when cancelled.
  String? multiline(
    String prompt, {
    int maxLines = 200,
    int visibleLines = 10,
    bool allowEmpty = true,
  }) {
    return runWithExecutionMode<String?>(
      rich: () => _richMultiline(
        prompt,
        maxLines: maxLines,
        visibleLines: visibleLines,
        allowEmpty: allowEmpty,
      ),
      line: () => FallbackPrompt.multiline(
        title: prompt,
        maxLines: maxLines,
        allowEmpty: allowEmpty,
      ),
      unattended: () => allowEmpty ? '' : null,
    );
  }

  /// MultiLineInputPrompt - editable pseudo text area for multi-line input.
  ///
  /// - [prompt] is the title displayed above the text area.
  /// - [maxLines] limits the total number of lines allowed (defaults to 200).
  /// - [visibleLines] sets the height of the scrollable viewport (defaults to 10).
  /// - [allowEmpty] determines if an empty input can be confirmed (defaults to `true`).
  ///
  /// Controls:
  /// - Type normally to insert text
  /// - [Enter] inserts a new line
  /// - [Backspace] deletes characters or merges lines
  /// - [↑]/[↓] navigate between lines
  /// - [←]/[→] move within a line
  /// - [Ctrl+D] confirm (EOF)
  /// - [Esc] or [Ctrl+C] cancel
  ///
  /// **Mixins:** Implements [Themeable] for fluent theme configuration:
  /// ```dart
  /// final text = terminice.multiline('Notes');
  /// ```
  String? _richMultiline(
    String prompt, {
    int maxLines = 200,
    int visibleLines = 10,
    bool allowEmpty = true,
  }) {
    final theme = defaultTheme;
    final lines = <TextInputBuffer>[TextInputBuffer()];
    int cursorLine = 0;
    int scrollOffset = 0;
    bool cancelled = false;
    bool confirmed = false;

    void updateScroll() {
      if (cursorLine < scrollOffset) {
        scrollOffset = cursorLine;
      } else if (cursorLine >= scrollOffset + visibleLines) {
        scrollOffset = cursorLine - visibleLines + 1;
      }
    }

    void moveLine(int delta) {
      final column = lines[cursorLine].cursorPosition;
      cursorLine = (cursorLine + delta).clamp(0, lines.length - 1);
      lines[cursorLine].setCursorPosition(column);
      updateScroll();
    }

    final bindings = KeyBindings([
          KeyBinding.single(KeyEventType.arrowUp, (_) {
            moveLine(-1);
            return KeyActionResult.handled;
          }, hintLabel: '↑/↓', hintDescription: 'line'),
          KeyBinding.single(KeyEventType.arrowDown, (_) {
            moveLine(1);
            return KeyActionResult.handled;
          }),
          KeyBinding.single(KeyEventType.arrowLeft, (_) {
            if (!lines[cursorLine].cursorAtStart || cursorLine == 0) {
              return KeyActionResult.ignored;
            }
            lines[--cursorLine].moveCursorToEnd();
            updateScroll();
            return KeyActionResult.handled;
          }, hintLabel: '←/→', hintDescription: 'move'),
          KeyBinding.single(KeyEventType.arrowRight, (_) {
            if (!lines[cursorLine].cursorAtEnd ||
                cursorLine == lines.length - 1) {
              return KeyActionResult.ignored;
            }
            lines[++cursorLine].moveCursorToStart();
            updateScroll();
            return KeyActionResult.handled;
          }),
          KeyBinding.single(KeyEventType.enter, (_) {
            if (lines.length < maxLines) {
              final input = lines[cursorLine];
              final after = input.textAfterCursor;
              input.setText(input.textBeforeCursor);
              lines.insert(++cursorLine,
                  TextInputBuffer(initialText: after)..moveCursorToStart());
            }
            updateScroll();
            return KeyActionResult.handled;
          }, hintLabel: 'Enter', hintDescription: 'new line'),
          KeyBinding.single(KeyEventType.backspace, (_) {
            if (!lines[cursorLine].cursorAtStart || cursorLine == 0) {
              return KeyActionResult.ignored;
            }
            final current = lines.removeAt(cursorLine);
            final previous = lines[--cursorLine];
            final joinPosition = previous.length;
            previous.setText(previous.text + current.text);
            previous.setCursorPosition(joinPosition);
            updateScroll();
            return KeyActionResult.handled;
          }),
        ]) +
        KeyBindings.textInput(buffer: () => lines[cursorLine]) +
        KeyBindings.ctrlD(
          onPress: () {
            if (allowEmpty || lines.any((l) => l.text.trim().isNotEmpty)) {
              confirmed = true;
              return KeyActionResult.confirmed;
            }
            return KeyActionResult.handled;
          },
          hintDescription: 'confirm',
        ) +
        KeyBindings.cancel(onCancel: () => cancelled = true);

    void render(RenderOutput out) {
      final widgetFrame = FrameView(
        title: prompt,
        theme: theme,
        bindings: bindings,
      );

      widgetFrame.render(out, (ctx) {
        // Visible text area
        final start = scrollOffset;
        final end = min(scrollOffset + visibleLines, lines.length);
        for (var i = start; i < end; i++) {
          final text = lines[i].text;
          final isCurrent = i == cursorLine;
          final prefix = ctx.lb.arrow(isCurrent);

          if (isCurrent) {
            final cursor = lines[i].textWithBlockCursor();
            ctx.gutterLine(
                '$prefix ${cursor.before}${theme.inverse}${cursor.cursor}${theme.reset}${cursor.after}');
          } else {
            ctx.gutterLine('$prefix $text');
          }
        }

        // Fill remaining lines
        for (var i = end; i < start + visibleLines; i++) {
          ctx.line('${ctx.lb.gutterOnly()}   ${theme.dim}~${theme.reset}');
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    if (cancelled || !confirmed) return null;
    return lines.map((line) => line.text).join('\n');
  }
}
