import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Provides the [cheatSheet] method for rendering reference tables.
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
  void cheatSheet(
    String prompt, {
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

    runWithExecutionMode<void>(
      rich: () => _richCheatSheet(
        prompt,
        entries: entries,
        columns: columns,
        alignments: alignments,
        zebraStripes: zebraStripes,
      ),
      line: () => _plainCheatSheet(
        prompt,
        entries: entries,
        columns: columns,
        alignments: alignments,
      ),
      unattended: () => _plainCheatSheet(
        prompt,
        entries: entries,
        columns: columns,
        alignments: alignments,
      ),
    );
  }

  void _richCheatSheet(
    String prompt, {
    required List<List<String>> entries,
    required List<String> columns,
    required List<ColumnAlign> alignments,
    required bool zebraStripes,
  }) {
    final theme = defaultTheme;
    final frame = FrameView(title: prompt, theme: theme);

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

void _plainCheatSheet(
  String prompt, {
  required List<List<String>> entries,
  required List<String> columns,
  required List<ColumnAlign> alignments,
}) {
  final safeColumns = columns.map(terminalSafeLineText).toList();
  final safeEntries = entries
      .map((row) => row.map(terminalSafeLineText).toList())
      .toList(growable: false);
  final widths = List<int>.generate(safeColumns.length, (column) {
    var width = visibleLength(safeColumns[column]);
    for (final row in safeEntries) {
      final cellWidth = visibleLength(row[column]);
      if (cellWidth > width) width = cellWidth;
    }
    return width;
  });

  String renderRow(List<String> row) {
    final cells = <String>[];
    for (var i = 0; i < row.length; i++) {
      switch (alignments[i]) {
        case ColumnAlign.left:
          cells.add(padRight(row[i], widths[i]));
        case ColumnAlign.right:
          cells.add(padLeft(row[i], widths[i]));
        case ColumnAlign.center:
          cells.add(padVisibleCenter(row[i], widths[i]));
      }
    }
    return cells.join(' | ');
  }

  final output = TerminalContext.output;
  output.writeln(terminalSafeLineText(prompt));
  output.writeln(renderRow(safeColumns));
  output.writeln(widths.map((width) => '-' * width).join('-+-'));
  for (final row in safeEntries) {
    output.writeln(renderRow(row));
  }
}
