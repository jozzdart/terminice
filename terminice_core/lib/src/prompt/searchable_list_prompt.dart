import 'package:terminice_core/terminice_core.dart';

/// SearchableListPrompt – composable system for searchable/filterable list prompts.
///
/// Extends the [SelectableListPrompt] pattern with:
/// - Real-time search/filter via [TextInputBuffer]
/// - Dynamic item filtering with constraint handling
/// - Toggleable search mode
///
/// **Design principles:**
/// - Composition over inheritance (uses same components as SelectableListPrompt)
/// - Separation of concerns (search is separate from selection/navigation)
/// - DRY: Centralizes the searchable list pattern
///
/// **Usage:**
/// ```dart
/// final prompt = SearchableListPrompt<String>(
///   title: 'Search and select',
///   items: allItems,
///   multiSelect: true,
/// );
///
/// final result = prompt.run();
/// ```
///
/// **With custom filter:**
/// ```dart
/// final result = prompt.run(
///   filter: (item, query) => item.name.contains(query),
///   itemLabel: (item) => item.name,
/// );
/// ```
class SearchableListPrompt<T> {
  /// Title for the frame header.
  final String title;

  /// All items (before filtering).
  final List<T> items;

  /// Theme for styling.
  final PromptTheme theme;

  /// Whether multiple items can be selected.
  final bool multiSelect;

  /// Maximum visible items (viewport size).
  final int maxVisible;

  /// Initial selection indices.
  final Set<int>? initialSelection;

  /// Whether search is initially enabled.
  final bool searchEnabled;

  /// Terminal lines to reserve for chrome.
  final int reservedLines;

  // ──────────────────────────────────────────────────────────────────────────
  // INTERNAL STATE
  // ──────────────────────────────────────────────────────────────────────────

  late ListNavigator _nav;
  late SelectionController _selection;
  late TextInputBuffer _queryInput;
  late KeyBindings _bindings;
  late List<T> _filtered;
  late bool _searchActive;
  bool _cancelled = false;

  SearchableListPrompt({
    required this.title,
    required this.items,
    this.theme = PromptTheme.dark,
    this.multiSelect = false,
    this.maxVisible = 10,
    this.initialSelection,
    this.searchEnabled = true,
    this.reservedLines = 7,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ACCESSORS
  // ──────────────────────────────────────────────────────────────────────────

  /// Current navigation state.
  ListNavigator get nav => _nav;

  /// Current selection state.
  SelectionController get selection => _selection;

  /// Current search query input.
  TextInputBuffer get queryInput => _queryInput;

  /// Current key bindings.
  KeyBindings get bindings => _bindings;

  /// Currently filtered items.
  List<T> get filtered => _filtered;

  /// Whether search is currently active.
  bool get isSearchActive => _searchActive;

  /// Whether the prompt was cancelled.
  bool get wasCancelled => _cancelled;

  // ──────────────────────────────────────────────────────────────────────────
  // RUN
  // ──────────────────────────────────────────────────────────────────────────

  /// Runs the searchable prompt.
  ///
  /// [filter] - Custom filter function. Defaults to case-insensitive contains.
  /// [itemLabel] - Converts item to string for display and default filter.
  /// [renderItem] - Custom item renderer. If null, uses default checkbox/select style.
  /// [highlightMatches] - Whether to highlight matching text in items.
  /// [extraBindings] - Additional key bindings.
  ///
  /// Returns selected items on confirm, empty list on cancel.
  List<T> run({
    bool Function(T item, String query)? filter,
    String Function(T item)? itemLabel,
    void Function(
      FrameContext ctx,
      T item,
      int absoluteIndex,
      bool isFocused,
      bool isSelected,
      String query,
    )? renderItem,
    bool highlightMatches = true,
    KeyBindings? extraBindings,
  }) {
    if (items.isEmpty) return [];

    _initState();

    // Default filter: case-insensitive contains on label
    final effectiveFilter = filter ??
        (T item, String query) {
          final label = itemLabel?.call(item) ?? item.toString();
          return label.toLowerCase().contains(query.toLowerCase());
        };

    void updateFilter() {
      if (!_searchActive || _queryInput.isEmpty) {
        _filtered = List.from(items);
      } else {
        final query = _queryInput.text;
        _filtered =
            items.where((item) => effectiveFilter(item, query)).toList();
      }
      _nav.itemCount = _filtered.length;
      _nav.reset();
      _selection.constrainTo(_filtered.length);
    }

    // Create bindings with search support
    _bindings = KeyBindings.searchableList(
      onUp: () => _nav.moveUp(),
      onDown: () => _nav.moveDown(),
      onSearchToggle: () {
        _searchActive = !_searchActive;
        if (!_searchActive) _queryInput.clear();
        updateFilter();
      },
      searchBuffer: _queryInput,
      isSearchEnabled: () => _searchActive,
      onSearchInput: updateFilter,
      onToggle: multiSelect && _filtered.isNotEmpty
          ? () => _selection.toggle(_nav.selectedIndex)
          : null,
      hasMultiSelect: multiSelect,
      onCancel: () => _cancelled = true,
    );

    if (extraBindings != null) {
      _bindings = _bindings + extraBindings;
    }

    final frame = FrameView(
      title: title,
      theme: theme,
      bindings: _bindings,
    );

    void render(RenderOutput out) {
      _nav.maxVisible =
          (TerminalInfo.rows - reservedLines).clamp(5, maxVisible);

      frame.render(out, (ctx) {
        // Search line
        ctx.searchLine(_queryInput.text, enabled: _searchActive);
        ctx.writeConnector();

        // Visible window
        final window = _nav.visibleWindow(_filtered);

        ctx.listWindow(
          window,
          selectedIndex: _nav.selectedIndex,
          renderItem: (T item, int absoluteIndex, bool isFocused) {
            final isSelected = _selection.isSelected(absoluteIndex);

            if (renderItem != null) {
              renderItem(
                ctx,
                item,
                absoluteIndex,
                isFocused,
                isSelected,
                _queryInput.text,
              );
            } else {
              // Default rendering
              final label = itemLabel?.call(item) ?? item.toString();
              final displayLabel = highlightMatches && _searchActive
                  ? highlightSubstring(label, _queryInput.text, theme)
                  : label;
              final checkbox = multiSelect ? ctx.lb.checkbox(isSelected) : ' ';
              final arrow = ctx.lb.arrow(isFocused);
              ctx.highlightedLine(
                '$arrow $checkbox $displayLabel',
                highlighted: isFocused,
              );
            }
          },
        );

        if (_filtered.isEmpty) {
          ctx.emptyMessage('no matches');
        }
      });
    }

    updateFilter();

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: render,
      bindings: _bindings,
    );

    if (_cancelled || result == PromptResult.cancelled || _filtered.isEmpty) {
      return [];
    }

    return _selection.getSelectedMany(
      _filtered,
      fallbackIndex: _nav.selectedIndex,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ──────────────────────────────────────────────────────────────────────────

  void _initState() {
    _cancelled = false;
    _filtered = List.from(items);
    _searchActive = searchEnabled;
    _queryInput = TextInputBuffer();

    _nav = ListNavigator(
      itemCount: _filtered.length,
      maxVisible: maxVisible,
    );

    _selection = SelectionController(
      multiSelect: multiSelect,
      initialSelection: _validatedInitialSelection(),
    );
  }

  Set<int>? _validatedInitialSelection() {
    if (initialSelection == null) return null;
    return initialSelection!.where((i) => i >= 0 && i < items.length).toSet();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STATIC FACTORIES
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a single-select searchable prompt.
  static T? single<T>({
    required String title,
    required List<T> items,
    PromptTheme theme = PromptTheme.dark,
    int maxVisible = 10,
    String Function(T)? labelBuilder,
    bool searchEnabled = true,
  }) {
    final prompt = SearchableListPrompt<T>(
      title: title,
      items: items,
      theme: theme,
      multiSelect: false,
      maxVisible: maxVisible,
      searchEnabled: searchEnabled,
    );

    final result = prompt.run(itemLabel: labelBuilder);
    return result.isEmpty ? null : result.first;
  }

  /// Creates a multi-select searchable prompt.
  static List<T> multi<T>({
    required String title,
    required List<T> items,
    PromptTheme theme = PromptTheme.dark,
    int maxVisible = 10,
    Set<int>? initialSelection,
    String Function(T)? labelBuilder,
    bool searchEnabled = true,
  }) {
    final prompt = SearchableListPrompt<T>(
      title: title,
      items: items,
      theme: theme,
      multiSelect: true,
      maxVisible: maxVisible,
      initialSelection: initialSelection,
      searchEnabled: searchEnabled,
    );

    return prompt.run(itemLabel: labelBuilder);
  }
}
