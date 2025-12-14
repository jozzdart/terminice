import 'package:terminice_core/terminice_core.dart';

/// RankedListPrompt – composable system for searchable lists with custom ranking.
///
/// Extends the search pattern with:
/// - Custom ranking/scoring for each item
/// - Match highlight spans for visual feedback
/// - Fuzzy or substring matching modes
///
/// **Design principles:**
/// - Composition over inheritance
/// - Separation of concerns (ranking is separate from navigation/rendering)
/// - DRY: Centralizes the ranked search pattern (CommandPalette, etc.)
///
/// **Usage:**
/// ```dart
/// final prompt = RankedListPrompt<CommandEntry>(
///   title: 'Command Palette',
///   items: commands,
///   rankItem: (item, query, useFuzzy) => fuzzyMatch(item.title, query),
///   itemLabel: (item) => item.title,
/// );
///
/// final result = prompt.run();
/// ```
class RankedListPrompt<T> {
  /// Title for the frame header.
  final String title;

  /// All items (before ranking).
  final List<T> items;

  /// Theme for styling.
  final PromptTheme theme;

  /// Maximum visible items (viewport size).
  final int maxVisible;

  /// Whether search input is always visible (vs toggle with /).
  final bool alwaysShowSearch;

  /// Initial search mode (true = fuzzy, false = substring).
  final bool initialFuzzyMode;

  /// Hint style for key bindings display.
  final HintStyle hintStyle;

  /// Terminal lines to reserve for chrome.
  final int reservedLines;

  // ──────────────────────────────────────────────────────────────────────────
  // INTERNAL STATE
  // ──────────────────────────────────────────────────────────────────────────

  late ListNavigator _nav;
  late TextInputBuffer _queryInput;
  late KeyBindings _bindings;
  late List<RankedItem<T>> _ranked;
  late bool _useFuzzy;
  bool _cancelled = false;
  T? _result;

  RankedListPrompt({
    required this.title,
    required this.items,
    this.theme = PromptTheme.dark,
    this.maxVisible = 12,
    this.alwaysShowSearch = true,
    this.initialFuzzyMode = true,
    this.hintStyle = HintStyle.grid,
    this.reservedLines = 8,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ACCESSORS
  // ──────────────────────────────────────────────────────────────────────────

  /// Current navigation state.
  ListNavigator get nav => _nav;

  /// Current search query input.
  TextInputBuffer get queryInput => _queryInput;

  /// Current key bindings.
  KeyBindings get bindings => _bindings;

  /// Currently ranked items.
  List<RankedItem<T>> get ranked => _ranked;

  /// Whether fuzzy mode is active.
  bool get useFuzzy => _useFuzzy;

  /// Whether the prompt was cancelled.
  bool get wasCancelled => _cancelled;

  // ──────────────────────────────────────────────────────────────────────────
  // RUN
  // ──────────────────────────────────────────────────────────────────────────

  /// Runs the ranked list prompt.
  ///
  /// [rankItem] - Ranking function that returns score and highlight spans.
  ///   Return null to exclude item from results.
  /// [itemLabel] - Converts item to display label.
  /// [itemSubtitle] - Optional subtitle for items.
  /// [renderItem] - Custom item renderer. If null, uses default style.
  /// [beforeItems] - Content to render before the list.
  /// [extraBindings] - Additional key bindings.
  ///
  /// Returns selected item on confirm, null on cancel.
  T? run({
    required RankResult? Function(T item, String query, bool useFuzzy) rankItem,
    required String Function(T item) itemLabel,
    String? Function(T item)? itemSubtitle,
    void Function(
      FrameContext ctx,
      RankedItem<T> rankedItem,
      int index,
      bool isFocused,
      String query,
    )? renderItem,
    void Function(
            FrameContext ctx, String query, bool useFuzzy, int matchCount)?
        beforeItems,
    KeyBindings? extraBindings,
  }) {
    if (items.isEmpty) return null;

    _initState();

    void updateRanking() {
      final query = _queryInput.text;
      if (query.isEmpty) {
        _ranked = items
            .map((item) => RankedItem(item, 0, const []))
            .toList(growable: false);
      } else {
        final results = <RankedItem<T>>[];
        for (final item in items) {
          final rankResult = rankItem(item, query, _useFuzzy);
          if (rankResult != null) {
            results.add(RankedItem(item, rankResult.score, rankResult.spans));
          }
        }
        results.sort((a, b) {
          final sc = b.score.compareTo(a.score);
          if (sc != 0) return sc;
          return itemLabel(a.item)
              .toLowerCase()
              .compareTo(itemLabel(b.item).toLowerCase());
        });
        _ranked = results;
      }
      _nav.itemCount = _ranked.length;
      _nav.reset();
    }

    // Create bindings
    _bindings = KeyBindings.verticalNavigation(
          onUp: () => _nav.moveUp(),
          onDown: () => _nav.moveDown(),
        ) +
        _queryInput.toTextInputBindings(onInput: updateRanking) +
        KeyBindings.ctrlR(
          onPress: () {
            _useFuzzy = !_useFuzzy;
            updateRanking();
          },
          hintDescription: 'toggle mode',
        ) +
        KeyBindings.confirm(onConfirm: () {
          if (_ranked.isNotEmpty) {
            _result = _ranked[_nav.selectedIndex].item;
          }
          return KeyActionResult.confirmed;
        }) +
        KeyBindings.cancel(onCancel: () => _cancelled = true);

    if (extraBindings != null) {
      _bindings = _bindings + extraBindings;
    }

    final frame = FrameView(
      title: title,
      theme: theme,
      bindings: _bindings,
      showConnector: true,
      hintStyle: hintStyle,
    );

    void render(RenderOutput out) {
      _nav.maxVisible =
          (TerminalInfo.rows - reservedLines).clamp(5, maxVisible);

      frame.render(out, (ctx) {
        // Before items hook or default header
        if (beforeItems != null) {
          beforeItems(ctx, _queryInput.text, _useFuzzy, _ranked.length);
        } else {
          ctx.headerLine('Search', _queryInput.text);
          ctx.writeConnector();
          final mode = _useFuzzy ? 'Fuzzy' : 'Substring';
          ctx.infoLine([mode, 'Matches: ${_ranked.length}']);
        }

        // Visible window
        final window = _nav.visibleWindow(_ranked);

        ctx.listWindow(
          window,
          selectedIndex: _nav.selectedIndex,
          renderItem: (rankedItem, index, isFocused) {
            if (renderItem != null) {
              renderItem(ctx, rankedItem, index, isFocused, _queryInput.text);
            } else {
              // Default rendering with span highlighting
              final label = itemLabel(rankedItem.item);
              final highlighted =
                  highlightSpans(label, rankedItem.spans, theme);
              final subtitle = itemSubtitle?.call(rankedItem.item);
              final subtitlePart = subtitle == null
                  ? ''
                  : '  ${theme.dim}$subtitle${theme.reset}';

              final arrow = ctx.lb.arrow(isFocused);
              ctx.highlightedLine(
                '$arrow $highlighted$subtitlePart',
                highlighted: isFocused,
              );
            }
          },
        );

        if (_ranked.isEmpty) {
          ctx.emptyMessage('no matches');
        }
      });
    }

    updateRanking();

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(
      render: render,
      bindings: _bindings,
    );

    return _cancelled ? null : _result;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ──────────────────────────────────────────────────────────────────────────

  void _initState() {
    _cancelled = false;
    _result = null;
    _useFuzzy = initialFuzzyMode;
    _queryInput = TextInputBuffer();
    _ranked = [];

    _nav = ListNavigator(
      itemCount: 0,
      maxVisible: maxVisible,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SUPPORTING TYPES
// ════════════════════════════════════════════════════════════════════════════

/// Result of ranking an item.
class RankResult {
  /// Score for sorting (higher = better match).
  final int score;

  /// Character indices that matched (for highlighting).
  final List<int> spans;

  const RankResult(this.score, this.spans);

  /// No match result.
  static const RankResult? noMatch = null;
}

/// A ranked item with score and highlight spans.
class RankedItem<T> {
  /// The original item.
  final T item;

  /// Ranking score (higher = better match).
  final int score;

  /// Character indices that matched (for highlighting).
  final List<int> spans;

  const RankedItem(this.item, this.score, this.spans);
}

// ════════════════════════════════════════════════════════════════════════════
// FUZZY MATCHING UTILITIES
// ════════════════════════════════════════════════════════════════════════════

/// Highlights matched spans in text using theme colors.
String highlightSpans(String text, List<int> indices, PromptTheme theme) {
  if (indices.isEmpty) return text;
  final set = indices.toSet();
  final buf = StringBuffer();
  bool inSpan = false;
  for (var i = 0; i < text.length; i++) {
    final isMatch = set.contains(i);
    if (isMatch && !inSpan) {
      buf.write(theme.highlight);
      inSpan = true;
    } else if (!isMatch && inSpan) {
      buf.write(theme.reset);
      inSpan = false;
    }
    buf.write(text[i]);
  }
  if (inSpan) buf.write(theme.reset);
  return buf.toString();
}

/// Standard fuzzy matcher with scoring.
///
/// Returns null if pattern doesn't match, otherwise returns score and indices.
RankResult? fuzzyMatch(String text, String pattern) {
  if (pattern.isEmpty) return const RankResult(0, []);

  final t = text.toLowerCase();
  final p = pattern.toLowerCase();
  int ti = 0;
  final matched = <int>[];

  for (var pi = 0; pi < p.length; pi++) {
    final ch = p[pi];
    final found = t.indexOf(ch, ti);
    if (found == -1) return null;
    matched.add(found);
    ti = found + 1;
  }

  if (matched.isEmpty) return null;

  // Scoring: prefer contiguous, early, word-boundary and case-exact matches
  int score = 0;

  // Base: more compact span is better
  final span = matched.last - matched.first + 1;
  score += (100000 - span * 300).clamp(0, 100000);

  // Contiguity bonus
  for (var i = 1; i < matched.length; i++) {
    if (matched[i] == matched[i - 1] + 1) score += 1200;
  }

  // Early start bonus
  score += (8000 - matched.first * 200).clamp(0, 8000);

  // Word boundary bonus
  final before = matched.first > 0 ? text[matched.first - 1] : ' ';
  if (before == ' ' ||
      before == '-' ||
      before == '_' ||
      before == '/' ||
      before == '.') {
    score += 2500;
  }

  // Exact case bonus
  for (var i = 0; i < matched.length; i++) {
    if (i < pattern.length && matched[i] < text.length) {
      if (text[matched[i]] == pattern[i]) score += 150;
    }
  }

  return RankResult(score, matched);
}

/// Standard substring matcher with scoring.
///
/// Returns null if pattern not found, otherwise returns score and indices.
RankResult? substringMatch(String text, String pattern) {
  if (pattern.isEmpty) return const RankResult(0, []);

  final idx = text.toLowerCase().indexOf(pattern.toLowerCase());
  if (idx == -1) return null;

  // Score based on position (earlier = better)
  final score = 100000 - idx * 100;
  final indices = List<int>.generate(pattern.length, (i) => idx + i);

  return RankResult(score, indices);
}

/// Combines fuzzy and substring matching based on mode.
RankResult? standardMatch(String text, String pattern, bool useFuzzy) {
  return useFuzzy ? fuzzyMatch(text, pattern) : substringMatch(text, pattern);
}
