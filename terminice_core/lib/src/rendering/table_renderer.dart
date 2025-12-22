import 'dart:math';

import 'package:terminice_core/terminice_core.dart';
import 'text_utils.dart' as text;

/// Alignment options for table columns.
enum ColumnAlign { left, center, right }

/// Configuration for a table column.
class ColumnConfig {
  /// The header text for this column.
  final String header;

  /// Alignment of content in this column.
  final ColumnAlign align;

  /// Minimum width for this column (optional).
  final int? minWidth;

  /// Maximum width for this column (optional).
  final int? maxWidth;

  const ColumnConfig(
    this.header, {
    this.align = ColumnAlign.left,
    this.minWidth,
    this.maxWidth,
  });

  /// Creates a left-aligned column.
  const ColumnConfig.left(this.header, {this.minWidth, this.maxWidth})
      : align = ColumnAlign.left;

  /// Creates a center-aligned column.
  const ColumnConfig.center(this.header, {this.minWidth, this.maxWidth})
      : align = ColumnAlign.center;

  /// Creates a right-aligned column.
  const ColumnConfig.right(this.header, {this.minWidth, this.maxWidth})
      : align = ColumnAlign.right;
}

/// Centralized table rendering utility.
///
/// Provides consistent table layout across views/prompts:
/// - Column width computation (ANSI-aware)
/// - Styled header row
/// - Connector lines
/// - Zebra-striped data rows
/// - Flexible alignment per column
///
/// **Usage:**
/// ```dart
/// final renderer = TableRenderer(
///   columns: [
///     ColumnConfig.left('Name'),
///     ColumnConfig.center('Status'),
///     ColumnConfig.right('Count'),
///   ],
///   theme: PromptTheme.dark,
/// );
///
/// // Compute widths from data
/// renderer.computeWidths(rows);
///
/// // Build individual lines
/// final header = renderer.headerLine();
/// final connector = renderer.connectorLine();
/// for (var i = 0; i < rows.length; i++) {
///   final row = renderer.rowLine(rows[i], index: i);
/// }
/// ```
class TableRenderer {
  /// Column configurations.
  final List<ColumnConfig> columns;

  /// Theme for styling.
  final PromptTheme theme;

  /// Whether to apply zebra stripes to rows.
  final bool zebraStripes;

  /// Padding added to each side of cell content.
  final int cellPadding;

  /// Computed column widths (set by [computeWidths] or [setWidths]).
  List<int> _widths = [];

  TableRenderer({
    required this.columns,
    this.theme = PromptTheme.dark,
    this.zebraStripes = true,
    this.cellPadding = 0,
  });

  /// Creates a renderer from simple string headers.
  ///
  /// All columns will be left-aligned by default.
  factory TableRenderer.fromHeaders(
    List<String> headers, {
    PromptTheme theme = PromptTheme.dark,
    bool zebraStripes = true,
    int cellPadding = 0,
  }) {
    return TableRenderer(
      columns: headers.map((h) => ColumnConfig(h)).toList(),
      theme: theme,
      zebraStripes: zebraStripes,
      cellPadding: cellPadding,
    );
  }

  /// Creates a renderer with custom alignments.
  ///
  /// If [alignments] is shorter than [headers], remaining columns use left alignment.
  factory TableRenderer.withAlignments(
    List<String> headers,
    List<ColumnAlign> alignments, {
    PromptTheme theme = PromptTheme.dark,
    bool zebraStripes = true,
    int cellPadding = 0,
  }) {
    final configs = <ColumnConfig>[];
    for (var i = 0; i < headers.length; i++) {
      final align = i < alignments.length ? alignments[i] : ColumnAlign.left;
      configs.add(ColumnConfig(headers[i], align: align));
    }
    return TableRenderer(
      columns: configs,
      theme: theme,
      zebraStripes: zebraStripes,
      cellPadding: cellPadding,
    );
  }

  /// Number of columns.
  int get columnCount => columns.length;

  /// Current computed widths.
  List<int> get widths => List.unmodifiable(_widths);

  /// Total width of the table content (excluding outer frame).
  int get contentWidth {
    if (_widths.isEmpty) return 0;
    // widths + separators (' │ ' = 3 chars between each)
    return _widths.fold<int>(0, (sum, w) => sum + w) + (columns.length - 1) * 3;
  }

  // ============================================================================
  // WIDTH COMPUTATION
  // ============================================================================

  /// Computes column widths based on header and row data.
  ///
  /// Respects [ColumnConfig.minWidth] and [ColumnConfig.maxWidth] constraints.
  void computeWidths(List<List<String>> rows) {
    _widths = List.generate(columns.length, (i) {
      final config = columns[i];
      int width = text.visibleLength(config.header);

      for (final row in rows) {
        if (i < row.length) {
          width = max(width, text.visibleLength(row[i]));
        }
      }

      // Apply constraints
      if (config.minWidth != null) {
        width = max(width, config.minWidth!);
      }
      if (config.maxWidth != null) {
        width = min(width, config.maxWidth!);
      }

      return width + cellPadding;
    });
  }

  /// Sets column widths explicitly.
  void setWidths(List<int> widths) {
    _widths = List.from(widths);
  }

  // ============================================================================
  // LINE RENDERING
  // ============================================================================

  /// Builds the header row line.
  String headerLine({String? leadingGutter}) {
    final style = theme.style;
    final buffer = StringBuffer();

    // Leading gutter (frame border)
    if (leadingGutter != null) {
      buffer.write(leadingGutter);
    } else {
      buffer.write('${theme.gray}${style.borderVertical}${theme.reset} ');
    }

    for (var i = 0; i < columns.length; i++) {
      if (i > 0) {
        buffer.write(' ${theme.gray}${style.borderVertical}${theme.reset} ');
      }
      buffer.write('${theme.bold}${theme.accent}');
      buffer.write(_padCell(columns[i].header, i));
      buffer.write(theme.reset);
    }

    return buffer.toString();
  }

  /// Builds the connector line below the header.
  String connectorLine({String? leadingGutter}) {
    final style = theme.style;
    final width = contentWidth + 2; // +2 for spacing
    final prefix =
        leadingGutter ?? '${theme.gray}${style.borderConnector}${theme.reset}';
    return '$prefix${'─' * width}';
  }

  /// Builds a data row line.
  ///
  /// [index] is used for zebra striping (odd rows are dimmed).
  /// [cells] should match the column count; missing cells render as empty.
  String rowLine(
    List<String> cells, {
    int index = 0,
    String? leadingGutter,
    bool forceStripe = false,
  }) {
    final style = theme.style;
    final buffer = StringBuffer();

    // Leading gutter
    if (leadingGutter != null) {
      buffer.write(leadingGutter);
    } else {
      buffer.write('${theme.gray}${style.borderVertical}${theme.reset} ');
    }

    final stripe = (zebraStripes && index % 2 == 1) || forceStripe;
    final prefix = stripe ? theme.dim : '';
    final suffix = stripe ? theme.reset : '';

    for (var i = 0; i < columns.length; i++) {
      if (i > 0) {
        buffer.write(' ${theme.gray}${style.borderVertical}${theme.reset} ');
      }
      final cell = i < cells.length ? cells[i] : '';
      buffer.write(prefix);
      buffer.write(_padCell(cell, i));
      buffer.write(suffix);
    }

    return buffer.toString();
  }

  /// Builds a row with selection highlighting.
  ///
  /// Used for interactive table views where one cell is selected.
  String selectableRowLine(
    List<String> cells, {
    required int index,
    int? selectedColumn,
    bool isEditing = false,
    String editBuffer = '',
    String? leadingGutter,
  }) {
    final style = theme.style;
    final buffer = StringBuffer();

    // Leading gutter
    if (leadingGutter != null) {
      buffer.write(leadingGutter);
    } else {
      buffer.write('${theme.gray}${style.borderVertical}${theme.reset} ');
    }

    final stripe = zebraStripes && index % 2 == 1;
    final prefix = stripe ? theme.dim : '';
    final suffix = stripe ? theme.reset : '';

    for (var i = 0; i < columns.length; i++) {
      if (i > 0) {
        buffer.write(' ${theme.gray}${style.borderVertical}${theme.reset} ');
      }

      final isSelected = selectedColumn == i;
      final cell = i < cells.length ? cells[i] : '';
      final content = (isSelected && isEditing) ? editBuffer : cell;

      buffer.write(prefix);

      if (isSelected) {
        buffer.write(_renderSelectedCell(content, i, isEditing));
      } else {
        buffer.write(_padCell(cell, i));
      }

      buffer.write(suffix);
    }

    return buffer.toString();
  }

  // ============================================================================
  // ALL-IN-ONE BUILDERS
  // ============================================================================

  /// Builds a complete table as a list of lines.
  ///
  /// Includes: header, connector, and all data rows.
  /// Does NOT include title frame - use with [FramedLayout] for full styling.
  List<String> buildLines(List<List<String>> rows) {
    if (_widths.isEmpty) {
      computeWidths(rows);
    }

    final lines = <String>[];
    lines.add(headerLine());
    lines.add(connectorLine());
    for (var i = 0; i < rows.length; i++) {
      lines.add(rowLine(rows[i], index: i));
    }
    return lines;
  }

  /// Writes the table header and connector to [out].
  void writeHeader(void Function(String) out) {
    out(headerLine());
    out(connectorLine());
  }

  /// Writes all data rows to [out].
  void writeRows(List<List<String>> rows, void Function(String) out) {
    for (var i = 0; i < rows.length; i++) {
      out(rowLine(rows[i], index: i));
    }
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  String _padCell(String content, int columnIndex) {
    if (columnIndex >= _widths.length) return content;

    final width = _widths[columnIndex];
    final align = columns[columnIndex].align;

    // Truncate if needed
    final visible = text.stripAnsi(content);
    String displayContent = content;
    if (visible.length > width) {
      displayContent = '${visible.substring(0, max(0, width - 1))}…';
    }

    switch (align) {
      case ColumnAlign.left:
        return text.padVisibleRight(displayContent, width);
      case ColumnAlign.center:
        return text.padVisibleCenter(displayContent, width);
      case ColumnAlign.right:
        return text.padVisibleLeft(displayContent, width);
    }
  }

  String _renderSelectedCell(String content, int columnIndex, bool isEditing) {
    if (columnIndex >= _widths.length) return content;

    final width = _widths[columnIndex];
    final style = theme.style;

    // Truncate visible content
    final visible = text.stripAnsi(content);
    String displayText = visible;
    if (visible.length > width - 1) {
      displayText = '${visible.substring(0, max(0, width - 2))}…';
    }

    if (isEditing) {
      // Show cursor indicator
      final cursor = '${theme.accent}|${theme.reset}';
      final base = displayText + cursor;
      final padded = text.padVisibleRight(base, width);
      if (style.useInverseHighlight) {
        return '${theme.inverse}$padded${theme.reset}';
      }
      return '${theme.selection}$padded${theme.reset}';
    }

    // Selected but not editing
    final padded = text.padVisibleRight(displayText, width);
    if (style.useInverseHighlight) {
      return '${theme.inverse}$padded${theme.reset}';
    }
    return '${theme.selection}$padded${theme.reset}';
  }
}
