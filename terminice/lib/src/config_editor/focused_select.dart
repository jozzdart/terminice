import 'package:terminice_core/terminice_core.dart';

/// A searchable single-select prompt that starts the cursor on a given index.
///
/// Functionally equivalent to [SearchableListPrompt] in single-select mode
/// but supports [initialIndex] so configurables can pre-focus the current
/// value instead of always starting at the top.
///
/// A `✓` marker is rendered next to the item at [initialIndex] so the user
/// can see which value was previously set even after scrolling away.
String? focusedSelect({
  required PromptTheme theme,
  required List<String> options,
  required String title,
  int initialIndex = 0,
  bool showSearch = false,
  int maxVisible = 10,
}) {
  if (options.isEmpty) return null;

  final clampedInit = initialIndex.clamp(0, options.length - 1);
  final nav = ListNavigator(
    itemCount: options.length,
    maxVisible: maxVisible,
    initialIndex: clampedInit,
  );

  final searchBuffer = TextInputBuffer();
  var searchActive = showSearch;
  var cancelled = false;

  var filtered = List<String>.from(options);
  var filteredMap = List<int>.generate(options.length, (i) => i);

  void applyFilter({bool resetNav = false}) {
    if (!searchActive || searchBuffer.isEmpty) {
      filtered = List<String>.from(options);
      filteredMap = List<int>.generate(options.length, (i) => i);
    } else {
      final query = searchBuffer.text.toLowerCase();
      filtered = <String>[];
      filteredMap = <int>[];
      for (var i = 0; i < options.length; i++) {
        if (options[i].toLowerCase().contains(query)) {
          filtered.add(options[i]);
          filteredMap.add(i);
        }
      }
    }
    nav.itemCount = filtered.length;
    if (resetNav) nav.reset();
  }

  final bindings = KeyBindings.searchableList(
    onUp: () => nav.moveUp(),
    onDown: () => nav.moveDown(),
    onSearchToggle: () {
      searchActive = !searchActive;
      if (!searchActive) searchBuffer.clear();
      applyFilter(resetNav: true);
    },
    searchBuffer: searchBuffer,
    isSearchEnabled: () => searchActive,
    onSearchInput: () => applyFilter(resetNav: true),
    onCancel: () => cancelled = true,
  );

  final frame = FrameView(title: title, theme: theme, bindings: bindings);

  void render(RenderOutput out) {
    final rows = TerminalInfo.rows;
    final available = rows > 7 ? rows - 7 : 5;
    nav.maxVisible = available.clamp(1, maxVisible);

    frame.render(out, (ctx) {
      ctx.searchLine(searchBuffer.text, enabled: searchActive);
      ctx.writeConnector();

      final window = nav.visibleWindow(filtered);

      ctx.listWindow(
        window,
        selectedIndex: nav.selectedIndex,
        renderItem: (String item, int absoluteIndex, bool isFocused) {
          final origIdx = filteredMap[absoluteIndex];
          final marker =
              origIdx == clampedInit ? '${theme.accent}✓${theme.reset} ' : '  ';
          final arrow = ctx.lb.arrow(isFocused);
          final label = searchActive && searchBuffer.isNotEmpty
              ? highlightSubstring(item, searchBuffer.text, theme)
              : item;
          ctx.highlightedLine(
            '$arrow $marker$label',
            highlighted: isFocused,
          );
        },
      );

      if (filtered.isEmpty) {
        ctx.emptyMessage('no matches');
      }
    });
  }

  applyFilter();

  final runner = PromptRunner(hideCursor: true);
  final result = runner.runWithBindings(
    render: render,
    bindings: bindings,
  );

  if (cancelled || result == PromptResult.cancelled || filtered.isEmpty) {
    return null;
  }

  return filtered[nav.selectedIndex];
}
