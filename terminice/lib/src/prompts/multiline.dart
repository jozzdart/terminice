import 'dart:math';

import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Multi-line editor prompt that emulates a lightweight terminal text area with
/// scrolling, cursor management, and full keyboard bindings.
extension MultiLineInputPromptExtensions on Terminice {
  /// MultiLineInputPrompt - editable pseudo text area for multi-line input.
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
  /// final text = MultiLineInputPrompt(label: 'Notes')
  ///   .withMatrixTheme()
  ///   .run();
  /// ```
  String? multiline({
    required String label,
    int maxLines = 200,
    int visibleLines = 10,
    bool allowEmpty = true,
  }) {
    final theme = defaultTheme;
    final lines = <String>[''];
    int cursorLine = 0;
    int cursorColumn = 0;
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

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings([
          // Vertical movement
          KeyBinding.single(
            KeyEventType.arrowUp,
            (event) {
              if (cursorLine > 0) cursorLine--;
              cursorColumn = min(cursorColumn, lines[cursorLine].length);
              updateScroll();
              return KeyActionResult.handled;
            },
            hintLabel: '↑/↓',
            hintDescription: 'line',
          ),
          KeyBinding.single(
            KeyEventType.arrowDown,
            (event) {
              if (cursorLine < lines.length - 1) cursorLine++;
              cursorColumn = min(cursorColumn, lines[cursorLine].length);
              updateScroll();
              return KeyActionResult.handled;
            },
          ),
          // Horizontal movement
          KeyBinding.single(
            KeyEventType.arrowLeft,
            (event) {
              if (cursorColumn > 0) {
                cursorColumn--;
              } else if (cursorLine > 0) {
                cursorLine--;
                cursorColumn = lines[cursorLine].length;
              }
              updateScroll();
              return KeyActionResult.handled;
            },
            hintLabel: '←/→',
            hintDescription: 'move',
          ),
          KeyBinding.single(
            KeyEventType.arrowRight,
            (event) {
              if (cursorColumn < lines[cursorLine].length) {
                cursorColumn++;
              } else if (cursorLine < lines.length - 1) {
                cursorLine++;
                cursorColumn = 0;
              }
              updateScroll();
              return KeyActionResult.handled;
            },
          ),
          // Enter = new line
          KeyBinding.single(
            KeyEventType.enter,
            (event) {
              if (lines.length < maxLines) {
                final line = lines[cursorLine];
                final before = line.substring(0, cursorColumn);
                final after = line.substring(cursorColumn);
                lines[cursorLine] = before;
                lines.insert(cursorLine + 1, after);
                cursorLine++;
                cursorColumn = 0;
              }
              updateScroll();
              return KeyActionResult.handled;
            },
            hintLabel: 'Enter',
            hintDescription: 'new line',
          ),
          // Backspace
          KeyBinding.single(
            KeyEventType.backspace,
            (event) {
              if (cursorColumn > 0) {
                final line = lines[cursorLine];
                lines[cursorLine] = line.substring(0, cursorColumn - 1) +
                    line.substring(cursorColumn);
                cursorColumn--;
              } else if (cursorLine > 0) {
                // merge with previous line
                final prev = lines[cursorLine - 1];
                final current = lines.removeAt(cursorLine);
                cursorLine--;
                cursorColumn = prev.length;
                lines[cursorLine] = prev + current;
              }
              updateScroll();
              return KeyActionResult.handled;
            },
          ),
          // Typing
          KeyBinding.char(
            (c) => true,
            (event) {
              final ch = event.char!;
              final line = lines[cursorLine];
              final before = line.substring(0, cursorColumn);
              final after = line.substring(cursorColumn);
              lines[cursorLine] = '$before$ch$after';
              cursorColumn++;
              return KeyActionResult.handled;
            },
          ),
        ]) +
        KeyBindings.ctrlD(
          onPress: () {
            if (allowEmpty || lines.any((l) => l.trim().isNotEmpty)) {
              confirmed = true;
            }
          },
          hintDescription: 'confirm',
        ) +
        KeyBindings.cancel(onCancel: () => cancelled = true);

    void render(RenderOutput out) {
      final widgetFrame = FrameView(
        title: label,
        theme: theme,
        bindings: bindings,
        hintStyle: HintStyle.bullets,
      );

      widgetFrame.render(out, (ctx) {
        // Visible text area
        final start = scrollOffset;
        final end = min(scrollOffset + visibleLines, lines.length);
        for (var i = start; i < end; i++) {
          final text = lines[i];
          final isCurrent = i == cursorLine;
          final prefix = ctx.lb.arrow(isCurrent);

          if (isCurrent) {
            final before = text.substring(0, cursorColumn);
            final after = text.substring(cursorColumn);
            final cursorChar = after.isEmpty ? ' ' : after[0];
            ctx.gutterLine(
                '$prefix $before${theme.inverse}$cursorChar${theme.reset}${after.length > 1 ? after.substring(1) : ''}');
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
    return lines.join('\n');
  }
}
