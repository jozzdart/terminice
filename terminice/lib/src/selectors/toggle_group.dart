import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Extension providing the [toggleGroup] prompt for `Terminice`.
extension ToggleGroupExtensions on Terminice {
  /// Runs a toggle group prompt to manage multiple on/off switches.
  ///
  /// Controls:
  /// - ↑ / ↓ navigate between rows
  /// - ← / → or Space toggles the focused switch
  /// - A toggles all switches
  /// - Enter confirms the edited states
  /// - Esc / Ctrl+C cancels (returns the initial map)
  ///
  /// Parameters:
  /// - [prompt]: Frame heading shown alongside the connector.
  /// - [items]: Collection of [ToggleItem]s with labels and initial states.
  /// - [alignContent]: When true, pads labels to create a tidy column.
  ///
  /// Returns a `Map<String, bool>` describing the confirmed state.
  ///
  /// Example:
  /// ```dart
  /// final settings = terminice.toggleGroup(
  ///   'Settings',
  ///   items: const [
  ///     ToggleItem('Auto deploy', initialOn: true),
  ///     ToggleItem('Send email'),
  ///   ],
  /// );
  /// ```
  Map<String, bool> toggleGroup(
    String prompt, {
    required List<ToggleItem> items,
    bool alignContent = true,
  }) {
    if (items.isEmpty) return const {};
    final theme = defaultTheme;

    // Use centralized focus navigation
    final focus = FocusNavigator(itemCount: items.length);
    bool cancelled = false;
    final states = List<bool>.generate(items.length, (i) => items[i].initialOn);
    final initialStates = List<bool>.from(states);

    int maxLabelWidth() {
      var w = 0;
      for (final it in items) {
        final len = it.label.length;
        if (len > w) w = len;
      }
      if (w < 8) w = 8;
      if (w > 48) w = 48; // cap for tidy layout
      return w;
    }

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings.toggleGroup(
      onUp: () => focus.moveUp(),
      onDown: () => focus.moveDown(),
      onToggle: () => states[focus.focusedIndex] = !states[focus.focusedIndex],
      onToggleAll: () {
        final anyOff = states.any((s) => s == false);
        for (var i = 0; i < states.length; i++) {
          states[i] = anyOff;
        }
      },
      onCancel: () => cancelled = true,
    );

    // Use WidgetFrame for consistent frame rendering
    final frame = FrameView(
      title: prompt,
      theme: theme,
      bindings: bindings,
    );

    void render(RenderOutput out) {
      frame.render(out, (ctx) {
        final gap = 2;
        final labelWidth = maxLabelWidth();

        for (var i = 0; i < items.length; i++) {
          final isFocused = focus.isFocused(i);
          final item = items[i];

          var label = item.label;
          if (label.length > labelWidth) {
            label = '${label.substring(0, labelWidth - 1)}…';
          }
          final paddedLabel = label.padRight(labelWidth);

          // Use LineBuilder for arrow and switch
          final arrow = ctx.lb.arrow(isFocused);
          final switchTxt =
              ctx.lb.switchControlHighlighted(states[i], highlight: isFocused);

          final lineCore = '$arrow $paddedLabel${' ' * gap}$switchTxt';
          ctx.gutterLine(lineCore);
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    final resultMap = <String, bool>{};
    final finalStates = (cancelled || result == PromptResult.cancelled)
        ? initialStates
        : states;
    for (var i = 0; i < items.length; i++) {
      resultMap[items[i].label] = finalStates[i];
    }
    return resultMap;
  }
}

/// Represents a single row in a toggle group.
///
/// Contains the [label] to display and its [initialOn] state.
class ToggleItem {
  /// The text displayed next to the toggle switch.
  final String label;

  /// Whether the toggle is initially turned on.
  final bool initialOn;

  /// Creates a new [ToggleItem].
  ///
  /// Provide a [label] and optionally set [initialOn] to true.
  const ToggleItem(this.label, {this.initialOn = false});
}
