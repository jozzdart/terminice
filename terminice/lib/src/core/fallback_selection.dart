import 'package:terminice_core/terminice_core.dart';

/// Internal line-mode selection helpers for high-level Terminice components.
class FallbackSelection {
  FallbackSelection._();

  /// Runs a single-select fallback with the shared empty-input default policy.
  static T? single<T>({
    required String title,
    required List<T> options,
    int? defaultIndex = 0,
    Set<int>? defaultIndices,
    FallbackLabelBuilder<T>? labelBuilder,
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
    );
  }

  /// Runs a multi-select fallback with the shared default-indices policy.
  static List<T> multi<T>({
    required String title,
    required List<T> options,
    Set<int>? defaultIndices,
    int? fallbackIndex,
    FallbackLabelBuilder<T>? labelBuilder,
  }) {
    if (options.isEmpty) return <T>[];

    return FallbackPrompt.multiSelect<T>(
      title: title,
      options: options,
      defaultIndices: defaultIndices,
      fallbackIndex: _focusedFallbackIndex(fallbackIndex, options.length),
      labelBuilder: labelBuilder,
    );
  }

  /// Runs a high-level selector fallback and returns selected items as a list.
  static List<T> selectedList<T>({
    required String title,
    required List<T> options,
    required bool multiSelect,
    int? defaultIndex = 0,
    Set<int>? defaultIndices,
    FallbackLabelBuilder<T>? labelBuilder,
  }) {
    return mappedList<T, T>(
      title: title,
      options: options,
      multiSelect: multiSelect,
      defaultIndex: defaultIndex,
      defaultIndices: defaultIndices,
      labelBuilder: labelBuilder,
      mapItem: (item) => item,
    );
  }

  /// Runs a high-level selector fallback and maps selected items to results.
  static List<R> mappedList<T, R>({
    required String title,
    required List<T> options,
    required bool multiSelect,
    required R Function(T item) mapItem,
    int? defaultIndex = 0,
    Set<int>? defaultIndices,
    FallbackLabelBuilder<T>? labelBuilder,
  }) {
    if (options.isEmpty) return <R>[];

    if (multiSelect) {
      return multi<T>(
        title: title,
        options: options,
        defaultIndices: defaultIndices,
        fallbackIndex: defaultIndex,
        labelBuilder: labelBuilder,
      ).map(mapItem).toList();
    }

    final selected = single<T>(
      title: title,
      options: options,
      defaultIndex: defaultIndex,
      defaultIndices: defaultIndices,
      labelBuilder: labelBuilder,
    );
    return selected == null ? <R>[] : <R>[mapItem(selected)];
  }

  static int? _singleDefaultIndex({
    required int? defaultIndex,
    required Set<int>? defaultIndices,
    required int length,
  }) {
    final validDefaultIndices = _validIndices(defaultIndices, length);
    if (validDefaultIndices.isEmpty) {
      return _focusedFallbackIndex(defaultIndex, length);
    }

    final sorted = validDefaultIndices.toList()..sort();
    return sorted.first;
  }

  static Set<int> _validIndices(Set<int>? indices, int length) {
    if (indices == null || length <= 0) return <int>{};
    return indices.where((index) => index >= 0 && index < length).toSet();
  }

  static int? _focusedFallbackIndex(int? index, int length) {
    if (index == null || length <= 0) return null;
    if (index >= 0 && index < length) return index;
    return 0;
  }
}
