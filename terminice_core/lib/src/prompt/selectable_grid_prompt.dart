import 'dart:math';

import 'package:terminice_core/terminice_core.dart';

/// SelectableGridPrompt – composable system for grid-based selection prompts.
///
/// Composes:
/// - [GridNavigator] for 2D navigation with wrapping
/// - [SelectionController] for selection state
/// - [KeyBindings] for input handling
/// - [FrameView] for rendering
/// - [PromptRunner] for the interactive loop
///
/// **Design principles:**
/// - Composition over inheritance
/// - Separation of concerns
/// - DRY: Centralizes grid selection patterns
/// - Parallel to SelectableListPrompt for lists
///
/// **Usage:**
/// ```dart
/// final prompt = SelectableGridPrompt<String>(
///   title: 'Pick colors',
///   items: ['Red', 'Green', 'Blue', 'Yellow'],
///   columns: 2,
///   multiSelect: true,
/// );
///
/// final result = prompt.run(
///   renderCell: (ctx, item, index, focused, selected, cellWidth) {
///     // Custom cell rendering
///   },
/// );
/// ```
///
/// **Auto layout:**
/// ```dart
/// final prompt = SelectableGridPrompt.responsive(
///   title: 'Select',
///   items: items,
///   cellWidth: 20,
/// );
/// ```
class SelectableGridPrompt<T> {
  /// Title for the frame header.
  final String title;

  /// Items to select from.
  final List<T> items;

  /// Theme for styling.
  final PromptTheme theme;

  /// Whether multiple items can be selected.
  final bool multiSelect;

  /// Number of columns (0 = auto-calculate).
  final int columns;

  /// Fixed cell width (null = auto-calculate from items).
  final int? cellWidth;

  /// Maximum columns for auto layout.
  final int? maxColumns;

  /// Initial selection indices.
  final Set<int>? initialSelection;

  /// Hint style for key bindings display.
  final HintStyle hintStyle;

  // ──────────────────────────────────────────────────────────────────────────
  // INTERNAL STATE
  // ──────────────────────────────────────────────────────────────────────────

  late GridNavigator _grid;
  late SelectionController _selection;
  late KeyBindings _bindings;
  late int _computedCellWidth;
  late int _computedColumns;
  bool _cancelled = false;

  SelectableGridPrompt({
    required this.title,
    required this.items,
    this.theme = PromptTheme.dark,
    this.multiSelect = false,
    this.columns = 0,
    this.cellWidth,
    this.maxColumns,
    this.initialSelection,
    this.hintStyle = HintStyle.grid,
  });

  /// Creates a responsive grid that adapts to terminal width.
  factory SelectableGridPrompt.responsive({
    required String title,
    required List<T> items,
    required int cellWidth,
    PromptTheme theme = PromptTheme.dark,
    bool multiSelect = false,
    int? maxColumns,
    Set<int>? initialSelection,
    HintStyle hintStyle = HintStyle.grid,
  }) {
    return SelectableGridPrompt(
      title: title,
      items: items,
      theme: theme,
      multiSelect: multiSelect,
      columns: 0, // auto
      cellWidth: cellWidth,
      maxColumns: maxColumns,
      initialSelection: initialSelection,
      hintStyle: hintStyle,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ACCESSORS
  // ──────────────────────────────────────────────────────────────────────────

  /// Current grid navigation state.
  GridNavigator get grid => _grid;

  /// Current selection state.
  SelectionController get selection => _selection;

  /// Current key bindings.
  KeyBindings get bindings => _bindings;

  /// Computed cell width.
  int get computedCellWidth => _computedCellWidth;

  /// Computed column count.
  int get computedColumns => _computedColumns;

  /// Whether the prompt was cancelled.
  bool get wasCancelled => _cancelled;

  // ──────────────────────────────────────────────────────────────────────────
  // RUN
  // ──────────────────────────────────────────────────────────────────────────

  /// Runs the grid prompt.
  ///
  /// [renderCell] - Custom cell renderer. If null, uses default style.
  /// [itemLabel] - Converts item to string for display.
  /// [extraBindings] - Additional key bindings.
  /// [cellSeparator] - Separator between cells (default: │).
  /// [rowSeparator] - Whether to show row separators.
  ///
  /// Returns selected items on confirm, empty list on cancel.
  List<T> run({
    void Function(
      FrameContext ctx,
      T item,
      int index,
      bool isFocused,
      bool isSelected,
      int cellWidth,
    )? renderCell,
    String Function(T item)? itemLabel,
    KeyBindings? extraBindings,
    bool showCellSeparators = true,
    bool showRowSeparators = true,
  }) {
    if (items.isEmpty) return [];

    _initState();

    if (extraBindings != null) {
      _bindings = _bindings + extraBindings;
    }

    final frame = FrameView(
      title: title,
      theme: theme,
      bindings: _bindings,
      hintStyle: hintStyle,
    );

    final colSep = showCellSeparators ? '${theme.gray}│${theme.reset}' : '';

    void render(RenderOutput out) {
      // Recompute columns if auto
      if (columns <= 0) {
        _recomputeLayout();
        _grid.columns = _computedColumns;
      }

      final rows = _grid.rows;

      frame.render(out, (ctx) {
        for (int r = 0; r < rows; r++) {
          final buffer = StringBuffer(ctx.lb.gutter());

          for (int c = 0; c < _computedColumns; c++) {
            final idx = r * _computedColumns + c;

            if (idx >= items.length) {
              // Empty slot for alignment
              buffer.write(''.padRight(_computedCellWidth));
            } else {
              final isFocused = _grid.isFocused(idx);
              final isSelected = _selection.isSelected(idx);

              if (renderCell != null) {
                // Custom rendering - need to capture to string
                final cellContent = _renderCellToString(
                  items[idx],
                  idx,
                  isFocused,
                  isSelected,
                  itemLabel,
                );
                buffer.write(cellContent);
              } else {
                // Default rendering
                final label =
                    itemLabel?.call(items[idx]) ?? items[idx].toString();
                buffer.write(_defaultCellRenderer(
                  label,
                  isFocused,
                  isSelected,
                ));
              }
            }

            if (c != _computedColumns - 1) {
              buffer.write(colSep);
            }
          }

          ctx.line(buffer.toString());

          // Row separator
          if (showRowSeparators && r != rows - 1) {
            final rowLine = List.generate(
              _computedColumns,
              (i) => '${theme.gray}${'─' * _computedCellWidth}${theme.reset}',
            ).join('${theme.gray}┼${theme.reset}');
            ctx.gutterLine(rowLine);
          }
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: render,
      bindings: _bindings,
    );

    if (_cancelled || result == PromptResult.cancelled) {
      return [];
    }

    return _selection.getSelectedMany(
      items,
      fallbackIndex: _grid.focusedIndex,
    );
  }

  /// Runs with custom full-render control (for complex grids like ChoiceMap).
  ///
  /// [renderContent] receives the FrameContext for complete control.
  List<T> runCustom({
    required void Function(FrameContext ctx) renderContent,
    KeyBindings? extraBindings,
  }) {
    if (items.isEmpty) return [];

    _initState();

    if (extraBindings != null) {
      _bindings = _bindings + extraBindings;
    }

    final frame = FrameView(
      title: title,
      theme: theme,
      bindings: _bindings,
      hintStyle: hintStyle,
    );

    void render(RenderOutput out) {
      if (columns <= 0) {
        _recomputeLayout();
        _grid.columns = _computedColumns;
      }

      frame.render(out, renderContent);
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: render,
      bindings: _bindings,
    );

    if (_cancelled || result == PromptResult.cancelled) {
      return [];
    }

    return _selection.getSelectedMany(
      items,
      fallbackIndex: _grid.focusedIndex,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ──────────────────────────────────────────────────────────────────────────

  void _initState() {
    _cancelled = false;

    _computeLayout();

    _grid = GridNavigator(
      itemCount: items.length,
      columns: _computedColumns,
    );

    _selection = SelectionController(
      multiSelect: multiSelect,
      initialSelection: _validatedInitialSelection(),
    );

    _bindings = _createDefaultBindings();
  }

  void _computeLayout() {
    // Cell width: explicit, or based on longest item + padding
    _computedCellWidth = cellWidth ??
        (items.fold<int>(0, (m, item) => max(m, item.toString().length)) + 4)
            .clamp(10, 40);

    // Columns: explicit, or auto-calculate from terminal width
    if (columns > 0) {
      _computedColumns = columns;
    } else {
      _recomputeLayout();
    }
  }

  void _recomputeLayout() {
    final termWidth = TerminalInfo.columns;
    const leftPrefix = 2;
    const sepWidth = 1;
    final unit = _computedCellWidth + sepWidth;
    final colsByWidth = max(1, ((termWidth - leftPrefix) + sepWidth) ~/ unit);

    // Aim for balanced grid
    final desired = max(2, min(items.length, sqrt(items.length).ceil()));
    final cap = (maxColumns != null && maxColumns! > 0) ? maxColumns! : desired;
    _computedColumns = min(colsByWidth, cap);
  }

  Set<int>? _validatedInitialSelection() {
    if (initialSelection == null) return null;
    return initialSelection!.where((i) => i >= 0 && i < items.length).toSet();
  }

  KeyBindings _createDefaultBindings() {
    return KeyBindings.gridSelection(
      onUp: () => _grid.moveUp(),
      onDown: () => _grid.moveDown(),
      onLeft: () => _grid.moveLeft(),
      onRight: () => _grid.moveRight(),
      onToggle:
          multiSelect ? () => _selection.toggle(_grid.focusedIndex) : null,
      showToggleHint: multiSelect,
      onCancel: () => _cancelled = true,
    );
  }

  String _defaultCellRenderer(String label, bool isFocused, bool isSelected) {
    final check = multiSelect ? (isSelected ? '[x] ' : '[ ] ') : '';
    final maxText = _computedCellWidth - (multiSelect ? 4 : 2);
    final visible =
        label.length > maxText ? '${label.substring(0, maxText - 1)}…' : label;
    final padded = (check + visible).padRight(_computedCellWidth);

    if (isFocused) {
      if (theme.style.useInverseHighlight) {
        return '${theme.inverse}$padded${theme.reset}';
      }
      return '${theme.selection}$padded${theme.reset}';
    }
    return padded;
  }

  String _renderCellToString(
    T item,
    int index,
    bool isFocused,
    bool isSelected,
    String Function(T)? itemLabel,
  ) {
    final label = itemLabel?.call(item) ?? item.toString();
    return _defaultCellRenderer(label, isFocused, isSelected);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STATIC FACTORIES
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a single-select grid prompt.
  static T? single<T>({
    required String title,
    required List<T> items,
    PromptTheme theme = PromptTheme.dark,
    int columns = 0,
    int? cellWidth,
    int? maxColumns,
    String Function(T)? labelBuilder,
  }) {
    final prompt = SelectableGridPrompt<T>(
      title: title,
      items: items,
      theme: theme,
      multiSelect: false,
      columns: columns,
      cellWidth: cellWidth,
      maxColumns: maxColumns,
    );

    final result = prompt.run(itemLabel: labelBuilder);
    return result.isEmpty ? null : result.first;
  }

  /// Creates a multi-select grid prompt.
  static List<T> multi<T>({
    required String title,
    required List<T> items,
    PromptTheme theme = PromptTheme.dark,
    int columns = 0,
    int? cellWidth,
    int? maxColumns,
    Set<int>? initialSelection,
    String Function(T)? labelBuilder,
  }) {
    final prompt = SelectableGridPrompt<T>(
      title: title,
      items: items,
      theme: theme,
      multiSelect: true,
      columns: columns,
      cellWidth: cellWidth,
      maxColumns: maxColumns,
      initialSelection: initialSelection,
    );

    return prompt.run(itemLabel: labelBuilder);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EXTENSIONS FOR COMMON PATTERNS
// ════════════════════════════════════════════════════════════════════════════

/// Extension for tag-style grid rendering.
extension SelectableGridPromptTags<T> on SelectableGridPrompt<T> {
  /// Renders items as tag chips: [ tag ]
  String renderChip(
    T item,
    bool isFocused,
    bool isSelected, {
    String Function(T)? labelBuilder,
  }) {
    final label = labelBuilder?.call(item) ?? item.toString();
    final raw = '[ $label ]';
    final padding = (computedCellWidth - raw.length).clamp(0, 1000);
    final padded = raw + ' ' * padding;

    if (isFocused) {
      return '${theme.inverse}${theme.selection}$padded${theme.reset}';
    }
    if (isSelected) {
      return padded.replaceFirst(label, '${theme.accent}$label${theme.reset}');
    }
    return '${theme.dim}$padded${theme.reset}';
  }
}

/// Extension for card-style grid rendering (ChoiceMap pattern).
extension SelectableGridPromptCards<T> on SelectableGridPrompt<T> {
  /// Renders a two-line card with title and subtitle.
  ({String top, String bottom}) renderCard({
    required String title,
    String? subtitle,
    required bool isFocused,
    required bool isSelected,
  }) {
    final boxWidth = computedCellWidth;
    final check = multiSelect ? (isSelected ? '[x] ' : '[ ] ') : '';
    final titleMax = boxWidth - (multiSelect ? 4 : 0);

    String pad(String text, int width) {
      if (text.length > width) {
        if (width <= 1) return text.substring(0, 1);
        return '${text.substring(0, width - 1)}…';
      }
      return text.padRight(width);
    }

    final titleStr = pad(check + title, titleMax);
    final subtitleStr = pad(subtitle ?? '', boxWidth).trimRight();

    String paint(String s) {
      if (isFocused) {
        if (theme.style.useInverseHighlight) {
          return '${theme.inverse}$s${theme.reset}';
        }
        return '${theme.selection}$s${theme.reset}';
      }
      return s;
    }

    final top = paint(titleStr.padRight(boxWidth));
    final bottom =
        paint('${theme.dim}${subtitleStr.padRight(boxWidth)}${theme.reset}');
    return (top: top, bottom: bottom);
  }
}
