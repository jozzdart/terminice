import 'package:terminice_core/terminice_core.dart';

/// Internal fallback selection helpers for high-level Terminice components.
class FallbackSelection {
  FallbackSelection._();

  /// Runs a single-select fallback with the shared empty-input default policy.
  static T? single<T>({
    required String title,
    required List<T> options,
    int? defaultIndex,
    Set<int>? defaultIndices,
    FallbackLabelBuilder<T>? labelBuilder,
    bool returnDefaultOnEndOfInput = false,
  }) {
    if (options.isEmpty) return null;

    return FallbackPrompt.singleSelect<T>(
      title: title,
      options: options,
      defaultIndex: _singleDefaultIndex(
        defaultIndex: defaultIndex,
        defaultIndices: defaultIndices,
        length: options.length,
      ),
      labelBuilder: labelBuilder,
      returnDefaultOnEndOfInput: returnDefaultOnEndOfInput,
    );
  }

  /// Runs a multi-select fallback with the shared default-indices policy.
  static List<T> multi<T>({
    required String title,
    required List<T> options,
    Set<int>? defaultIndices,
    int? fallbackIndex,
    FallbackLabelBuilder<T>? labelBuilder,
    bool returnDefaultOnEndOfInput = false,
  }) {
    if (options.isEmpty) return <T>[];

    return FallbackPrompt.multiSelect<T>(
      title: title,
      options: options,
      defaultIndices: normalizedIndices(defaultIndices, options.length),
      fallbackIndex: _normalizedIndex(fallbackIndex, options.length),
      labelBuilder: labelBuilder,
      returnDefaultOnEndOfInput: returnDefaultOnEndOfInput,
    );
  }

  /// Runs a high-level selector fallback and returns selected items as a list.
  static List<T> selectedList<T>({
    required String title,
    required List<T> options,
    required bool multiSelect,
    int? defaultIndex,
    Set<int>? defaultIndices,
    FallbackLabelBuilder<T>? labelBuilder,
    bool returnDefaultOnEndOfInput = false,
  }) {
    return mappedList<T, T>(
      title: title,
      options: options,
      multiSelect: multiSelect,
      defaultIndex: defaultIndex,
      defaultIndices: defaultIndices,
      labelBuilder: labelBuilder,
      returnDefaultOnEndOfInput: returnDefaultOnEndOfInput,
      mapItem: (item) => item,
    );
  }

  /// Runs a high-level selector fallback and maps selected items to results.
  static List<R> mappedList<T, R>({
    required String title,
    required List<T> options,
    required bool multiSelect,
    required R Function(T item) mapItem,
    int? defaultIndex,
    Set<int>? defaultIndices,
    FallbackLabelBuilder<T>? labelBuilder,
    bool returnDefaultOnEndOfInput = false,
  }) {
    if (options.isEmpty) return <R>[];

    if (multiSelect) {
      return multi<T>(
        title: title,
        options: options,
        defaultIndices: defaultIndices,
        // A focused item is not a selected item. With no explicit defaults,
        // blank input confirms the valid empty selection just like rich mode.
        fallbackIndex: null,
        labelBuilder: labelBuilder,
        returnDefaultOnEndOfInput: returnDefaultOnEndOfInput,
      ).map(mapItem).toList();
    }

    final selected = single<T>(
      title: title,
      options: options,
      defaultIndex: defaultIndex,
      defaultIndices: defaultIndices,
      labelBuilder: labelBuilder,
      returnDefaultOnEndOfInput: returnDefaultOnEndOfInput,
    );
    return selected == null ? <R>[] : <R>[mapItem(selected)];
  }

  /// Resolves explicit initial indices to their valid items in index order.
  ///
  /// Single-select callers receive only the first valid sorted index, while
  /// multi-select callers receive every valid index. This is also the shared
  /// unattended-mode policy for selectors that expose initial state.
  static List<T> initialItems<T>({
    required List<T> options,
    required Set<int>? indices,
    required bool multiSelect,
  }) {
    final sorted = normalizedIndices(indices, options.length).toList()..sort();
    final selected = multiSelect ? sorted : sorted.take(1);
    return <T>[for (final index in selected) options[index]];
  }

  /// Removes out-of-range initial indices without inventing replacements.
  static Set<int> normalizedIndices(Set<int>? indices, int length) {
    if (indices == null || length <= 0) return <int>{};
    return indices.where((index) => index >= 0 && index < length).toSet();
  }

  static int? _singleDefaultIndex({
    required int? defaultIndex,
    required Set<int>? defaultIndices,
    required int length,
  }) {
    final validDefaultIndices = normalizedIndices(defaultIndices, length);
    if (validDefaultIndices.isEmpty) {
      return _normalizedIndex(defaultIndex, length);
    }

    final sorted = validDefaultIndices.toList()..sort();
    return sorted.first;
  }

  static int? _normalizedIndex(int? index, int length) {
    if (index == null || length <= 0) return null;
    if (index >= 0 && index < length) return index;
    return null;
  }
}
