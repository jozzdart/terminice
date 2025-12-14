import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Presents a vertical multi-select checklist with a live summary counter.
///
/// Controls:
/// - ↑ / ↓ navigate
/// - Space toggles the focused option
/// - A selects all / clears all
/// - Enter confirms the selection
/// - Esc / Ctrl+C cancels (returns `[]`)
///
/// Parameters:
/// - `label`: Heading rendered in the frame title bar.
/// - `options`: String labels displayed next to the checkboxes.
/// - `initialSelected`: Optional set of indices that start checked.
/// - `maxVisible`: Maximum number of rows before scrolling kicks in.
///
/// Returns a list containing the labels that were confirmed by the user.
///
/// Example:
/// ```dart
/// final choices = terminice.checkboxSelector(
///   label: 'Options',
///   options: ['Alpha', 'Beta', 'Gamma'],
///   initialSelected: {0},
/// );
/// ```
extension CheckboxSelectorExtensions on Terminice {
  /// Renders a keyboard-driven checklist prompt and returns the checked labels.
  ///
  /// See the file-level docs above for controls, parameter details, and usage.
  List<String> checkboxSelector({
    required String label,
    required List<String> options,
    Set<int>? initialSelected,
    int maxVisible = 12,
  }) {
    final theme = defaultTheme;
    if (options.isEmpty) return <String>[];

    // Use SelectableListPrompt for centralized state management
    final prompt = SelectableListPrompt<String>(
      title: label,
      items: options,
      theme: theme,
      multiSelect: true,
      maxVisible: maxVisible,
      initialSelection: initialSelected,
      showConnector: true,
      hintStyle: HintStyle.grid,
    );

    // Summary line builder (captures prompt for access to selection state)
    String buildSummaryLine() {
      final total = options.length;
      final count = prompt.selection.count;
      if (count == 0) {
        return '${theme.dim}(none selected)${theme.reset}';
      }
      // render up to 3 selections by label, then "+N"
      final indices = prompt.selection.getSelectedIndices();
      final names = <String>[];
      for (var i = 0; i < indices.length && i < 3; i++) {
        final name = options[indices[i]];
        names.add('${theme.accent}$name${theme.reset}');
      }
      final more = indices.length > 3
          ? ' ${theme.dim}(+${indices.length - 3})${theme.reset}'
          : '';
      return '${theme.accent}$count${theme.reset}/${theme.dim}$total${theme.reset} • ${names.join('${theme.dim}, ${theme.reset}')} $more';
    }

    return prompt.runCustom(
      // Add select-all binding ('A' key)
      extraBindings: KeyBindings.letter(
        char: 'A',
        onPress: () => prompt.selection.toggleAll(options.length),
        hintDescription: 'select all / clear',
      ),

      // Summary line before items
      beforeItems: (ctx) {
        ctx.gutterLine(buildSummaryLine());
        ctx.writeConnector();
      },

      // Render each item with checkbox
      renderItem: (ctx, item, absoluteIdx, isFocused, isChecked) {
        final arrow = ctx.lb.arrow(isFocused);
        final check = ctx.lb.checkbox(isChecked);

        // Construct core line and fit within terminal width with graceful truncation
        final cols = TerminalInfo.columns;
        var core = '$arrow $check $item';
        final reserve = 0; // no trailing widget for now
        final gutterLen = ctx.lb.gutter().length;
        final maxLabel = (cols - gutterLen - 1 - reserve).clamp(8, cols);
        if (core.length > maxLabel) {
          core = '${core.substring(0, maxLabel - 3)}...';
        }

        ctx.highlightedLine(core, highlighted: isFocused);
      },
    );
  }
}
