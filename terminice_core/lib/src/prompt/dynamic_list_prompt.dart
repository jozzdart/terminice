import 'package:terminice_core/terminice_core.dart';

/// DynamicListPrompt – composable system for lists with dynamic items.
///
/// Handles patterns where items change based on state:
/// - Tree navigation (expand/collapse)
/// - File system navigation
/// - Any hierarchical or mutable list
///
/// **Design principles:**
/// - Composition over inheritance
/// - Separation of concerns (item generation is separate from navigation)
/// - DRY: Centralizes the dynamic list pattern
///
/// **Usage:**
/// ```dart
/// final prompt = DynamicListPrompt<TreeEntry>(
///   title: 'Explorer',
///   buildItems: () => flattenTree(root, expandedNodes),
/// );
///
/// final result = prompt.run(
///   onAction: (item, action) {
///     if (action == ItemAction.expand) expandedNodes.add(item);
///     if (action == ItemAction.collapse) expandedNodes.remove(item);
///   },
/// );
/// ```
class DynamicListPrompt<T> {
  /// Title for the frame header.
  final String title;

  /// Theme for styling.
  final PromptTheme theme;

  /// Maximum visible items (viewport size).
  final int maxVisible;

  /// Whether to show a connector line after header.
  final bool showConnector;

  /// Hint style for key bindings display.
  final HintStyle hintStyle;

  // ──────────────────────────────────────────────────────────────────────────
  // INTERNAL STATE
  // ──────────────────────────────────────────────────────────────────────────

  late ListNavigator _nav;
  late KeyBindings _bindings;
  late List<T> _items;
  bool _cancelled = false;
  T? _result;

  DynamicListPrompt({
    required this.title,
    this.theme = PromptTheme.dark,
    this.maxVisible = 18,
    this.showConnector = true,
    this.hintStyle = HintStyle.grid,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ACCESSORS
  // ──────────────────────────────────────────────────────────────────────────

  /// Current navigation state.
  ListNavigator get nav => _nav;

  /// Current key bindings.
  KeyBindings get bindings => _bindings;

  /// Current items.
  List<T> get items => _items;

  /// Whether the prompt was cancelled.
  bool get wasCancelled => _cancelled;

  /// The result item (if confirmed).
  T? get result => _result;

  // ──────────────────────────────────────────────────────────────────────────
  // RUN
  // ──────────────────────────────────────────────────────────────────────────

  /// Runs the dynamic list prompt.
  ///
  /// [buildItems] - Function that returns current list of items.
  ///   Called on every action to rebuild the list.
  /// [onPrimary] - Called when Enter/Right is pressed on an item.
  ///   Return [DynamicAction] to control behavior.
  /// [onSecondary] - Called when Left is pressed on an item.
  ///   Return [DynamicAction] to control behavior.
  /// [onToggle] - Called when Space is pressed on an item.
  ///   Return [DynamicAction] to control behavior.
  /// [renderItem] - Custom item renderer.
  /// [beforeItems] - Content to render before the list.
  /// [extraBindings] - Additional key bindings.
  /// [customBindings] - Completely replace default bindings.
  ///
  /// Returns selected item on confirm, null on cancel.
  T? run({
    required List<T> Function() buildItems,
    DynamicAction Function(T item, int index)? onPrimary,
    DynamicAction Function(T item, int index)? onSecondary,
    DynamicAction Function(T item, int index)? onToggle,
    required void Function(
      FrameContext ctx,
      T item,
      int absoluteIndex,
      bool isFocused,
    ) renderItem,
    void Function(FrameContext ctx)? beforeItems,
    KeyBindings? extraBindings,
    KeyBindings? customBindings,
  }) {
    _initState(buildItems);

    void rebuild() {
      _items = buildItems();
      _nav.itemCount = _items.length;
    }

    DynamicAction handleAction(DynamicAction Function(T, int)? handler) {
      if (handler == null || _items.isEmpty) return DynamicAction.none;
      final item = _items[_nav.selectedIndex];
      return handler(item, _nav.selectedIndex);
    }

    // Create bindings
    if (customBindings != null) {
      _bindings = customBindings;
    } else {
      _bindings = KeyBindings.verticalNavigation(
            onUp: () => _nav.moveUp(),
            onDown: () => _nav.moveDown(),
          ) +
          KeyBindings([
            // Primary action (Enter/Right)
            KeyBinding.multi(
              {KeyEventType.enter, KeyEventType.arrowRight},
              (event) {
                final action = handleAction(onPrimary);
                switch (action) {
                  case DynamicAction.confirm:
                    if (_items.isNotEmpty) {
                      _result = _items[_nav.selectedIndex];
                    }
                    return KeyActionResult.confirmed;
                  case DynamicAction.rebuild:
                    rebuild();
                    return KeyActionResult.handled;
                  case DynamicAction.rebuildAndReset:
                    rebuild();
                    _nav.reset();
                    return KeyActionResult.handled;
                  case DynamicAction.cancel:
                    _cancelled = true;
                    return KeyActionResult.cancelled;
                  case DynamicAction.none:
                    return KeyActionResult.handled;
                }
              },
              hintLabel: '→/Enter',
              hintDescription: 'select/enter',
            ),
            // Secondary action (Left)
            KeyBinding.single(
              KeyEventType.arrowLeft,
              (event) {
                final action = handleAction(onSecondary);
                switch (action) {
                  case DynamicAction.confirm:
                    if (_items.isNotEmpty) {
                      _result = _items[_nav.selectedIndex];
                    }
                    return KeyActionResult.confirmed;
                  case DynamicAction.rebuild:
                    rebuild();
                    return KeyActionResult.handled;
                  case DynamicAction.rebuildAndReset:
                    rebuild();
                    _nav.reset();
                    return KeyActionResult.handled;
                  case DynamicAction.cancel:
                    _cancelled = true;
                    return KeyActionResult.cancelled;
                  case DynamicAction.none:
                    return KeyActionResult.handled;
                }
              },
              hintLabel: '←',
              hintDescription: 'back/collapse',
            ),
            // Toggle action (Space)
            if (onToggle != null)
              KeyBinding.single(
                KeyEventType.space,
                (event) {
                  final action = handleAction(onToggle);
                  switch (action) {
                    case DynamicAction.confirm:
                      if (_items.isNotEmpty) {
                        _result = _items[_nav.selectedIndex];
                      }
                      return KeyActionResult.confirmed;
                    case DynamicAction.rebuild:
                      rebuild();
                      return KeyActionResult.handled;
                    case DynamicAction.rebuildAndReset:
                      rebuild();
                      _nav.reset();
                      return KeyActionResult.handled;
                    case DynamicAction.cancel:
                      _cancelled = true;
                      return KeyActionResult.cancelled;
                    case DynamicAction.none:
                      return KeyActionResult.handled;
                  }
                },
                hintLabel: 'Space',
                hintDescription: 'toggle',
              ),
          ]) +
          KeyBindings.cancel(onCancel: () => _cancelled = true);
    }

    if (extraBindings != null) {
      _bindings = _bindings + extraBindings;
    }

    final frame = FrameView(
      title: title,
      theme: theme,
      bindings: _bindings,
      showConnector: showConnector,
      hintStyle: hintStyle,
    );

    void render(RenderOutput out) {
      // Rebuild items on each render to catch state changes
      rebuild();

      frame.render(out, (ctx) {
        // Before items hook
        beforeItems?.call(ctx);

        // Visible window
        final window = _nav.visibleWindow(_items);

        ctx.listWindow(
          window,
          selectedIndex: _nav.selectedIndex,
          renderItem: (T item, int index, bool isFocused) {
            renderItem(ctx, item, index, isFocused);
          },
        );

        if (_items.isEmpty) {
          ctx.emptyMessage('empty');
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(
      render: render,
      bindings: _bindings,
    );

    return _cancelled ? null : _result;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ──────────────────────────────────────────────────────────────────────────

  void _initState(List<T> Function() buildItems) {
    _cancelled = false;
    _result = null;
    _items = buildItems();

    _nav = ListNavigator(
      itemCount: _items.length,
      maxVisible: maxVisible,
    );
  }
}

/// Actions that can be returned from dynamic list handlers.
enum DynamicAction {
  /// Do nothing special.
  none,

  /// Rebuild the item list (e.g., after expand/collapse).
  rebuild,

  /// Rebuild the item list and reset navigation to first item.
  rebuildAndReset,

  /// Confirm and exit with the current item.
  confirm,

  /// Cancel and exit.
  cancel,
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER MIXINS FOR COMMON PATTERNS
// ════════════════════════════════════════════════════════════════════════════

/// Helper for tree-like hierarchical navigation.
mixin TreeNavigationHelper<T> {
  /// Builds visible entries from a tree structure.
  ///
  /// [roots] - Root nodes of the tree.
  /// [isExpanded] - Check if a node is expanded.
  /// [getChildren] - Get children of a node.
  /// [createEntry] - Create a visible entry from node + metadata.
  List<E> buildTreeEntries<E>({
    required List<T> roots,
    required bool Function(T node) isExpanded,
    required List<T> Function(T node) getChildren,
    required E Function(
            T node, int depth, bool isLast, List<bool> ancestorLines)
        createEntry,
  }) {
    final result = <E>[];

    void traverse(T node, int depth, bool isLast, List<bool> ancestorLines) {
      result.add(createEntry(node, depth, isLast, ancestorLines));

      if (isExpanded(node)) {
        final children = getChildren(node);
        for (var i = 0; i < children.length; i++) {
          final child = children[i];
          final childIsLast = i == children.length - 1;
          traverse(
            child,
            depth + 1,
            childIsLast,
            [...ancestorLines, !isLast],
          );
        }
      }
    }

    for (var i = 0; i < roots.length; i++) {
      traverse(roots[i], 0, i == roots.length - 1, const []);
    }

    return result;
  }
}

/// Helper for path-like navigation.
mixin PathNavigationHelper {
  /// Navigates to parent directory.
  String parentPath(String path) {
    final parts = path.split('/');
    if (parts.length <= 1) return path;
    return parts.sublist(0, parts.length - 1).join('/');
  }

  /// Gets basename from path.
  String basename(String path) {
    final parts = path.split('/');
    return parts.isEmpty ? path : parts.last;
  }
}
