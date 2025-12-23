import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Generic 2D grid selector with arrow-key navigation.
///
/// Controls:
/// - Arrow keys move across cells (wraps around edges)
/// - Space toggles selection when `multiSelect` is true
/// - Enter confirms the current selection
/// - Esc cancels (returns `[]`)
///
/// Parameters:
/// - `options`: Labels rendered inside each cell.
/// - `prompt`: Frame title text.
/// - `columns`: Fixed column count (auto when zero).
/// - `multiSelect`: Enables toggling multiple cells at once.
/// - `cellWidth`: Overrides computed width per cell.
/// - `maxColumns`: Caps automatically computed column count.
/// - `initialSelection`: Indices that start out selected.
///
/// Example:
/// ```dart
/// final selected = terminice.gridSelector(
///   options: const ['Red', 'Blue', 'Green', 'Yellow'],
///   prompt: 'Select colors',
///   multiSelect: true,
///   initialSelection: {1, 2},
/// );
/// ```
extension GridSelectorExtensions on Terminice {
  /// Renders a flexible grid selector and returns the chosen labels.
  ///
  /// See the file documentation for control hints and parameter details.
  List<String> gridSelector({
    required List<String> options,
    String prompt = 'Select',
    int columns = 0,
    bool multiSelect = false,
    int? cellWidth,
    int? maxColumns,
    Set<int>? initialSelection,
  }) {
    return SelectableGridPrompt<String>(
      title: prompt,
      items: options,
      theme: defaultTheme,
      multiSelect: multiSelect,
      columns: columns,
      cellWidth: cellWidth,
      maxColumns: maxColumns,
      initialSelection: initialSelection,
    ).run();
  }
}
