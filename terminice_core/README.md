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
