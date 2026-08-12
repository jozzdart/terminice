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
    var width = safeColumns[column].length;
    for (final row in safeEntries) {
      if (row[column].length > width) width = row[column].length;
    }
    return width;
  });

  String renderRow(List<String> row) {
    final cells = <String>[];
    for (var i = 0; i < row.length; i++) {
      final padding = widths[i] - row[i].length;
      switch (alignments[i]) {
        case ColumnAlign.left:
          cells.add('${row[i]}${' ' * padding}');
        case ColumnAlign.right:
          cells.add('${' ' * padding}${row[i]}');
        case ColumnAlign.center:
          final left = padding ~/ 2;
          cells.add('${' ' * left}${row[i]}${' ' * (padding - left)}');
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
