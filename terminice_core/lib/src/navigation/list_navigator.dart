import 'dart:math';

/// Manages list navigation state (selection + viewport scrolling) for terminal
/// and TUI experiences.
///
/// ## What problems it solves
/// - Tracks the selected index independently of rendering code
/// - Keeps a scroll offset so the selection always stays visible
/// - Provides helper views ([ListViewport], [ListWindow]) for cheap rendering
/// - Wraps around at the boundaries so keyboard navigation "just works"
///
/// ## Usage
/// ```dart
/// final nav = ListNavigator(itemCount: items.length, maxVisible: 10);
///
/// nav.moveBy(-1);  // up
/// nav.moveBy(1);   // down
/// nav.jumpTo(5);   // absolute jump
///
/// final visible = nav.visibleWindow(items);
/// for (final (offset, item) in visible.items.indexed) {
///   final absoluteIndex = visible.start + offset;
///   final isFocused = nav.isSelected(absoluteIndex);
///   // render row
/// }
/// ```
///
/// ## Power tips
/// - Pair with [SelectionController] to support multi-select lists
/// - Feed `maxVisible` with your terminal height to keep scroll math accurate
/// - Use [ListNavigator.viewport] when you want to keep the original `items`
///   list intact and only need index ranges for rendering
///
/// These docs surface every public API so downstream consumers on pub.dev can
/// copy/paste examples without reading the source.
class ListNavigator {
  /// Total number of items in the list.
  int _itemCount;

  /// Maximum number of items visible at once (viewport size).
  int _maxVisible;

  /// Current selected/focused index.
  int _selectedIndex;

  /// Current scroll offset (first visible item index).
  int _scrollOffset;

  /// Creates a new list navigation state.
  ///
  /// [itemCount] is the total number of items in the list.
  /// [maxVisible] is the viewport size (how many items can be shown at once).
  /// [initialIndex] is the starting selection (defaults to 0).
  ListNavigator({
    required int itemCount,
    required int maxVisible,
    int initialIndex = 0,
  })  : _itemCount = max(0, itemCount),
        _maxVisible = max(1, maxVisible),
        _selectedIndex = 0,
        _scrollOffset = 0 {
    // Clamp initial index to valid range
    _selectedIndex = itemCount > 0 ? initialIndex.clamp(0, itemCount - 1) : 0;
    _adjustScroll();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GETTERS & SETTERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Current selected index.
  int get selectedIndex => _selectedIndex;

  /// Current scroll offset (first visible item index).
  int get scrollOffset => _scrollOffset;

  /// Total number of items.
  int get itemCount => _itemCount;

  /// Maximum visible items (viewport size).
  int get maxVisible => _maxVisible;

  /// Updates the maximum visible items (e.g., when terminal resizes).
  set maxVisible(int value) {
    _maxVisible = max(1, value);
    _adjustScroll();
  }

  /// Updates the total item count (e.g., when filtering changes the list).
  ///
  /// Automatically clamps selection to valid range and adjusts scroll.
  set itemCount(int value) {
    _itemCount = max(0, value);
    if (_itemCount == 0) {
      _selectedIndex = 0;
      _scrollOffset = 0;
    } else {
      _selectedIndex = _selectedIndex.clamp(0, _itemCount - 1);
      _adjustScroll();
    }
  }

  /// Whether there are items above the current viewport.
  bool get hasOverflowAbove => _scrollOffset > 0;

  /// Whether there are items below the current viewport.
  bool get hasOverflowBelow =>
      _itemCount > 0 && (_scrollOffset + _maxVisible) < _itemCount;

  /// Whether the list is empty.
  bool get isEmpty => _itemCount == 0;

  /// Whether the list is not empty.
  bool get isNotEmpty => _itemCount > 0;

  // ──────────────────────────────────────────────────────────────────────────
  // NAVIGATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Moves selection by [delta] positions with wrapping.
  ///
  /// Positive delta moves down, negative moves up.
  /// Wraps around at list boundaries.
  void moveBy(int delta) {
    if (_itemCount == 0) return;
    _selectedIndex = (_selectedIndex + delta + _itemCount) % _itemCount;
    _adjustScroll();
  }

  /// Moves selection up by one (with wrapping).
  void moveUp() => moveBy(-1);

  /// Moves selection down by one (with wrapping).
  void moveDown() => moveBy(1);

  /// Jumps to a specific index (clamped to valid range).
  void jumpTo(int index) {
    if (_itemCount == 0) return;
    _selectedIndex = index.clamp(0, _itemCount - 1);
    _adjustScroll();
  }

  /// Jumps to the first item.
  void jumpToFirst() => jumpTo(0);

  /// Jumps to the last item.
  void jumpToLast() => jumpTo(_itemCount - 1);

  /// Moves viewport up by one page.
  void pageUp() => moveBy(-_maxVisible);

  /// Moves viewport down by one page.
  void pageDown() => moveBy(_maxVisible);

  /// Resets navigation to initial state (first item, no scroll).
  void reset({int initialIndex = 0}) {
    if (_itemCount == 0) {
      _selectedIndex = 0;
      _scrollOffset = 0;
    } else {
      _selectedIndex = initialIndex.clamp(0, _itemCount - 1);
      _scrollOffset = 0;
      _adjustScroll();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // VIEWPORT
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns viewport information for rendering.
  ///
  /// Use this to render only the visible portion of a list:
  /// ```dart
  /// final vp = nav.viewport;
  /// for (var i = vp.start; i < vp.end; i++) {
  ///   final isSelected = i == nav.selectedIndex;
  ///   // render items[i]
  /// }
  /// ```
  ListViewport get viewport {
    final start = _scrollOffset;
    final end = min(_scrollOffset + _maxVisible, _itemCount);
    return ListViewport(
      start: start,
      end: end,
      hasOverflowAbove: hasOverflowAbove,
      hasOverflowBelow: hasOverflowBelow,
    );
  }

  /// Returns a window of items from the given list based on current viewport.
  ///
  /// This is a convenience method that slices the list for you:
  /// ```dart
  /// final window = nav.visibleWindow(items);
  /// for (final (index, item) in window.items.indexed) {
  ///   final absoluteIndex = window.start + index;
  ///   final isSelected = absoluteIndex == nav.selectedIndex;
  ///   // render item
  /// }
  /// ```
  ListWindow<T> visibleWindow<T>(List<T> items) {
    if (items.isEmpty) {
      return ListWindow<T>(
        items: const [],
        start: 0,
        end: 0,
        hasOverflowAbove: false,
        hasOverflowBelow: false,
      );
    }

    final start = _scrollOffset.clamp(0, items.length);
    final end = min(_scrollOffset + _maxVisible, items.length);

    return ListWindow<T>(
      items: items.sublist(start, end),
      start: start,
      end: end,
      hasOverflowAbove: start > 0,
      hasOverflowBelow: end < items.length,
    );
  }

  /// Checks if the given absolute index is currently selected.
  bool isSelected(int absoluteIndex) => absoluteIndex == _selectedIndex;

  // ──────────────────────────────────────────────────────────────────────────
  // INTERNAL
  // ──────────────────────────────────────────────────────────────────────────

  /// Adjusts scroll offset to keep selection visible.
  void _adjustScroll() {
    if (_itemCount == 0) {
      _scrollOffset = 0;
      return;
    }

    // If selection is above viewport, scroll up
    if (_selectedIndex < _scrollOffset) {
      _scrollOffset = _selectedIndex;
    }
    // If selection is below viewport, scroll down
    else if (_selectedIndex >= _scrollOffset + _maxVisible) {
      _scrollOffset = _selectedIndex - _maxVisible + 1;
    }

    // Clamp scroll to valid range
    _scrollOffset = _scrollOffset.clamp(0, max(0, _itemCount - _maxVisible));
  }
}

/// Viewport information for list rendering.
///
/// Contains the range of visible items and overflow indicators.
class ListViewport {
  /// Index of the first visible item.
  final int start;

  /// Index after the last visible item (exclusive).
  final int end;

  /// Whether there are hidden items above the viewport.
  final bool hasOverflowAbove;

  /// Whether there are hidden items below the viewport.
  final bool hasOverflowBelow;

  const ListViewport({
    required this.start,
    required this.end,
    required this.hasOverflowAbove,
    required this.hasOverflowBelow,
  });

  /// Number of items in the viewport.
  int get length => end - start;

  /// Whether the viewport is empty.
  bool get isEmpty => length == 0;
}

/// A window of visible items from a list.
///
/// Contains the actual items plus metadata for rendering.
class ListWindow<T> {
  /// The visible items (sublist of the original list).
  final List<T> items;

  /// Index of the first visible item in the original list.
  final int start;

  /// Index after the last visible item (exclusive) in the original list.
  final int end;

  /// Whether there are hidden items above the viewport.
  final bool hasOverflowAbove;

  /// Whether there are hidden items below the viewport.
  final bool hasOverflowBelow;

  const ListWindow({
    required this.items,
    required this.start,
    required this.end,
    required this.hasOverflowAbove,
    required this.hasOverflowBelow,
  });

  /// Number of items in the window.
  int get length => items.length;

  /// Whether the window is empty.
  bool get isEmpty => items.isEmpty;

  /// Whether the window is not empty.
  bool get isNotEmpty => items.isNotEmpty;
}
