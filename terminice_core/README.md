# terminice_core

`terminice_core` provides the low-level primitives that power the Terminice design system. The navigation utilities live in `lib/src/navigation` and are intended to be consumed directly by downstream packages via the public exports in `terminice_core.dart`.

## Navigation toolkit

### FocusNavigator

- Single-column focus state with optional per-item validation
- Wrapping navigation (`moveUp`, `moveDown`, `moveBy`) and helpers like `focusFirstError`
- Ideal for forms, multi-step wizards, command palettes, and any view where every item is already on screen

```dart
final focus = FocusNavigator(itemCount: fields.length);
focus.moveBy(1);
focus.setError(2, 'Required');
if (focus.hasAnyError) focus.focusFirstError();
```

### ListNavigator

- Handles selection + scroll math for vertical lists
- Keeps the focused row visible by adjusting an internal scroll offset
- Exposes both a lightweight `[start, end)` viewport and a materialized window of items for rendering

```dart
final nav = ListNavigator(itemCount: items.length, maxVisible: 8);
nav.moveDown();
final window = nav.visibleWindow(items);
for (final (idx, item) in window.items.indexed) {
  final absoluteIndex = window.start + idx;
  final isSelected = nav.isSelected(absoluteIndex);
  // render row
}
```

### GridNavigator

- 2D navigation for matrices of cards / tiles with predictable wrapping in every direction
- Factory constructors for fixed, responsive, or balanced column counts
- Ships a `rowsOf` helper and `GridLayout` descriptor for ergonomic rendering

```dart
final grid = GridNavigator.responsive(
  itemCount: items.length,
  cellWidth: 20,
  availableWidth: terminalWidth,
);
grid.moveRight();
grid.moveDown();
```

### SelectionController

- Abstracts single- versus multi-select behaviour while remaining index based
- Includes power-user helpers (`selectAll`, `toggleAll`, `invert`) and safe result extraction APIs
- Composes cleanly with every navigator by sharing the focused index

```dart
final sel = SelectionController.multi();
sel.toggle(nav.selectedIndex);
sel.selectAll(items.length);
final selectedItems = sel.getSelectedMany(items);
```

## Recommended pairing

- Use `SelectionController` when you need to differentiate focus versus user selection
- Bind keyboard events with `KeyBindings` and delegate movement to the navigators
- Keep your rendering code dumb: take `viewport`, `visibleWindow`, or `rowsOf` data and simply paint what is described

For more examples, browse the inline dartdoc inside each navigation file—everything is documented with production-ready snippets that render cleanly on pub.dev.
