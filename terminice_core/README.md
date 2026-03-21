# terminice_core

**The low-level foundation for building beautiful terminal interfaces in Dart.**

> **Note:** If you just want to ask for user input or display menus, you probably want the main [**`terminice`** package on pub.dev](https://pub.dev/packages/terminice). Check out the [main `terminice` README](https://pub.dev/packages/terminice) for a complete catalogue of ready-to-use components.

`terminice_core` provides the essential primitives, state management, and rendering utilities that power the main `terminice` package. While `terminice` offers high-level, ready-to-use components, `terminice_core` is designed for developers who need full control to build custom prompts, complex CLI layouts, or entirely new terminal UI frameworks.

#### Table of Contents

- [Overview](#overview)
- [IO](#io)
- [Navigation](#navigation)
- [Rendering](#rendering)
- [Prompt](#prompt)
- [Testing](#testing)

## Overview

The `terminice_core` package acts as the engine room for terminal user interfaces. Rather than providing rigid, pre-built components, it offers a set of composable modules that handle the complex, low-level mechanics of terminal interaction. When these modules are combined, they form a robust pipeline for building interactive CLI tools.

In the broader ecosystem, the main `terminice` package relies entirely on these core modules to construct its ready-to-use components (like date pickers, color selectors, and complex forms). By understanding how these layers interact, you can leverage them to build custom components or contribute to the `terminice` ecosystem.

Here is how the macro architecture comes together:

### 1. IO (Input/Output)

The **IO** module is the foundational layer that communicates directly with the operating system's terminal. It handles enabling raw mode, reading raw byte streams from standard input, and parsing complex ANSI escape sequences into structured key events.

**Role in the ecosystem:** It shields the rest of the application from platform-specific terminal quirks and provides a clean stream of user intents.

```dart
final terminal = Terminal();
terminal.enableRawMode();
final keyEvent = terminal.readKey(); // e.g., Key.up, Key.enter
```

### 2. Navigation

Once input is captured, the **Navigation** module interprets those key events to manage state. It provides mathematical models for lists, grids, and focus areas, handling edge cases like scrolling viewports, wrapping cursors, and two-dimensional matrix bounds.

**Role in the ecosystem:** It maintains the "where am I?" state strictly as data, completely decoupled from how the UI looks.

```dart
final navigator = ListNavigator(itemCount: 10, maxVisible: 5);
if (keyEvent == Key.down) navigator.moveDown();
final window = navigator.visibleWindow(); // Calculates what should be on screen
```

### 3. Rendering

With the state updated, the **Rendering** module takes over to paint the UI. It provides a highly optimized frame buffer, layout primitives, and theming utilities. It ensures that only the necessary parts of the terminal are redrawn, preventing flickering and maintaining high performance.

**Role in the ecosystem:** It translates abstract state (like a selected index or a scroll offset) into colored, formatted text on the screen.

```dart
final frame = FrameView();
frame.writeLine('Select an option:', theme.primaryColor);
frame.render(); // Flushes the buffer to the terminal
```

### 4. Prompt

The **Prompt** module is the orchestrator that ties IO, Navigation, and Rendering together. It provides the scaffolding for interactive sessions, managing the event loop, handling cancellation, and returning the final structured result to the caller.

**Role in the ecosystem:** It acts as the controller, managing the lifecycle of a single interactive component from start to finish.

```dart
final result = await SimplePrompt<String>(
  title: 'Enter your name',
  render: (ctx, state) => ctx.writeInput(state.value),
).run();
```

### How it powers `terminice`

When you use a high-level component from the main `terminice` package—such as a `DatePicker`—it is secretly orchestrating these core modules. The `DatePicker` uses the **IO** module to listen for arrow keys, feeds those keys into a **Navigation** grid to move between days, uses the **Rendering** module to draw the calendar layout with the correct theme, and wraps it all in a **Prompt** to return a `DateTime` object back to your application.

---

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

## Prompt toolkit

The prompt module composes navigation, selection, rendering, and input helpers into production-ready interactions. Every prompt ships extensive dartdoc so the snippets below render well on pub.dev.

### SimplePrompt

- Boilerplate killer for "one value in, one value out" prompts
- Automatically tracks cancellation and merges `PromptRunner`, `FrameView`, and key bindings

```dart
final confirm = SimplePrompt<bool>(
  title: 'Confirm deploy?',
  initialValue: false,
  buildBindings: (state) => KeyBindings.togglePrompt(
    onToggle: () => state.value = !state.value,
    onCancel: state.cancel,
  ),
  render: (ctx, state) => ctx.checkboxLine(
    label: 'Deploy to production',
    checked: state.value,
  ),
).run();
```

### SelectableListPrompt

- Builds on `ListNavigator` + `SelectionController` for scrollable lists
- Opt into single- or multi-select flows with the same API surface

```dart
final lang = SelectableListPrompt<String>(
  title: 'Language',
  items: ['Dart', 'Go', 'Rust', 'Zig'],
).run(
  renderItem: (ctx, item, index, focused, selected) {
    ctx.checkboxItem(
      item,
      highlighted: focused,
      checked: selected,
    );
  },
);
```

### SearchableListPrompt

- Layers a `TextInputBuffer` on top of the list prompt for live filtering
- Toggle search with `/` or keep it always-on for command palette flows

```dart
final matches = SearchableListPrompt<String>(
  title: 'Find files',
  items: files,
  multiSelect: true,
).run(
  filter: (file, query) => file.contains(query),
  itemLabel: (file) => file,
);
```

### RankedListPrompt

- Adds fuzzy/substring ranking plus highlight spans for the active query
- Perfect for command palettes where relevance matters more than order

```dart
final command = RankedListPrompt<Command>(
  title: 'Command Palette',
  items: commands,
).run(
  rankItem: (cmd, query, useFuzzy) => useFuzzy
      ? cmd.fuzzyRank(query)
      : cmd.substringRank(query),
  itemLabel: (cmd) => cmd.title,
);
```

### DynamicListPrompt

- Rebuilds its backing data on every tick so tree/file explorers stay fresh
- Return `DynamicAction.rebuild()` or `rebuildAndReset()` from callbacks to mutate the list safely

```dart
final tree = DynamicListPrompt<FileEntry>(
  title: 'Files',
);

tree.run(
  buildItems: () => flattenTree(root, expanded),
  onPrimary: (entry, _) {
    if (entry.isDir) {
      expanded.add(entry.path);
      return DynamicAction.rebuild();
    }
    openFile(entry.path);
    return DynamicAction.confirm;
  },
  renderItem: (ctx, entry, _, focused) =>
      ctx.treeItem(entry.label, entry.depth, focused: focused),
);
```

### SelectableGridPrompt

- Backed by `GridNavigator` for deterministic two-dimensional movement
- Responsive factory computes column counts based on terminal width

```dart
final colors = SelectableGridPrompt.responsive<String>(
  title: 'Pick colors',
  items: swatches,
  cellWidth: 16,
  multiSelect: true,
).run(
  renderCell: (ctx, color, index, focused, selected, cellWidth) {
    ctx.colorSwatch(color, focused: focused, selected: selected);
  },
);
```

### ValuePrompt + DiscreteValuePrompt

- Cover sliders, numeric ranges, and star ratings without rebuilding input plumbing
- Merge with `KeyBindings.numbers()` or standard horizontal navigation

```dart
final volume = ValuePrompt(
  title: 'Volume',
  min: 0,
  max: 100,
  initial: 50,
).run(
  render: (ctx, value, ratio) {
    ctx.sliderBar(ratio);
    ctx.labeledAccent('Volume', '${value.toStringAsFixed(0)}%');
  },
);
```

Need something more bespoke? Compose the underlying parts yourself—everything exported from `terminice_core.dart` remains available for custom prompt architectures.
