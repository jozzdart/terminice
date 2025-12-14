import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Choose multiple "chips" (tags) from a responsive grid.
///
/// Controls:
/// - Arrow keys navigate between chips
/// - Space toggles selection
/// - Enter confirms the highlighted set
/// - Esc / Ctrl+C cancels (returns `[]`)
///
/// Parameters:
/// - `tags`: Labels rendered inside each chip.
/// - `prompt`: Frame title text.
/// - `maxContentWidth`: Caps the inner frame width (auto when `null`).
/// - `minContentWidth`: Minimum content width before wrapping.
/// - `minColumnWidth`: Lower bound for chip column width.
/// - `maxColumnWidth`: Upper bound for chip column width.
/// - `useTerminalWidth`: When true, recomputes layout on resize.
///
/// Example:
/// ```dart
/// final labels = terminice.tagSelector(
///   tags: const ['Bug', 'Feature', 'Docs', 'Chore'],
///   prompt: 'Select labels',
///   maxContentWidth: 96,
/// );
/// ```
extension TagSelectorExtensions on Terminice {
  /// Renders the chip-style selector and returns the confirmed tags.
  ///
  /// See the file-level documentation for the control scheme and arguments.
  List<String> tagSelector({
    required List<String> tags,
    String prompt = 'Select tags',
    int? maxContentWidth,
    int minContentWidth = 32,
    int minColumnWidth = 8,
    int maxColumnWidth = 24,
    bool useTerminalWidth = true,
  }) {
    if (tags.isEmpty) return [];
    final theme = defaultTheme;
    String renderChip(
        String tag, bool isFocused, bool isSelected, int colWidth) {
      final raw = '[ $tag ]';
      final padding = (colWidth - raw.length).clamp(0, 1000);
      final padded = raw + ' ' * padding;

      if (isFocused) {
        return '${theme.inverse}${theme.selection}$padded${theme.reset}';
      }
      if (isSelected) {
        return padded.replaceFirst(tag, '${theme.accent}$tag${theme.reset}');
      }
      return '${theme.dim}$padded${theme.reset}';
    }

    // Compute layout for chip-style grid
    ({int contentWidth, int colWidth, int cols}) computeLayout() {
      const framePrefix = 2;
      final termCols = useTerminalWidth ? TerminalInfo.columns : 80;
      final targetContent = (maxContentWidth != null)
          ? maxContentWidth.clamp(minContentWidth, termCols - 4)
          : (termCols - 4).clamp(minContentWidth, termCols);

      final longest = tags.fold<int>(0, (m, t) => t.length > m ? t.length : m);
      final naturalChip = longest + 4; // [ tag ]
      final colWidth = naturalChip.clamp(minColumnWidth, maxColumnWidth);

      final available = targetContent - framePrefix;
      final cols =
          available <= 0 ? 1 : (available + 1) ~/ (colWidth + 1).clamp(1, 99);

      return (contentWidth: targetContent, colWidth: colWidth, cols: cols);
    }

    final initialLayout = computeLayout();

    // Use SelectableGridPrompt with custom chip rendering
    final gridPrompt = SelectableGridPrompt<String>(
      title: prompt,
      items: tags,
      theme: theme,
      multiSelect: true,
      columns: initialLayout.cols,
      cellWidth: initialLayout.colWidth,
    );

    // Run with custom rendering for chip style
    return gridPrompt.runCustom(
      renderContent: (ctx) {
        final l = computeLayout();
        // Update columns in case terminal resized
        gridPrompt.grid.columns = l.cols;

        // Summary line
        final count = gridPrompt.selection.count;
        final summary = count == 0
            ? ctx.lb.emptyMessage('none selected')
            : '${theme.accent}$count selected${theme.reset}';
        ctx.gutterLine('${HintFormat.comma([
              'Space to toggle',
              'Enter to confirm',
              'Esc to cancel'
            ], theme)}  $summary');

        ctx.writeConnector();

        final rows = (tags.length / l.cols).ceil().clamp(1, 999);
        for (var r = 0; r < rows; r++) {
          final pieces = <String>[];
          for (var c = 0; c < l.cols; c++) {
            final idx = r * l.cols + c;
            if (idx >= tags.length) break;
            pieces.add(renderChip(
              tags[idx],
              gridPrompt.grid.isFocused(idx),
              gridPrompt.selection.isSelected(idx),
              l.colWidth,
            ));
          }
          ctx.gutterLine(pieces.join(' '));
        }
      },
    );
  }
}
