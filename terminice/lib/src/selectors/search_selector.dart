import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Presents a filterable list with optional multi-select controls.
///
/// Controls:
/// - ↑ / ↓ navigate through items
/// - / toggles the search field
/// - Type to filter when search is visible
/// - Space toggles the focused option when `multiSelect` is true
/// - Enter confirms the selection
/// - Esc / Ctrl+C cancels (returns `[]`)
///
/// Parameters:
/// - `options`: Items shown in the scrollable list.
/// - `prompt`: Frame title displayed above the list.
/// - `multiSelect`: Enables toggling multiple entries.
/// - `showSearch`: Starts with the search box visible.
/// - `maxVisible`: Maximum rows before scrolling.
///
/// Example:
/// ```dart
/// final chosen = terminice.searchSelector(
///   options: const ['Frogs', 'Dogs', 'Hogs'],
///   prompt: 'Select animal',
///   multiSelect: false,
///   showSearch: true,
/// );
/// ```
extension SearchSelectorExtensions on Terminice {
  /// Renders the searchable list selector and returns the chosen labels.
  ///
  /// See the file-level docs for full behavior and parameters.
  List<String> searchSelector({
    required List<String> options,
    String prompt = 'Select an option',
    bool multiSelect = false,
    bool showSearch = false,
    int maxVisible = 10,
  }) {
    if (options.isEmpty) return [];
    return SearchableListPrompt<String>(
      title: prompt,
      items: options,
      theme: defaultTheme,
      multiSelect: multiSelect,
      maxVisible: maxVisible,
      searchEnabled: showSearch,
    ).run();
  }
}
