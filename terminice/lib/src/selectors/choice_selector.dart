import 'dart:math';

import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Displays a dashboard-style grid of selectable cards.
///
/// Controls:
/// - Arrow keys move across cards (wraps around edges)
/// - Space toggles selection when `multiSelect` is true
/// - Enter confirms the highlighted card(s)
/// - Esc cancels (returns `[]`)
///
/// Parameters:
/// - `items`: Cards rendered with `ChoiceItem.label` and optional subtitle.
/// - `prompt`: Frame title displayed above the grid.
/// - `multiSelect`: Enables toggling multiple cards.
/// - `columns`: Forces a specific column count (auto when zero).
/// - `cardWidth`: Overrides the computed card width (16-44 characters).
/// - `maxColumns`: Caps automatically computed columns.
///
/// Returns the labels for any cards that were confirmed by the user.
///
/// Example:
/// ```dart
/// final picked = terminice.choiceSelector(
///   items: const [
///     ChoiceItem('Preview', subtitle: 'Shows a live diff'),
///     ChoiceItem('Publish', subtitle: 'Deploy to production'),
///   ],
///   prompt: 'Pick actions',
///   multiSelect: true,
/// );
/// ```
extension ChoiceSelectorExtensions on Terminice {
  /// Renders a grid of cards and returns the labels that were selected.
  ///
  /// See the file-level docs for the supported controls and parameters.
  List<String> choiceSelector({
    required List<ChoiceItem> items,
    required String prompt,
    bool multiSelect = false,
    int columns = 0,
    int? cardWidth,
    int? maxColumns,
  }) {
    if (items.isEmpty) return [];
    final theme = defaultTheme;

    CardRender renderCard(
      ChoiceItem item,
      int boxWidth,
      bool highlighted,
      bool checked,
    ) {
      final check = multiSelect ? (checked ? '[x] ' : '[ ] ') : '';
      final titleMax = boxWidth - (multiSelect ? 4 : 0);

      String pad(String text, int width) {
        if (text.length > width) {
          if (width <= 1) return text.substring(0, 1);
          return '${text.substring(0, width - 1)}…';
        }
        return text.padRight(width);
      }

      final title = pad(check + item.label, titleMax);
      final subtitle = pad((item.subtitle ?? ''), boxWidth).trimRight();

      String paint(String s) {
        if (highlighted) {
          if (theme.useInverseHighlight) {
            return '${theme.inverse}$s${theme.reset}';
          }
          return '${theme.selection}$s${theme.reset}';
        }
        return s;
      }

      final top = paint(title.padRight(boxWidth));
      final bottom =
          paint('${theme.dim}${subtitle.padRight(boxWidth)}${theme.reset}');
      return CardRender(top: top, bottom: bottom);
    }

    // Compute card layout
    final longestLabel = items.fold<int>(0, (m, e) => max(m, e.label.length));
    final longestSubtitle =
        items.fold<int>(0, (m, e) => max(m, (e.subtitle ?? '').length));
    final natural = max(longestLabel + 4, min(36, longestSubtitle + 4));
    final computedCardWidth = (cardWidth ?? natural).clamp(16, 44);

    int computeCols() {
      if (columns > 0) return columns;
      final termWidth = TerminalInfo.columns;
      const leftPrefix = 2;
      const sepWidth = 1;
      final unit = computedCardWidth + sepWidth;
      final colsByWidth = max(1, ((termWidth - leftPrefix) + sepWidth) ~/ unit);
      final desired = max(2, min(items.length, sqrt(items.length).ceil()));
      final cap = (maxColumns != null && maxColumns > 0) ? maxColumns : desired;
      return min(colsByWidth, cap);
    }

    final cols = computeCols();
    final rows = (items.length + cols - 1) ~/ cols;

    // Use SelectableGridPrompt with custom card rendering
    final gridPrompt = SelectableGridPrompt<ChoiceItem>(
      title: prompt,
      items: items,
      theme: theme,
      multiSelect: multiSelect,
      columns: cols,
      cellWidth: computedCardWidth,
      maxColumns: maxColumns,
    );

    // Run with custom card-style rendering (two lines per card)
    final result = gridPrompt.runCustom(
      renderContent: (ctx) {
        final colSep = '${theme.gray}│${theme.reset}';

        for (int r = 0; r < rows; r++) {
          // First line of cards (titles)
          final line1 = StringBuffer(ctx.lb.gutter());
          // Second line (subtitles)
          final line2 = StringBuffer(ctx.lb.gutter());

          for (int c = 0; c < cols; c++) {
            final idx = r * cols + c;
            if (idx >= items.length) {
              line1.write(''.padRight(computedCardWidth));
              line2.write(''.padRight(computedCardWidth));
            } else {
              final card = renderCard(
                items[idx],
                computedCardWidth,
                gridPrompt.grid.isFocused(idx),
                gridPrompt.selection.isSelected(idx),
              );
              line1.write(card.top);
              line2.write(card.bottom);
            }
            if (c != cols - 1) {
              line1.write(colSep);
              line2.write(colSep);
            }
          }

          ctx.line(line1.toString());
          ctx.line(line2.toString());

          if (r != rows - 1) {
            final rowLine = List.generate(
              cols,
              (i) => '${theme.gray}${'─' * computedCardWidth}${theme.reset}',
            ).join('${theme.gray}┼${theme.reset}');
            ctx.gutterLine(rowLine);
          }
        }
      },
    );

    return result.map((item) => item.label).toList();
  }
}

/// Defines the content for a `choiceSelector` card.
///
/// Provide a short `label` and an optional `subtitle` (shown dimmed).
class ChoiceItem {
  final String label;
  final String? subtitle;

  const ChoiceItem(this.label, {this.subtitle});
}
