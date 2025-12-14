import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

extension CheatSheetExtensions on Terminice {
  /// Renders a framed cheat sheet table for quick reference material.
  ///
  /// Provide `entries` where each inner list represents a row and each value
  /// maps to the corresponding column defined in [columns]. Rows must contain
  /// the same number of cells as there are columns.
  ///
  /// ```dart
  /// terminice.cheatSheet(
  ///   title: 'Navigation Shortcuts',
  ///   columns: const ['Command', 'Shortcut', 'Description'],
  ///   entries: const [
  ///     ['List files', 'ls', 'Shows directory contents'],
  ///     ['Change dir', 'cd <path>', 'Moves into a folder'],
  ///   ],
  /// );
  /// ```
  ///
  /// The table automatically sizes columns, applies zebra striping, and renders
  /// within a `FrameView` that matches the current theme.
  void cheatSheet({
    required String title,
    required List<List<String>> entries,
    List<String> columns = const ['Command', 'Shortcut', 'Usage'],
    List<ColumnAlign>? columnAlignments,
    bool zebraStripes = true,
  }) {
    assert(columns.isNotEmpty, 'columns cannot be empty');
    assert(entries.every((row) => row.length == columns.length),
        'Each entry must match the column count (${columns.length}).');

    final alignments = columnAlignments ??
        List<ColumnAlign>.filled(columns.length, ColumnAlign.left);
    assert(alignments.length == columns.length,
        'columnAlignments must match the column count (${columns.length}).');

    final theme = defaultTheme;
    final frame = FrameView(title: title, theme: theme);

    frame.show((ctx) {
      final renderer = TableRenderer.withAlignments(
        columns,
        alignments,
        theme: theme,
        zebraStripes: zebraStripes,
      );

      renderer.computeWidths(entries);

      ctx.line(renderer.headerLine());
      ctx.line(renderer.connectorLine());

      for (var i = 0; i < entries.length; i++) {
        ctx.line(renderer.rowLine(entries[i], index: i));
      }
    });
  }
}
