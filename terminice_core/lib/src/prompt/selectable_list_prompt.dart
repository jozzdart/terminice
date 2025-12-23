import 'package:terminice_core/terminice_core.dart';

/// SelectableListPrompt – composable system for list-based selection prompts.
///
/// Eliminates boilerplate by composing:
/// - [ListNavigator] for viewport navigation
/// - [SelectionController] for selection state
/// - [KeyBindings] for input handling
/// - [FrameView] for rendering
/// - [PromptRunner] for the interactive loop
///
/// **Design principles:**
/// - Composition over inheritance
/// - Separation of concerns (each component remains independent)
/// - Builder pattern for flexible configuration
/// - DRY: Centralizes common prompt/view patterns
/// - Backward compatible: Individual components still work standalone
///
/// **Before SelectableListPrompt:**
/// ```dart
/// final nav = ListNavigator(itemCount: items.length, maxVisible: 10);
/// final selection = SelectionController.multi();
/// bool cancelled = false;
///
/// final bindings = KeyBindings.verticalNavigation(
///   onUp: () => nav.moveUp(),
///   onDown: () => nav.moveDown(),
/// ) + KeyBindings.toggle(
///   onToggle: () => selection.toggle(nav.selectedIndex),
/// ) + KeyBindings.prompt(onCancel: () => cancelled = true);
///
/// final frame = FrameView(title: title, theme: theme, bindings: bindings);
///
/// void render(RenderOutput out) {
///   frame.render(out, (ctx) {
///     final window = nav.visibleWindow(items);
///     ctx.listWindow(window, selectedIndex: nav.selectedIndex, ...);
///   });
/// }
///
/// final runner = PromptRunner(hideCursor: true);
/// final result = runner.runWithBindings(render: render, bindings: bindings);
///
/// if (cancelled || result == PromptResult.cancelled) return [];
/// return selection.getSelectedMany(items, fallbackIndex: nav.selectedIndex);
/// ```
///
/// **After SelectableListPrompt:**
/// ```dart
/// final prompt = SelectableListPrompt(
///   title: title,
///   items: items,
///   theme: theme,
///   multiSelect: true,
/// );
///
/// final result = prompt.run(
///   renderItem: (ctx, item, index, focused, selected) {
///     ctx.checkboxItem(item, focused: focused, checked: selected);
///   },
/// );
/// ```
///
/// **Advanced usage with custom content:**
/// ```dart
/// final prompt = SelectableListPrompt(
///   title: title,
///   items: items,
///   theme: theme,
/// );
///
/// final result = prompt.runCustom(
///   beforeItems: (ctx) => ctx.searchLine(query),
///   renderItem: (ctx, item, index, focused, selected) { ... },
///   afterItems: (ctx) => ctx.summaryLine(selection.count, items.length),
/// );
/// ```
class SelectableListPrompt<T> {
  /// Title for the frame header.
  final String title;

  /// Items to select from.
  final List<T> items;

  /// Theme for styling.
  final PromptTheme theme;

  /// Whether multiple items can be selected.
  final bool multiSelect;

  /// Maximum visible items (viewport size).
  final int maxVisible;

  /// Initial selection indices.
  final Set<int>? initialSelection;

  /// Terminal lines to reserve for chrome (headers, hints, etc).
  final int reservedLines;

  // ──────────────────────────────────────────────────────────────────────────
  // INTERNAL STATE (created on run)
  // ──────────────────────────────────────────────────────────────────────────

  late ListNavigator _nav;
  late SelectionController _selection;
  late KeyBindings _bindings;
  bool _cancelled = false;

  SelectableListPrompt({
    required this.title,
    required this.items,
    this.theme = PromptTheme.dark,
    this.multiSelect = false,
    this.maxVisible = 12,
    this.initialSelection,
    this.reservedLines = 7,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ACCESSORS (for advanced customization within callbacks)
  // ──────────────────────────────────────────────────────────────────────────

  /// Current navigation state. Available during [run] callbacks.
  ListNavigator get nav => _nav;

  /// Current selection state. Available during [run] callbacks.
  SelectionController get selection => _selection;

  /// Current key bindings. Available during [run] callbacks.
  KeyBindings get bindings => _bindings;

  /// Whether the prompt was cancelled. Available after [run] completes.
  bool get wasCancelled => _cancelled;

  // ──────────────────────────────────────────────────────────────────────────
  // SIMPLE RUN
  // ──────────────────────────────────────────────────────────────────────────

  /// Runs the prompt with simple item rendering.
  ///
  /// [renderItem] is called for each visible item:
  /// - `ctx`: FrameContext for rendering
  /// - `item`: The item being rendered
  /// - `absoluteIndex`: Index in the full list
  /// - `isFocused`: Whether this item is currently focused
  /// - `isSelected`: Whether this item is selected (multi-select)
  ///
  /// [extraBindings]: Additional key bindings to merge (e.g., 'A' for select all).
  ///
  /// Returns selected items on confirm, empty list on cancel.
  ///
  /// Example:
  /// ```dart
  /// final selected = prompt.run(
  ///   renderItem: (ctx, item, index, focused, selected) {
  ///     final arrow = ctx.lb.arrow(focused);
  ///     final check = ctx.lb.checkbox(selected);
  ///     ctx.highlightedLine('$arrow $check $item', highlighted: focused);
  ///   },
  /// );
  /// ```
  List<T> run({
    required void Function(
      FrameContext ctx,
      T item,
      int absoluteIndex,
      bool isFocused,
      bool isSelected,
    ) renderItem,
    KeyBindings? extraBindings,
  }) {
    return runCustom(
      renderItem: renderItem,
      extraBindings: extraBindings,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CUSTOM RUN (with hooks)
  // ──────────────────────────────────────────────────────────────────────────

  /// Runs the prompt with full customization hooks.
  ///
  /// [beforeItems]: Content to render before the item list (e.g., search bar, summary).
  /// [renderItem]: Called for each visible item.
  /// [afterItems]: Content to render after the item list (e.g., footer, stats).
  /// [extraBindings]: Additional key bindings to merge.
  /// [onBeforeRender]: Called before each render (e.g., update nav.maxVisible).
  ///
  /// Returns selected items on confirm, empty list on cancel.
  ///
  /// Example:
  /// ```dart
  /// final selected = prompt.runCustom(
  ///   beforeItems: (ctx) {
  ///     ctx.searchLine(queryInput.text, enabled: searchEnabled);
  ///     ctx.writeConnector();
  ///   },
  ///   renderItem: (ctx, item, index, focused, selected) {
  ///     ctx.checkboxItem(item.toString(), focused: focused, checked: selected);
  ///   },
  ///   afterItems: (ctx) {
  ///     if (items.isEmpty) ctx.emptyMessage('no matches');
  ///   },
  /// );
  /// ```
  List<T> runCustom({
    void Function(FrameContext ctx)? beforeItems,
    required void Function(
      FrameContext ctx,
      T item,
      int absoluteIndex,
      bool isFocused,
      bool isSelected,
    ) renderItem,
    void Function(FrameContext ctx)? afterItems,
    KeyBindings? extraBindings,
    void Function()? onBeforeRender,
  }) {
    if (items.isEmpty) return [];

    _initState();

    // Merge extra bindings if provided
    if (extraBindings != null) {
      _bindings = _bindings + extraBindings;
    }

    final frame = FrameView(
      title: title,
      theme: theme,
      bindings: _bindings,
    );

    void render(RenderOutput out) {
      // Hook for pre-render updates
      onBeforeRender?.call();

      // Responsive viewport adjustment
      _nav.maxVisible =
          (TerminalInfo.rows - reservedLines).clamp(5, maxVisible);

      frame.render(out, (ctx) {
        // Before items hook
        beforeItems?.call(ctx);

        // Get visible window
        final window = _nav.visibleWindow(items);

        // Overflow above indicator
        if (window.hasOverflowAbove) {
          ctx.overflowIndicator();
        }

        // Render visible items
        for (var i = 0; i < window.items.length; i++) {
          final absoluteIndex = window.start + i;
          final isFocused = _nav.isSelected(absoluteIndex);
          final isSelected = _selection.isSelected(absoluteIndex);
          renderItem(
              ctx, window.items[i], absoluteIndex, isFocused, isSelected);
        }

        // Overflow below indicator
        if (window.hasOverflowBelow) {
          ctx.overflowIndicator();
        }

        // After items hook
        afterItems?.call(ctx);
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
      fallbackIndex: _nav.selectedIndex,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ──────────────────────────────────────────────────────────────────────────

  void _initState() {
    _cancelled = false;

    _nav = ListNavigator(
      itemCount: items.length,
      maxVisible: maxVisible,
    );

    _selection = SelectionController(
      multiSelect: multiSelect,
      initialSelection: _validatedInitialSelection(),
    );

    _bindings = _createDefaultBindings();
  }

  Set<int>? _validatedInitialSelection() {
    if (initialSelection == null) return null;
    return initialSelection!.where((i) => i >= 0 && i < items.length).toSet();
  }

  KeyBindings _createDefaultBindings() {
    var bindings = KeyBindings.verticalNavigation(
      onUp: () => _nav.moveUp(),
      onDown: () => _nav.moveDown(),
    );

    if (multiSelect) {
      bindings = bindings +
          KeyBindings.toggle(
            onToggle: () => _selection.toggle(_nav.selectedIndex),
            hintDescription: 'toggle',
          );
    }

    bindings = bindings +
        KeyBindings.prompt(
          onCancel: () => _cancelled = true,
        );

    return bindings;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STATIC FACTORIES FOR COMMON PATTERNS
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a single-select prompt.
  ///
  /// Returns the selected item or null if cancelled.
  static T? single<T>({
    required String title,
    required List<T> items,
    PromptTheme theme = PromptTheme.dark,
    int maxVisible = 12,
    String Function(T)? labelBuilder,
  }) {
    final prompt = SelectableListPrompt<T>(
      title: title,
      items: items,
      theme: theme,
      multiSelect: false,
      maxVisible: maxVisible,
    );

    final result = prompt.run(
      renderItem: (ctx, item, index, focused, _) {
        final label = labelBuilder?.call(item) ?? item.toString();
        ctx.selectableItem(label, focused: focused);
      },
    );

    return result.isEmpty ? null : result.first;
  }

  /// Creates a multi-select prompt with checkbox UI.
  ///
  /// Returns selected items (empty if cancelled).
  static List<T> multi<T>({
    required String title,
    required List<T> items,
    PromptTheme theme = PromptTheme.dark,
    int maxVisible = 12,
    Set<int>? initialSelection,
    String Function(T)? labelBuilder,
    bool withSelectAll = true,
  }) {
    final prompt = SelectableListPrompt<T>(
      title: title,
      items: items,
      theme: theme,
      multiSelect: true,
      maxVisible: maxVisible,
      initialSelection: initialSelection,
    );

    KeyBindings? extra;
    if (withSelectAll) {
      extra = KeyBindings.letter(
        char: 'A',
        onPress: () => prompt.selection.toggleAll(items.length),
        hintDescription: 'select all / clear',
      );
    }

    return prompt.run(
      renderItem: (ctx, item, index, focused, selected) {
        final label = labelBuilder?.call(item) ?? item.toString();
        ctx.checkboxItem(label, focused: focused, checked: selected);
      },
      extraBindings: extra,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EXTENSIONS FOR COMMON PATTERNS
// ════════════════════════════════════════════════════════════════════════════

/// Extension for adding select-all functionality.
extension SelectableListPromptExt<T> on SelectableListPrompt<T> {
  /// Creates bindings for select all ('A' key).
  KeyBindings selectAllBindings(
      {String hintDescription = 'select all / clear'}) {
    return KeyBindings.letter(
      char: 'A',
      onPress: () => selection.toggleAll(items.length),
      hintDescription: hintDescription,
    );
  }

  /// Creates a summary line showing selection count.
  String summaryLine() {
    final count = selection.count;
    final total = items.length;
    if (count == 0) {
      return '${theme.dim}(none selected)${theme.reset}';
    }
    return '${theme.accent}$count${theme.reset}/${theme.dim}$total${theme.reset} selected';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BUILDER PATTERN FOR ADVANCED CONFIGURATION
// ════════════════════════════════════════════════════════════════════════════

/// Builder for creating customized SelectableListPrompt instances.
///
/// Example:
/// ```dart
/// final selected = SelectableListPromptBuilder<String>()
///   .title('Select items')
///   .items(myItems)
///   .multiSelect(true)
///   .maxVisible(8)
///   .withSelectAll()
///   .build()
///   .run(...);
/// ```
class SelectableListPromptBuilder<T> {
  String _title = 'Select';
  List<T> _items = [];
  PromptTheme _theme = PromptTheme.dark;
  bool _multiSelect = false;
  int _maxVisible = 12;
  Set<int>? _initialSelection;
  int _reservedLines = 7;
  KeyBindings? _extraBindings;

  SelectableListPromptBuilder<T> title(String title) {
    _title = title;
    return this;
  }

  SelectableListPromptBuilder<T> items(List<T> items) {
    _items = items;
    return this;
  }

  SelectableListPromptBuilder<T> theme(PromptTheme theme) {
    _theme = theme;
    return this;
  }

  SelectableListPromptBuilder<T> multiSelect([bool value = true]) {
    _multiSelect = value;
    return this;
  }

  SelectableListPromptBuilder<T> maxVisible(int value) {
    _maxVisible = value;
    return this;
  }

  SelectableListPromptBuilder<T> initialSelection(Set<int> selection) {
    _initialSelection = selection;
    return this;
  }

  SelectableListPromptBuilder<T> reservedLines(int lines) {
    _reservedLines = lines;
    return this;
  }

  SelectableListPromptBuilder<T> extraBindings(KeyBindings bindings) {
    _extraBindings = bindings;
    return this;
  }

  /// Adds 'A' key binding for select all / clear all.
  SelectableListPromptBuilder<T> withSelectAll({
    String hintDescription = 'select all / clear',
  }) {
    final binding = KeyBindings.letter(
      char: 'A',
      onPress: () {
        // Will be connected during run()
      },
      hintDescription: hintDescription,
    );
    if (_extraBindings != null) {
      _extraBindings = _extraBindings! + binding;
    } else {
      _extraBindings = binding;
    }
    return this;
  }

  SelectableListPrompt<T> build() {
    return SelectableListPrompt<T>(
      title: _title,
      items: _items,
      theme: _theme,
      multiSelect: _multiSelect,
      maxVisible: _maxVisible,
      initialSelection: _initialSelection,
      reservedLines: _reservedLines,
    );
  }
}
