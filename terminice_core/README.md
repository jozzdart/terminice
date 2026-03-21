# terminice_core

**The low-level foundation for building beautiful terminal interfaces in Dart.**

> **Note:** If you just want to ask for user input or display menus, you probably want the main [**`terminice`** package on pub.dev](https://pub.dev/packages/terminice). Check out the [main `terminice` README](https://pub.dev/packages/terminice) for a complete catalogue of ready-to-use components.

`terminice_core` provides the essential primitives, state management, and rendering utilities that power the main `terminice` package. It builds heavily upon its sibling package, [**`termistyle`**](https://pub.dev/packages/termistyle) (also created by the `terminice` team), for its robust ANSI styling, color manipulation, and text formatting. While `terminice` offers high-level, ready-to-use components, `terminice_core` is designed for developers who need full control to build custom prompts, complex CLI layouts, or entirely new terminal UI frameworks.

#### Table of Contents

- [Overview](#overview)
- [Termistyle Integration](#termistyle-integration)
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

When you use a high-level component from the main `terminice` package—such as a `DatePicker`—it is secretly orchestrating these core modules. The `DatePicker` uses the **IO** module to listen for arrow keys, feeds those keys into a **Navigation** grid to move between days, uses the **Rendering** module (powered by the sibling `termistyle` package) to draw the calendar layout with the correct theme, and wraps it all in a **Prompt** to return a `DateTime` object back to your application.

---

## `termistyle` Integration

`terminice_core` does not reinvent the wheel when it comes to colors and text formatting. Instead, it delegates all ANSI styling, color manipulation, and text decoration to the [**`termistyle`**](https://pub.dev/packages/termistyle) package.

**`termistyle` is a sibling package created specifically by the `terminice` team to power this ecosystem.** While it was built to handle the complex styling needs of `terminice` and `terminice_core`, it is designed as a completely independent package. This means you can use `termistyle` to get rich terminal styling, gradients, and text formatting in _any_ Dart CLI application, even if you don't need the complex interactive prompts or rendering logic provided by `terminice_core`.

If you are building custom components with `terminice_core`, you will frequently interact with `termistyle` APIs. The `PromptTheme` class in `terminice_core` is essentially a structured configuration object that holds `termistyle` color functions and styles.

For a complete understanding of how to define colors, apply gradients, or use text styles (like bold, italic, or strikethrough) within your custom prompts, please refer to the [**`termistyle` README**](https://pub.dev/packages/termistyle).

---

## IO

The **IO** module provides the lowest-level interaction with the system's terminal. It abstracts away `dart:io` to allow for custom implementations (like testing mocks), manages terminal raw mode, parses complex ANSI escape sequences into structured key events, and provides utilities for cursor control and screen clearing. It is the foundation upon which all user input and screen manipulation is built.

### API Surface

- `Terminal`, `TerminalInput`, `TerminalOutput`
- `TerminalContext`
- `TerminalControl`, `TerminalModeState`
- `KeyEvent`, `KeyEventType`, `KeyEventReader`
- `KeyBindings`, `KeyBinding`, `KeyActionResult`

### Terminal Abstraction

The `Terminal` interface mirrors the relevant parts of `dart:io`'s `Stdin` and `Stdout`. By accessing the terminal through `TerminalContext.current` rather than directly using `dart:io`, the entire package becomes testable and environment-agnostic. You can inject a mock terminal to simulate user input during tests.

```dart
// Accessing terminal dimensions safely
final cols = TerminalContext.output.terminalColumns;
final rows = TerminalContext.output.terminalLines;

// Writing raw bytes
TerminalContext.output.write('\x1B[31mHello\x1B[0m');
```

### Terminal Control & Raw Mode

Interactive CLI applications require "raw mode" to read keystrokes immediately without waiting for the user to press Enter, and to prevent those keystrokes from echoing to the screen. `TerminalControl` handles entering raw mode and capturing the previous state so it can be safely restored. It also provides helpers for cursor visibility and screen clearing.

```dart
// Enter raw mode and save the previous state
final state = TerminalControl.enterRaw();

try {
  TerminalControl.hideCursor();
  TerminalControl.clearAndHome();
  // Run interactive prompt...
} finally {
  // Always restore the terminal to its original state
  TerminalControl.showCursor();
  state.restore();
}
```

### Key Events

Terminals send input as a stream of bytes. While normal characters are single bytes, special keys like arrows or `F1` are sent as multi-byte ANSI escape sequences (e.g., `ESC [ A` for up arrow). `KeyEventReader` synchronously reads from the terminal input, intercepts these sequences, and normalizes them into a simple, predictable `KeyEvent` object.

```dart
// Read a single normalized key event
final event = KeyEventReader.read();

if (event.type == KeyEventType.arrowUp) {
  // Handle up arrow
} else if (event.type == KeyEventType.char && event.char == 'y') {
  // Handle 'y' press
} else if (event.type == KeyEventType.ctrlC) {
  // Handle interrupt
}
```

### Key Bindings

`KeyBindings` acts as the bridge between raw `KeyEvent`s and your application's logic. It provides a composable, immutable collection of rules that map specific keys to actions (like moving a cursor or confirming a prompt). It also automatically generates hint labels (e.g., "↑/↓ navigate") for the UI.

```dart
// Compose standard bindings using the + operator
final bindings = KeyBindings.verticalNavigation(
  onUp: () => navigator.moveUp(),
  onDown: () => navigator.moveDown(),
) + KeyBindings.confirm(
  onConfirm: () => KeyActionResult.confirmed,
);

// Process an event through the bindings
final result = bindings.handle(event);
if (result == KeyActionResult.confirmed) {
  // Exit prompt
}
```

---

## Navigation

The **Navigation** module is responsible for managing the "where am I?" and "what is selected?" state of your terminal application. It intentionally decouples the mathematical logic of moving through items (like wrapping around edges, calculating scroll offsets, and bounding 2D matrices) from the actual rendering of those items. This allows you to build complex, interactive UI components that are robust and easy to test.

### API Surface

- `FocusNavigator`
- `ListNavigator`, `ListViewport`, `ListWindow`
- `GridNavigator`, `GridLayout`, `GridRow`
- `SelectionController`

### Focus Navigation

`FocusNavigator` is the simplest state machine, designed for views where every item is already visible on the screen—such as forms, multi-step wizards, or settings pages. It handles wrapping navigation and includes built-in helpers for tracking per-item validation errors.

```dart
final focus = FocusNavigator(itemCount: fields.length);

focus.moveDown(); // Moves to the next field
focus.setError(2, 'This field is required');

if (focus.hasAnyError) {
  focus.focusFirstError(); // Jumps focus to the invalid field
}
```

### List Navigation

When dealing with lists that are longer than the terminal height, `ListNavigator` handles both the selected index and the scroll offset. It ensures that the currently focused item always remains visible within the viewport, and provides convenient windowing methods so your rendering code only has to draw what is actually on screen.

```dart
final nav = ListNavigator(itemCount: 100, maxVisible: 10);

nav.moveDown(); // Moves selection, adjusting scroll if necessary

// Get only the items that should be rendered on screen right now
final window = nav.visibleWindow(items);
for (final (offset, item) in window.items.indexed) {
  final absoluteIndex = window.start + offset;
  final isFocused = nav.isSelected(absoluteIndex);
  // Render the visible row...
}
```

### Grid Navigation

For 2D layouts like card grids, color pickers, or calendars, `GridNavigator` handles movement across rows and columns. It supports predictable wrapping (e.g., moving right from the end of a row wraps to the start of the next row) and includes factory constructors to automatically calculate column counts based on terminal width.

```dart
// Automatically calculates columns based on terminal width
final grid = GridNavigator.responsive(
  itemCount: items.length,
  cellWidth: 15,
  availableWidth: TerminalContext.output.terminalColumns,
);

grid.moveRight(); // Moves right, wrapping to next row if needed
grid.moveDown();  // Moves down, maintaining column position
```

### Selection Management

UI code often mixes navigation (which item is focused) with selection (which items the user has actually "picked"). `SelectionController` separates this responsibility, providing a unified API for both single-select and multi-select flows. It pairs perfectly with any of the navigators.

```dart
final sel = SelectionController.multi();

// Toggle the currently focused item
sel.toggle(nav.selectedIndex);

// Power-user shortcuts
sel.selectAll(items.length);
sel.invert(items.length);

// Safely extract the final result
final pickedItems = sel.getSelectedMany(items);
```

---

## Rendering

The **Rendering** module provides the tools to paint your state onto the terminal screen. It focuses on high-performance drawing (minimizing terminal flicker) and provides a rich set of composable layout primitives. By using this module alongside our standalone `termistyle` package, you ensure that your custom components look and feel exactly like the built-in `terminice` components, respecting the user's chosen theme and border preferences.

### API Surface

- `FrameView`, `FrameContext`
- `LineBuilder`
- `PromptTheme`, `TerminalGlyphs`, `DisplayFeatures`
- `RenderOutput`

### Frame View

The `FrameView` is the primary layout container. It eliminates the boilerplate of drawing top/bottom borders, handling connector lines, and rendering keyboard hints at the bottom of the prompt. It provides a `FrameContext` to its builder, which gives you access to a rich set of methods for drawing styled lines (like lists, checkboxes, and progress bars) inside the frame.

```dart
final frame = FrameView(
  title: 'Select an option',
  theme: theme,
  bindings: bindings, // Automatically renders hints like "↑/↓ navigate"
);

frame.render(out, (ctx) {
  // Renders a line with the proper left border/gutter automatically
  ctx.gutterLine('Please choose carefully:');
  ctx.emptyLine();

  // Renders a list of items, handling the selection arrow automatically
  ctx.selectionList(
    items,
    selectedIndex: nav.selectedIndex,
  );
});
```

### Line Builder

While `FrameContext` provides high-level layout methods, `LineBuilder` is the lower-level utility that actually constructs the strings. It handles the exact ANSI escape codes for colors (via our `termistyle` package), inverse highlighting, and glyphs (like arrows, checkboxes, and borders). It is deeply aware of the current `PromptTheme` and ensures that all components share a unified visual language.

```dart
final lb = LineBuilder(theme);

// Manually construct a styled line
final prefix = lb.gutter(); // e.g., "│ "
final arrow = lb.arrow(isFocused); // e.g., "▶ "
final check = lb.checkbox(isChecked); // e.g., "■ "

out.writeln('$prefix$arrow $check $itemText');
```

### Theming

The rendering engine is entirely driven by `PromptTheme`, which acts as a bridge to the [**`termistyle`**](https://pub.dev/packages/termistyle) package (our dedicated styling library). A theme dictates not just colors (using `termistyle`'s robust ANSI manipulation), but also the structural `TerminalGlyphs` (whether to use rounded corners, sharp corners, or ASCII fallbacks) and `DisplayFeatures` (whether to show borders at all, or use inverse highlighting).

Because `PromptTheme` exposes `termistyle` functions directly (like `theme.accent` or `theme.dim`), you can easily compose complex, styled strings. By passing a theme down through the render tree, your components can instantly adapt to different visual styles.

```dart
// A component rendering with the provided theme (powered by our termistyle package)
final errorColor = theme.error;
final borderChar = theme.glyphs.borderVertical;

if (hasError) {
  // Uses termistyle under the hood to apply the correct ANSI codes
  ctx.errorMessage('Invalid input provided');
}
```

---

## Prompt

The **Prompt** module is the orchestrator that ties IO, Navigation, and Rendering together into a cohesive, interactive lifecycle. It manages the event loop, handles terminal state (like hiding the cursor and entering raw mode), and intercepts key events to update state and trigger re-renders. It is the highest-level abstraction in `terminice_core` and the foundation for all interactive components.

### API Surface

- `PromptRunner`, `RenderOutput`, `TerminalSession`
- `SimplePrompt`, `PromptState`
- `TextPromptSync`, `TextInputBuffer`
- `SelectableListPrompt`, `SearchableListPrompt`, `SelectableGridPrompt` (and more)

### Prompt Runner & Render Output

`PromptRunner` manages the core event loop. It enters raw mode, hides the cursor, and listens for keystrokes. Crucially, it uses `RenderOutput` to ensure that the terminal is never fully cleared. Instead, it tracks exactly how many lines it has written and uses ANSI cursor movements to clear _only_ its own output before the next frame. This preserves the user's terminal history.

```dart
final runner = PromptRunner();
final result = runner.runWithBindings(
  render: (out) {
    out.writeln('Interactive content goes here');
  },
  bindings: myKeyBindings,
);
```

### Simple Prompt

For basic "one value in, one value out" interactions, `SimplePrompt` eliminates boilerplate. It automatically handles cancellation (e.g., pressing `Esc`), default values, and integrates `PromptRunner` with `FrameView` under the hood.

```dart
final confirm = SimplePrompt<bool>(
  title: 'Deploy to production?',
  initialValue: false, // Returned if the user presses Esc
  buildBindings: (state) => KeyBindings.togglePrompt(
    onToggle: () => state.value = !state.value,
    onCancel: state.cancel,
  ),
  render: (ctx, state) {
    ctx.checkboxLine('Confirm deployment', checked: state.value);
  },
).run();
```

### Text Input & Complex Prompts

The module also includes specialized state managers like `TextInputBuffer` for handling typing, backspacing, and cursor movement. It ships with several highly-configurable prompt templates that combine navigation and rendering for you:

- **`SelectableListPrompt`**: Vertical lists with single or multi-select.
- **`SearchableListPrompt`**: Lists with a built-in text buffer for live filtering.
- **`SelectableGridPrompt`**: 2D matrices for picking from a grid.
- **`ValuePrompt`**: Numeric ranges and sliders.

```dart
// A production-ready text prompt with validation and masking
final password = TextPromptSync(
  title: 'Enter password',
  masked: true,
  maskChar: '*',
  required: true,
).run();
```

---

## Testing

The **Testing** module provides a suite of mock objects that allow you to test your terminal UI components in a headless environment. Because `terminice_core` abstracts all `dart:io` interactions through the `TerminalContext`, you can easily swap out the real terminal for a mock one during your test runs. This makes it possible to simulate user input and assert against the exact output rendered to the screen.

### API Surface

- `MockTerminal`, `MockTerminalInput`, `MockTerminalOutput`
- `SpyTerminal`
- `ErrorTerminal`

### Mock Terminal

`MockTerminal` is the primary tool for testing interactive prompts. It allows you to queue up a sequence of simulated keystrokes (like typing a string, pressing arrow keys, and hitting Enter) and then inspect the resulting output buffer to ensure your UI rendered correctly.

```dart
test('SimplePrompt returns true when user presses y', () {
  final mock = MockTerminal();
  TerminalContext.current = mock; // Inject the mock

  // Simulate the user pressing 'y' then 'Enter'
  mock.mockInput.queueKey(KeyEventType.char, 'y');
  mock.mockInput.queueKey(KeyEventType.enter);

  // Run the prompt
  final result = SimplePrompts.confirm(
    title: 'Delete file?',
    message: 'Are you sure?',
  ).run();

  // Assert the logical result
  expect(result, isTrue);

  // Assert the visual output
  expect(mock.mockOutput.allOutput, contains('Delete file?'));
});
```

### Spy and Error Terminals

For more advanced testing scenarios, the module also provides:

- **`SpyTerminal`**: Tracks every method call made to the terminal (e.g., verifying that `hideCursor` and `showCursor` were called in the correct order).
- **`ErrorTerminal`**: A terminal that always throws exceptions, useful for ensuring your components gracefully handle environments where no real terminal is attached (like CI/CD pipelines).

```dart
test('TerminalSession restores cursor visibility', () {
  final spy = SpyTerminal();
  TerminalContext.current = spy;

  final session = TerminalSession(hideCursor: true);
  session.run(() {
    // Do work...
  });

  // Verify the exact sequence of ANSI escape codes written
  expect(spy.calls, contains('output.write')); // hide cursor
  expect(spy.calls, contains('output.write')); // show cursor
});
```
