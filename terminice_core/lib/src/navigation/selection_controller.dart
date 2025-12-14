/// Manages selection state for list and grid based views.
///
/// ## Why it exists
/// UI code often mixes navigation (which item is focused) with selection (which
/// items are "picked"). [SelectionController] separates these responsibilities so
/// list, grid, or focus navigators can stay dumb and reusable.
///
/// ## Features
/// - Single- or multi-select modes via the same API
/// - Toggle/select/deselect helpers that keep code expressive
/// - `selectAll`, `toggleAll`, and `invert` for power-user shortcuts
/// - Safe result extraction helpers that gracefully fallback to the focused row
/// - Can be copied/cloned, making it easy to snapshot state
///
/// ## Single-select usage
/// ```dart
/// final nav = ListNavigator(itemCount: items.length, maxVisible: 10);
/// final sel = SelectionController.single();
///
/// sel.toggle(nav.selectedIndex); // replaces the single selection
/// final selectedItem = sel.getSelected(
///   items,
///   fallbackIndex: nav.selectedIndex,
/// );
/// ```
///
/// ## Multi-select usage
/// ```dart
/// final nav = GridNavigator(itemCount: items.length, columns: 4);
/// final sel = SelectionController.multi();
///
/// sel.toggle(nav.focusedIndex); // add/remove the focused tile
/// sel.selectAll(items.length);  // convenience for Cmd+A style shortcuts
/// final picked = sel.getSelectedMany(items);
/// ```
///
/// ## Key binding integration
/// ```dart
/// KeyBindings.toggle(
///   onToggle: () => sel.toggle(nav.selectedIndex),
///   onSelectAll: () => sel.selectAll(items.length),
/// );
/// ```
class SelectionController {
  /// Whether this controller allows multiple selections.
  final bool multiSelect;

  /// The set of selected indices.
  final Set<int> _selected;

  /// Creates a selection controller.
  ///
  /// [multiSelect] determines if multiple items can be selected.
  /// [initialSelection] pre-selects the given indices.
  SelectionController({
    this.multiSelect = false,
    Set<int>? initialSelection,
  }) : _selected = {...?initialSelection};

  /// Creates a single-selection controller.
  factory SelectionController.single({int? initialIndex}) {
    return SelectionController(
      multiSelect: false,
      initialSelection: initialIndex != null ? {initialIndex} : null,
    );
  }

  /// Creates a multi-selection controller.
  factory SelectionController.multi({Set<int>? initialSelection}) {
    return SelectionController(
      multiSelect: true,
      initialSelection: initialSelection,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STATE QUERIES
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns an unmodifiable view of selected indices.
  Set<int> get selectedIndices => Set.unmodifiable(_selected);

  /// Number of selected items.
  int get count => _selected.length;

  /// Whether no items are selected.
  bool get isEmpty => _selected.isEmpty;

  /// Whether at least one item is selected.
  bool get isNotEmpty => _selected.isNotEmpty;

  /// Checks if an index is selected.
  bool isSelected(int index) => _selected.contains(index);

  /// The single selected index (for single-select mode).
  ///
  /// Returns null if nothing is selected.
  int? get selectedIndex => _selected.isEmpty ? null : _selected.first;

  // ──────────────────────────────────────────────────────────────────────────
  // SELECTION OPERATIONS
  // ──────────────────────────────────────────────────────────────────────────

  /// Toggles selection of an index.
  ///
  /// In single-select mode, this replaces the current selection.
  /// In multi-select mode, this adds or removes the index.
  void toggle(int index) {
    if (multiSelect) {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    } else {
      // Single select: replace selection
      _selected.clear();
      _selected.add(index);
    }
  }

  /// Selects an index (adds to selection in multi-select, replaces in single).
  void select(int index) {
    if (multiSelect) {
      _selected.add(index);
    } else {
      _selected.clear();
      _selected.add(index);
    }
  }

  /// Deselects an index.
  void deselect(int index) {
    _selected.remove(index);
  }

  /// Clears all selections.
  void clear() {
    _selected.clear();
  }

  /// Selects all indices from 0 to [count]-1.
  ///
  /// Only works in multi-select mode. In single-select mode, this is a no-op.
  void selectAll(int count) {
    if (!multiSelect) return;
    _selected.clear();
    for (var i = 0; i < count; i++) {
      _selected.add(i);
    }
  }

  /// Selects all if any are unselected, otherwise clears all.
  ///
  /// Only works in multi-select mode.
  void toggleAll(int count) {
    if (!multiSelect) return;
    if (_selected.length == count) {
      clear();
    } else {
      selectAll(count);
    }
  }

  /// Inverts the selection (selects unselected, deselects selected).
  ///
  /// Only works in multi-select mode.
  void invert(int count) {
    if (!multiSelect) return;
    final newSelection = <int>{};
    for (var i = 0; i < count; i++) {
      if (!_selected.contains(i)) {
        newSelection.add(i);
      }
    }
    _selected
      ..clear()
      ..addAll(newSelection);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // RESULT EXTRACTION
  // ──────────────────────────────────────────────────────────────────────────

  /// Gets the selected items from a list.
  ///
  /// Returns items at selected indices, sorted by index.
  /// If nothing is selected and [fallbackIndex] is provided,
  /// returns a list with just that item.
  List<T> getSelectedMany<T>(List<T> items, {int? fallbackIndex}) {
    if (_selected.isEmpty) {
      if (fallbackIndex != null &&
          fallbackIndex >= 0 &&
          fallbackIndex < items.length) {
        return [items[fallbackIndex]];
      }
      return [];
    }

    final indices = _selected.toList()..sort();
    return indices
        .where((i) => i >= 0 && i < items.length)
        .map((i) => items[i])
        .toList();
  }

  /// Gets the single selected item from a list.
  ///
  /// For single-select mode. Returns null if nothing is selected
  /// and no fallback is provided.
  T? getSelected<T>(List<T> items, {int? fallbackIndex}) {
    final index = selectedIndex;
    if (index != null && index >= 0 && index < items.length) {
      return items[index];
    }
    if (fallbackIndex != null &&
        fallbackIndex >= 0 &&
        fallbackIndex < items.length) {
      return items[fallbackIndex];
    }
    return null;
  }

  /// Gets the selected indices as a sorted list.
  ///
  /// If nothing is selected and [fallbackIndex] is provided,
  /// returns a list with just that index.
  List<int> getSelectedIndices({int? fallbackIndex}) {
    if (_selected.isEmpty) {
      if (fallbackIndex != null) {
        return [fallbackIndex];
      }
      return [];
    }
    return _selected.toList()..sort();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UTILITY
  // ──────────────────────────────────────────────────────────────────────────

  /// Constrains selection to valid indices for the given item count.
  ///
  /// Removes any indices that are >= [itemCount].
  /// Call this when the underlying list changes size.
  void constrainTo(int itemCount) {
    _selected.removeWhere((i) => i >= itemCount);
  }

  /// Returns a summary string for display.
  ///
  /// Example: "3/10 selected" or "none selected"
  String summary(int totalCount) {
    if (_selected.isEmpty) return 'none selected';
    return '${_selected.length}/$totalCount selected';
  }

  /// Creates a copy of this controller.
  SelectionController copy() {
    return SelectionController(
      multiSelect: multiSelect,
      initialSelection: Set.from(_selected),
    );
  }

  @override
  String toString() {
    return 'SelectionController(multiSelect: $multiSelect, selected: $_selected)';
  }
}

/// Extension to integrate SelectionController with ListNavigator.
///
/// Provides convenient methods that combine navigation and selection.
extension SelectionControllerExt on SelectionController {
  /// Toggles the currently focused item.
  ///
  /// Usage:
  /// ```dart
  /// sel.toggleFocused(nav.selectedIndex);
  /// ```
  void toggleFocused(int focusedIndex) => toggle(focusedIndex);

  /// Checks if the focused item is selected.
  bool isFocusedSelected(int focusedIndex) => isSelected(focusedIndex);
}
