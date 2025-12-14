import 'dart:math';

/// Manages 2D grid navigation with predictable wrapping semantics.
///
/// ## When to use
/// Reach for [GridNavigator] when you render collections as a matrix (card
/// grids, emoji pickers, icon launchers, split panes). It keeps track of the
/// focused cell, handles wrapping in every direction, and keeps your widgets
/// free from manual row/column arithmetic.
///
/// ## Layout strategies
/// - Call the default constructor when you know the number of columns up front
/// - Use [GridNavigator.responsive] to derive a column count from terminal
///   width, cell width, and separators—perfect for adaptive layouts
/// - Use [GridNavigator.balanced] to quickly build a near-square grid without
///   thinking about math
///
/// ## Examples
/// ```dart
/// // Fixed columns (12 items shown as 3 rows of 4)
/// final grid = GridNavigator(itemCount: 12, columns: 4);
/// grid.moveRight(); // wraps to the next row when hitting an edge
/// grid.moveDown();  // wraps from bottom row back to top
///
/// // Responsive layout driven by terminal width
/// final adaptiveGrid = GridNavigator.responsive(
///   itemCount: items.length,
///   cellWidth: 20,
///   availableWidth: terminalWidth,
/// );
/// ```
///
/// ## Integration hints
/// Pair the navigator with a [SelectionController] (single or multi) to keep the
/// focused cell and the user selection in sync:
/// ```dart
/// final nav = GridNavigator(itemCount: icons.length, columns: 6);
/// final sel = SelectionController.multi();
///
/// KeyBindings.arrowKeys(
///   onLeft: nav.moveLeft,
///   onRight: nav.moveRight,
///   onUp: nav.moveUp,
///   onDown: nav.moveDown,
///   onSelect: () => sel.toggle(nav.focusedIndex),
/// );
/// ```
///
/// The navigator only knows about indices, so it is agnostic to the type of the
/// widgets/items you render—ideal for downstream consumers on pub.dev.
class GridNavigator {
  /// Total number of items in the grid.
  int _itemCount;

  /// Number of columns in the grid.
  int _columns;

  /// Current focused index.
  int _focusedIndex;

  /// Creates a grid navigation with fixed column count.
  ///
  /// [itemCount] is the total number of items.
  /// [columns] is the number of columns (must be >= 1).
  /// [initialIndex] is the starting focus (defaults to 0).
  GridNavigator({
    required int itemCount,
    required int columns,
    int initialIndex = 0,
  })  : _itemCount = max(0, itemCount),
        _columns = max(1, columns),
        _focusedIndex = 0 {
    _focusedIndex = _itemCount > 0 ? initialIndex.clamp(0, _itemCount - 1) : 0;
  }

  /// Creates a grid navigation with responsive column calculation.
  ///
  /// Calculates columns based on available width and cell width.
  /// Optionally caps columns with [maxColumns].
  factory GridNavigator.responsive({
    required int itemCount,
    required int cellWidth,
    required int availableWidth,
    int? maxColumns,
    int initialIndex = 0,
    int separatorWidth = 1,
    int prefixWidth = 2,
  }) {
    final effectiveWidth = availableWidth - prefixWidth;
    final unit = cellWidth + separatorWidth;
    var cols = max(1, (effectiveWidth + separatorWidth) ~/ unit);

    // Apply optional cap
    if (maxColumns != null && maxColumns > 0) {
      cols = min(cols, maxColumns);
    }

    // Also cap to item count (no point having more columns than items)
    cols = min(cols, max(1, itemCount));

    return GridNavigator(
      itemCount: itemCount,
      columns: cols,
      initialIndex: initialIndex,
    );
  }

  /// Creates a balanced grid (roughly square).
  ///
  /// Calculates columns to create a balanced grid, optionally
  /// constrained by available width and max columns.
  factory GridNavigator.balanced({
    required int itemCount,
    int? cellWidth,
    int? availableWidth,
    int? maxColumns,
    int initialIndex = 0,
  }) {
    // Aim for roughly sqrt(itemCount) columns
    var cols = max(1, sqrt(itemCount).ceil());

    // Constrain by available width if provided
    if (cellWidth != null && availableWidth != null) {
      final maxByWidth = max(1, (availableWidth - 2) ~/ (cellWidth + 1));
      cols = min(cols, maxByWidth);
    }

    // Apply optional cap
    if (maxColumns != null && maxColumns > 0) {
      cols = min(cols, maxColumns);
    }

    // Cap to item count
    cols = min(cols, max(1, itemCount));

    return GridNavigator(
      itemCount: itemCount,
      columns: cols,
      initialIndex: initialIndex,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GETTERS & SETTERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Current focused index.
  int get focusedIndex => _focusedIndex;

  /// Total number of items.
  int get itemCount => _itemCount;

  /// Number of columns.
  int get columns => _columns;

  /// Number of rows (calculated from item count and columns).
  int get rows =>
      _itemCount == 0 ? 0 : ((_itemCount + _columns - 1) ~/ _columns);

  /// Current focused row (0-indexed).
  int get focusedRow => _focusedIndex ~/ _columns;

  /// Current focused column (0-indexed).
  int get focusedColumn => _focusedIndex % _columns;

  /// Whether the grid is empty.
  bool get isEmpty => _itemCount == 0;

  /// Whether the grid is not empty.
  bool get isNotEmpty => _itemCount > 0;

  /// Updates the column count.
  set columns(int value) {
    _columns = max(1, value);
  }

  /// Updates the item count.
  ///
  /// Clamps focus to valid range.
  set itemCount(int value) {
    _itemCount = max(0, value);
    if (_itemCount == 0) {
      _focusedIndex = 0;
    } else {
      _focusedIndex = _focusedIndex.clamp(0, _itemCount - 1);
    }
  }

  /// Checks if an index is currently focused.
  bool isFocused(int index) => index == _focusedIndex;

  // ──────────────────────────────────────────────────────────────────────────
  // NAVIGATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Moves focus left by one cell with wrapping.
  ///
  /// At the start of a row, wraps to the end of the previous row.
  /// At item 0, wraps to the last item.
  void moveLeft() {
    if (_itemCount == 0) return;
    _focusedIndex = _focusedIndex == 0 ? _itemCount - 1 : _focusedIndex - 1;
  }

  /// Moves focus right by one cell with wrapping.
  ///
  /// At the end of a row, wraps to the start of the next row.
  /// At the last item, wraps to item 0.
  void moveRight() {
    if (_itemCount == 0) return;
    _focusedIndex = _focusedIndex == _itemCount - 1 ? 0 : _focusedIndex + 1;
  }

  /// Moves focus up by one row with wrapping.
  ///
  /// Maintains the same column position when possible.
  /// Wraps from top row to bottom row.
  void moveUp() {
    if (_itemCount == 0) return;

    final col = _focusedIndex % _columns;
    var row = _focusedIndex ~/ _columns;
    final totalRows = rows;

    // Try each row above, wrapping around
    for (var i = 0; i < totalRows; i++) {
      row = (row - 1 + totalRows) % totalRows;
      final candidate = row * _columns + col;
      if (candidate < _itemCount) {
        _focusedIndex = candidate;
        return;
      }
    }
  }

  /// Moves focus down by one row with wrapping.
  ///
  /// Maintains the same column position when possible.
  /// Wraps from bottom row to top row.
  void moveDown() {
    if (_itemCount == 0) return;

    final col = _focusedIndex % _columns;
    var row = _focusedIndex ~/ _columns;
    final totalRows = rows;

    // Try each row below, wrapping around
    for (var i = 0; i < totalRows; i++) {
      row = (row + 1) % totalRows;
      final candidate = row * _columns + col;
      if (candidate < _itemCount) {
        _focusedIndex = candidate;
        return;
      }
    }
  }

  /// Jumps to a specific index (clamped to valid range).
  void jumpTo(int index) {
    if (_itemCount == 0) return;
    _focusedIndex = index.clamp(0, _itemCount - 1);
  }

  /// Jumps to a specific cell by row and column.
  ///
  /// If the cell is out of bounds, jumps to the nearest valid cell.
  void jumpToCell(int row, int col) {
    if (_itemCount == 0) return;
    final targetRow = row.clamp(0, rows - 1);
    final targetCol = col.clamp(0, _columns - 1);
    final index = targetRow * _columns + targetCol;
    jumpTo(index);
  }

  /// Jumps to the first item.
  void jumpToFirst() => jumpTo(0);

  /// Jumps to the last item.
  void jumpToLast() => jumpTo(_itemCount - 1);

  /// Resets navigation to initial state.
  void reset({int initialIndex = 0}) {
    if (_itemCount == 0) {
      _focusedIndex = 0;
    } else {
      _focusedIndex = initialIndex.clamp(0, _itemCount - 1);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LAYOUT HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns layout information for rendering.
  GridLayout get layout => GridLayout(
        itemCount: _itemCount,
        columns: _columns,
        rows: rows,
        focusedIndex: _focusedIndex,
        focusedRow: focusedRow,
        focusedColumn: focusedColumn,
      );

  /// Iterates over rows, providing items for each row.
  ///
  /// Useful for rendering:
  /// ```dart
  /// for (final row in grid.rowsOf(items)) {
  ///   for (final (index, item) in row.items.indexed) {
  ///     final absoluteIndex = row.startIndex + index;
  ///     // render item
  ///   }
  /// }
  /// ```
  Iterable<GridRow<T>> rowsOf<T>(List<T> items) sync* {
    final totalRows = rows;
    for (var r = 0; r < totalRows; r++) {
      final startIdx = r * _columns;
      final endIdx = min(startIdx + _columns, _itemCount);
      final rowItems = items.sublist(
        startIdx.clamp(0, items.length),
        endIdx.clamp(0, items.length),
      );
      yield GridRow<T>(
        row: r,
        startIndex: startIdx,
        items: rowItems,
        isLastRow: r == totalRows - 1,
      );
    }
  }

  @override
  String toString() {
    return 'GridNavigation(items: $_itemCount, cols: $_columns, rows: $rows, focused: $_focusedIndex)';
  }
}

/// Layout information for a grid.
class GridLayout {
  /// Total number of items.
  final int itemCount;

  /// Number of columns.
  final int columns;

  /// Number of rows.
  final int rows;

  /// Currently focused item index.
  final int focusedIndex;

  /// Currently focused row.
  final int focusedRow;

  /// Currently focused column.
  final int focusedColumn;

  const GridLayout({
    required this.itemCount,
    required this.columns,
    required this.rows,
    required this.focusedIndex,
    required this.focusedRow,
    required this.focusedColumn,
  });

  /// Whether the grid is empty.
  bool get isEmpty => itemCount == 0;

  /// Index at a specific row and column (may exceed itemCount).
  int indexAt(int row, int col) => row * columns + col;

  /// Whether an index is within the item count.
  bool isValidIndex(int index) => index >= 0 && index < itemCount;
}

/// A row of items in a grid.
class GridRow<T> {
  /// Row index (0-indexed).
  final int row;

  /// Start index of this row in the full item list.
  final int startIndex;

  /// Items in this row.
  final List<T> items;

  /// Whether this is the last row.
  final bool isLastRow;

  const GridRow({
    required this.row,
    required this.startIndex,
    required this.items,
    required this.isLastRow,
  });

  /// Number of items in this row.
  int get length => items.length;

  /// Whether this row is empty.
  bool get isEmpty => items.isEmpty;
}
