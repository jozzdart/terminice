import 'dart:math';

import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

extension HelpCenterExtensions on Terminice {
  /// Launches an interactive help center with search, filtering, and preview.
  ///
  /// Users can type to filter documentation entries, navigate with the arrow
  /// keys, scroll previews horizontally, and confirm or cancel with Enter/Esc.
  /// The helper returns the selected [HelpDoc] or `null` when the prompt is
  /// cancelled or no documents are provided.
  ///
  /// ```dart
  /// final doc = terminice.helpCenter(
  ///   docs: const [
  ///     HelpDoc(
  ///       id: 'shortcuts',
  ///       title: 'Keyboard shortcuts',
  ///       content: 'Use Ctrl+P to open the command palette.',
  ///       category: 'Productivity',
  ///     ),
  ///   ],
  /// );
  /// ```
  ///
  /// - `title`: Frame header text.
  /// - `docs`: Complete list of searchable documents.
  /// - `maxVisibleResults`: Number of rows in the results window.
  /// - `maxPreviewLines`: Number of lines shown in the preview pane.
  HelpDoc? helpCenter({
    String title = 'Help Center',
    required List<HelpDoc> docs,
    int maxVisibleResults = 10,
    int maxPreviewLines = 8,
  }) {
    if (docs.isEmpty) return null;
    final theme = defaultTheme;

    // Use centralized text input for search query handling
    final queryInput = TextInputBuffer();
    int previewScroll = 0;
    bool cancelled = false;

    List<HelpDoc> filtered = List.from(docs);

    // Use centralized list navigation for selection & scrolling
    final nav = ListNavigator(
      itemCount: filtered.length,
      maxVisible: maxVisibleResults,
    );

    // Note: compact mode ignores terminal height to avoid expansion

    void updateFilter() {
      if (queryInput.text.trim().isEmpty) {
        filtered = List.from(docs);
      } else {
        final q = queryInput.text.toLowerCase();
        filtered = docs
            .where((d) =>
                d.title.toLowerCase().contains(q) ||
                (d.category?.toLowerCase().contains(q) ?? false) ||
                d.content.toLowerCase().contains(q))
            .toList();
        // Light ranking: title hits before content hits
        filtered.sort((a, b) {
          final at = a.title.toLowerCase().contains(q);
          final bt = b.title.toLowerCase().contains(q);
          if (at != bt) return bt ? 1 : -1;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
      }
      nav.itemCount = filtered.length;
      nav.reset();
      previewScroll = 0;
    }

    String truncate(String text, int max) {
      if (text.length <= max) return text;
      if (max <= 3) return text.substring(0, max);
      return '${text.substring(0, max - 3)}...';
    }

    String labelFor(HelpDoc d) {
      if (d.category == null || d.category!.isEmpty) return d.title;
      return '${d.title}  ${theme.dim}(${d.category})${theme.reset}';
    }

    void moveSelection(int delta) {
      nav.moveBy(delta);
      previewScroll = 0; // reset preview to top of new selection
    }

    HelpDoc? result;

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings.verticalNavigation(
          onUp: () => moveSelection(-1),
          onDown: () => moveSelection(1),
        ) +
        KeyBindings([
          // Horizontal scroll
          KeyBinding.single(
            KeyEventType.arrowLeft,
            (event) {
              previewScroll = max(0, previewScroll - 1);
              return KeyActionResult.handled;
            },
            hintLabel: '←/→',
            hintDescription: 'scroll preview',
          ),
          KeyBinding.single(
            KeyEventType.arrowRight,
            (event) {
              if (filtered.isNotEmpty) {
                final lines = filtered[nav.selectedIndex].content.split('\n');
                previewScroll =
                    min(previewScroll + 1, max(0, lines.length - 1));
              }
              return KeyActionResult.handled;
            },
          ),
        ]) +
        queryInput.toTextInputBindings(onInput: updateFilter) +
        KeyBindings.confirm(onConfirm: () {
          if (filtered.isNotEmpty) result = filtered[nav.selectedIndex];
          return KeyActionResult.confirmed;
        }) +
        KeyBindings.cancel(onCancel: () => cancelled = true);

    void render(RenderOutput out) {
      final cols = TerminalInfo.columns;
      final widgetFrame = FrameView(
        title: title,
        theme: theme,
        bindings: bindings,
      );

      widgetFrame.render(out, (ctx) {
        ctx.labeledValue('Search', queryInput.text, dimLabel: false);

        ctx.writeConnector();

        // Results header
        ctx.gutterLine(
            '${theme.dim}Results (${filtered.length})${theme.reset}');

        // Results window using ListNavigation
        if (filtered.isEmpty) {
          ctx.emptyMessage('no matches');
        } else {
          final window = nav.visibleWindow(filtered);

          if (window.hasOverflowAbove) {
            ctx.overflowIndicator();
          }

          for (var i = 0; i < window.items.length; i++) {
            final absoluteIdx = window.start + i;
            final isSel = nav.isSelected(absoluteIdx);
            final prefix = ctx.lb.arrow(isSel);
            final label = labelFor(window.items[i]);
            final line =
                '$prefix ${highlightSubstring(label, queryInput.text, theme)}';
            ctx.highlightedLine(line, highlighted: isSel);
          }

          if (window.hasOverflowBelow) {
            ctx.overflowIndicator();
          }
        }

        // Separator to preview
        ctx.writeConnector();

        // Preview header
        final selected = filtered.isEmpty ? null : filtered[nav.selectedIndex];
        final previewTitle = selected == null
            ? '${theme.dim}no selection${theme.reset}'
            : '${theme.accent}Preview:${theme.reset} ${selected.title}';
        ctx.gutterLine(previewTitle);

        // Preview content area
        if (selected != null) {
          final rawLines = selected.content.split('\n');
          final viewportStart = min(previewScroll, max(0, rawLines.length - 1));
          final viewportEnd =
              min(viewportStart + maxPreviewLines, rawLines.length);
          final contentWidth = max(10, cols - 4);

          for (var i = viewportStart; i < viewportEnd; i++) {
            final ln = rawLines[i];
            final highlighted = highlightSubstring(
                truncate(ln, contentWidth), queryInput.text, theme);
            ctx.gutterLine(highlighted);
          }
        }
      });
    }

    updateFilter();

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    return cancelled ? null : result;
  }
}

/// Represents a single searchable help document.
class HelpDoc {
  final String id;
  final String title;
  final String content;
  final String? category;

  /// Creates a help document.
  ///
  /// - `id`: Stable identifier used for analytics or persistence.
  /// - `title`: Line rendered in the results list.
  /// - `content`: Markdown or plaintext body shown in the preview panel.
  /// - `category`: Optional badge appended to the title for quick grouping.
  const HelpDoc({
    required this.id,
    required this.title,
    required this.content,
    this.category,
  });
}
