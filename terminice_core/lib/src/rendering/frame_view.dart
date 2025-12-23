import 'package:terminice_core/terminice_core.dart';

/// FrameView – Composable frame rendering for terminal views.
///
/// Eliminates the common boilerplate pattern found across views/prompts:
/// - Create FramedLayout
/// - Write top (with conditional bold)
/// - Write content lines with LineBuilder
/// - Write bottom border (conditionally)
/// - Write hints from KeyBindings
///
/// **Before FrameView:**
/// ```dart
/// void render(RenderOutput out) {
///   final lb = LineBuilder(theme);
///   final frame = FramedLayout(title, theme: theme);
///
///   out.writeln(theme.boldTitles
///     ? '${theme.bold}${frame.top()}${theme.reset}'
///     : frame.top());
///
///   // ... 10+ lines of content setup ...
///
///   if (theme.showBorders) {
///     out.writeln(frame.bottom());
///   }
///
///   out.writeln(bindings.toHintsBullets(theme));
/// }
/// ```
///
/// **After FrameView:**
/// ```dart
/// void render(RenderOutput out) {
///   final wf = FrameView(title: title, theme: theme, bindings: bindings);
///   wf.render(out, (ctx) {
///     ctx.line('Content line');
///     ctx.gutterLine('Indented content');
///   });
/// }
/// ```
///
/// **Features:**
/// - Automatic themed frame (top/bottom borders)
/// - `FrameContext` provides `LineBuilder` + convenience methods
/// - Automatic hints from KeyBindings
/// - Connector line support
/// - Consistent styling across all views
///
/// **Design principles:**
/// - Composition over inheritance
/// - Separation of concerns (frame rendering vs view logic)
/// - Backward compatible (use alongside existing patterns)
class FrameView {
  /// Title displayed in the frame header.
  final String title;

  /// Theme for colors and styling.
  final PromptTheme theme;

  /// Key bindings for hint generation.
  final KeyBindings? bindings;

  const FrameView({
    required this.title,
    required this.theme,
    this.bindings,
  });

  /// Hint style from theme.
  HintStyle get hintStyle => theme.hintStyle;

  /// Whether to show connector from theme.
  bool get showConnector => theme.showConnector;

  /// Shorthand access to glyphs.
  TerminalGlyphs get glyphs => theme.glyphs;

  /// Shorthand access to features.
  DisplayFeatures get features => theme.features;

  /// Renders the complete frame with content.
  ///
  /// [content] receives a [FrameContext] with helper methods for writing
  /// styled lines. The frame handles top, bottom, and hints automatically.
  ///
  /// Example:
  /// ```dart
  /// wf.render(out, (ctx) {
  ///   ctx.gutterLine('${theme.accent}Name:${theme.reset} $name');
  ///   ctx.gutterLine('${ctx.lb.checkbox(selected)} Toggle option');
  /// });
  /// ```
  void render(
    RenderOutput out,
    void Function(FrameContext ctx) content,
  ) {
    final frame = FramedLayout(title, theme: theme);
    final lb = LineBuilder(theme);
    final ctx = FrameContext._(out, lb, theme, frame);

    // Top border
    ctx.writeTop();

    // Optional connector
    if (showConnector && features.showBorders) {
      out.writeln(frame.connector());
    }

    // Content callback
    content(ctx);

    // Bottom border
    if (features.showBorders) {
      out.writeln(frame.bottom());
    }

    // Hints
    if (bindings != null) {
      _writeHints(out, bindings!);
    }
  }

  /// Renders without hints (for nested/partial renders).
  void renderContent(
    RenderOutput out,
    void Function(FrameContext ctx) content,
  ) {
    final frame = FramedLayout(title, theme: theme);
    final lb = LineBuilder(theme);
    final ctx = FrameContext._(out, lb, theme, frame);

    ctx.writeTop();

    if (showConnector && features.showBorders) {
      out.writeln(frame.connector());
    }

    content(ctx);

    if (features.showBorders) {
      out.writeln(frame.bottom());
    }
  }

  /// Writes hints in the configured style.
  void _writeHints(RenderOutput out, KeyBindings bindings) {
    switch (hintStyle) {
      case HintStyle.bullets:
        out.writeln(bindings.toHintsBullets(theme));
        break;
      case HintStyle.grid:
        out.writeln(bindings.toHintsGrid(theme));
        break;
      case HintStyle.inline:
        final entries = bindings.toHintEntries();
        final hints = entries.map((e) => '${e[0]}: ${e[1]}').toList();
        out.writeln(HintFormat.comma(hints, theme));
        break;
      case HintStyle.none:
        break;
    }
  }
}

// HintStyle is now defined in display_features.dart and re-exported through prompt_theme.dart

/// Context passed to the content callback during frame rendering.
///
/// Provides convenient methods for writing styled content lines
/// within the frame. Wraps `LineBuilder` and `RenderOutput` together.
class FrameContext {
  /// The render output to write to.
  final RenderOutput out;

  /// LineBuilder for consistent styling.
  final LineBuilder lb;

  /// Theme for colors and ANSI codes.
  final PromptTheme theme;

  /// Frame layout for structure.
  final FramedLayout frame;

  const FrameContext._(this.out, this.lb, this.theme, this.frame);

  /// Shorthand access to glyphs.
  TerminalGlyphs get glyphs => theme.glyphs;

  /// Shorthand access to features.
  DisplayFeatures get features => theme.features;

  // ──────────────────────────────────────────────────────────────────────────
  // FRAME STRUCTURE
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes the top border line with optional bold styling.
  void writeTop() {
    final top = frame.top();
    out.writeln(features.boldTitles ? '${theme.bold}$top${theme.reset}' : top);
  }

  /// Writes a connector line (├─────).
  void writeConnector() {
    if (features.showBorders) {
      out.writeln(frame.connector());
    }
  }

  /// Writes the bottom border line.
  void writeBottom() {
    if (features.showBorders) {
      out.writeln(frame.bottom());
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LINE WRITING
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a plain line (no gutter).
  void line(String content) {
    out.writeln(content);
  }

  /// Writes an empty line.
  void emptyLine() {
    out.writeln('');
  }

  /// Writes a line with the gutter prefix (│ content).
  void gutterLine(String content) {
    out.writeln('${lb.gutter()}$content');
  }

  /// Writes an empty gutter line (│).
  void gutterEmpty() {
    out.writeln(lb.gutterOnly());
  }

  /// Writes a line with optional inverse highlight.
  ///
  /// Delegates to LineBuilder's writeLine for consistent highlight handling.
  void highlightedLine(
    String content, {
    bool highlighted = false,
    bool includeGutter = true,
  }) {
    lb.writeLine(out, content,
        highlighted: highlighted, includeGutter: includeGutter);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STYLED CONTENT
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a selectable item line with arrow indicator.
  void selectableItem(String content, {required bool focused}) {
    lb.writeSelectableLine(out, content, focused: focused);
  }

  /// Writes a checkbox item line with arrow and checkbox.
  void checkboxItem(
    String content, {
    required bool focused,
    required bool checked,
  }) {
    lb.writeCheckboxLine(out, content, focused: focused, checked: checked);
  }

  /// Writes an overflow indicator line (│ ...).
  void overflowIndicator() {
    out.writeln(lb.overflowLine());
  }

  /// Writes an empty message line (│ (message)).
  void emptyMessage(String message) {
    out.writeln(lb.emptyLine(message));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LABELED VALUES
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a labeled value line: │ Label: Value
  void labeledValue(String label, String value, {bool dimLabel = true}) {
    final labelPart =
        dimLabel ? '${theme.dim}$label:${theme.reset}' : '$label:';
    gutterLine('$labelPart $value');
  }

  /// Writes a labeled value with accent color on the value.
  void labeledAccent(String label, String value) {
    gutterLine(
        '${theme.dim}$label:${theme.reset} ${theme.accent}$value${theme.reset}');
  }

  /// Writes a bold message line.
  void boldMessage(String message) {
    gutterLine('${theme.bold}$message${theme.reset}');
  }

  /// Writes a dimmed/muted message line.
  void dimMessage(String message) {
    gutterLine('${theme.dim}$message${theme.reset}');
  }

  /// Writes an error message line.
  void errorMessage(String message) {
    gutterLine('${theme.error}$message${theme.reset}');
  }

  /// Writes a warning message line.
  void warnMessage(String message) {
    gutterLine('${theme.warn}$message${theme.reset}');
  }

  /// Writes an info message line.
  void infoMessage(String message) {
    gutterLine('${theme.info}$message${theme.reset}');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // COMPOSITE PATTERNS
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a list of items with selection indicator.
  ///
  /// [items] is the list of items to display.
  /// [selectedIndex] is the currently selected index.
  /// [startIndex] is the offset for viewport scrolling (default 0).
  /// [itemBuilder] converts an item to its display string.
  void selectionList<T>(
    List<T> items, {
    required int selectedIndex,
    int startIndex = 0,
    String Function(T item)? itemBuilder,
  }) {
    for (var i = 0; i < items.length; i++) {
      final absoluteIndex = startIndex + i;
      final isSelected = absoluteIndex == selectedIndex;
      final text = itemBuilder?.call(items[i]) ?? items[i].toString();
      selectableItem(text, focused: isSelected);
    }
  }

  /// Writes a list of checkbox items.
  ///
  /// [items] is the list of items to display.
  /// [focusedIndex] is the currently focused index.
  /// [checkedIndices] is the set of checked item indices.
  /// [startIndex] is the offset for viewport scrolling (default 0).
  /// [itemBuilder] converts an item to its display string.
  void checkboxList<T>(
    List<T> items, {
    required int focusedIndex,
    required Set<int> checkedIndices,
    int startIndex = 0,
    String Function(T item)? itemBuilder,
  }) {
    for (var i = 0; i < items.length; i++) {
      final absoluteIndex = startIndex + i;
      final isFocused = absoluteIndex == focusedIndex;
      final isChecked = checkedIndices.contains(absoluteIndex);
      final text = itemBuilder?.call(items[i]) ?? items[i].toString();
      checkboxItem(text, focused: isFocused, checked: isChecked);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SEARCH & INPUT PATTERNS
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a search input line: │ Search: [query]
  void searchLine(String query, {bool enabled = true}) {
    if (enabled) {
      gutterLine('${theme.accent}Search:${theme.reset} $query');
    } else {
      dimMessage('(Search disabled — press / to enable)');
    }
  }

  /// Writes a key-value header line: │ Key: Value (key is accent, value is normal)
  void headerLine(String key, String value) {
    gutterLine('${theme.accent}$key:${theme.reset} $value');
  }

  /// Writes an input line with cursor: │ ▶ [text][cursor]
  void inputLine(String text, {bool showCursor = true, String? placeholder}) {
    final display = text.isEmpty && placeholder != null
        ? '${theme.dim}$placeholder${theme.reset}'
        : text;
    final cursor = showCursor ? '${theme.accent}▌${theme.reset}' : '';
    gutterLine('${lb.arrowAccent()} $display$cursor');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LIST NAVIGATION INTEGRATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Renders a ListWindow with selection and custom rendering.
  ///
  /// This handles overflow indicators automatically and delegates
  /// item rendering to the provided callback.
  ///
  /// Example:
  /// ```dart
  /// final window = nav.visibleWindow(items);
  /// ctx.listWindow(
  ///   window,
  ///   selectedIndex: nav.selectedIndex,
  ///   renderItem: (item, index, isFocused) {
  ///     ctx.selectableItem(item.toString(), focused: isFocused);
  ///   },
  /// );
  /// ```
  void listWindow<T>(
    ListWindow<T> window, {
    required int selectedIndex,
    required void Function(T item, int absoluteIndex, bool isFocused)
        renderItem,
  }) {
    if (window.hasOverflowAbove) {
      overflowIndicator();
    }

    for (var i = 0; i < window.items.length; i++) {
      final absoluteIndex = window.start + i;
      final isFocused = absoluteIndex == selectedIndex;
      renderItem(window.items[i], absoluteIndex, isFocused);
    }

    if (window.hasOverflowBelow) {
      overflowIndicator();
    }
  }

  /// Renders a simple selection list from a ListWindow.
  ///
  /// Convenience wrapper around [listWindow] for the common case
  /// of rendering a simple selectable list.
  void selectionWindow<T>(
    ListWindow<T> window, {
    required int selectedIndex,
    String Function(T item)? itemBuilder,
  }) {
    listWindow(
      window,
      selectedIndex: selectedIndex,
      renderItem: (T item, int index, bool isFocused) {
        final text = itemBuilder?.call(item) ?? item.toString();
        selectableItem(text, focused: isFocused);
      },
    );
  }

  /// Renders a checkbox list from a ListWindow.
  ///
  /// Convenience wrapper around [listWindow] for multi-select lists.
  void checkboxWindow<T>(
    ListWindow<T> window, {
    required int focusedIndex,
    required Set<int> checkedIndices,
    String Function(T item)? itemBuilder,
  }) {
    listWindow<T>(
      window,
      selectedIndex: focusedIndex,
      renderItem: (item, index, isFocused) {
        final isChecked = checkedIndices.contains(index);
        final text = itemBuilder?.call(item) ?? item.toString();
        checkboxItem(text, focused: isFocused, checked: isChecked);
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CUSTOM ITEM PATTERNS
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a custom selectable item with a prefix before the content.
  ///
  /// Useful for items that need extra decoration beyond the arrow indicator.
  /// The prefix appears after the arrow, before the content.
  ///
  /// Example: `▶ [x] Option 1` where `[x]` is the prefix.
  void selectableItemWithPrefix(
    String content, {
    required bool focused,
    required String prefix,
  }) {
    final arrow = lb.arrow(focused);
    final line = '$arrow $prefix $content';
    highlightedLine(line, highlighted: focused);
  }

  /// Writes an item line with custom leading glyph.
  ///
  /// Useful for tree structures, icons, or other custom prefixes.
  void customItem(
    String content, {
    required bool focused,
    String? leadingGlyph,
    bool highlighted = false,
  }) {
    final arrow = lb.arrow(focused);
    final glyph = leadingGlyph != null ? '$leadingGlyph ' : '';
    final line = '$arrow $glyph$content';
    highlightedLine(line, highlighted: highlighted && focused);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MODE & INFO LINES
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a mode/info status line with multiple segments.
  ///
  /// Each segment is separated by spaces. Useful for showing
  /// multiple status indicators like "Fuzzy   Matches: 5".
  void infoLine(List<String> segments, {int spacing = 3}) {
    final separator = ' ' * spacing;
    gutterLine('${theme.dim}${segments.join(separator)}${theme.reset}');
  }

  /// Writes a summary/count line: │ count/total • item1, item2, ...
  void summaryLine(int count, int total, {List<String>? highlights}) {
    final countPart =
        '${theme.accent}$count${theme.reset}/${theme.dim}$total${theme.reset}';
    if (highlights != null && highlights.isNotEmpty) {
      final items =
          highlights.map((h) => '${theme.accent}$h${theme.reset}').join(', ');
      gutterLine('$countPart • $items');
    } else {
      gutterLine(countPart);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DISPLAY-ONLY PATTERNS
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a stat item line with icon: │ ✔ Label: Value
  ///
  /// Useful for stat cards and dashboard displays.
  void statItem(
    String label,
    String value, {
    String icon = '•',
    StatTone tone = StatTone.accent,
  }) {
    final toneColor = _toneColor(tone, theme);
    final line = StringBuffer();
    line.write('$toneColor$icon${theme.reset} ');
    line.write('${theme.dim}$label:${theme.reset} ');
    line.write('${theme.selection}${theme.bold}$value${theme.reset}');
    gutterLine(line.toString());
  }

  /// Writes a styled message line with icon: │ ℹ Message
  ///
  /// Useful for info boxes, toasts, and notifications.
  void styledMessage(
    String message, {
    String icon = 'ℹ',
    StatTone tone = StatTone.info,
    bool bold = false,
  }) {
    final toneColor = _toneColor(tone, theme);
    final iconPart = '${theme.bold}$toneColor$icon${theme.reset}';
    final msgPart = bold ? '${theme.bold}$message${theme.reset}' : message;
    gutterLine('$iconPart $msgPart');
  }

  /// Writes a section header line: ├─ SectionName
  void sectionHeader(String name) {
    line(
        '${theme.gray}${glyphs.borderConnector}${theme.reset} ${theme.dim}$name${theme.reset}');
  }

  /// Writes a progress bar line: │ ████████░░░░ 75%
  void progressBar(
    double ratio, {
    int width = 20,
    String filledChar = '█',
    String emptyChar = '░',
    bool showPercent = true,
  }) {
    final clamped = ratio.clamp(0.0, 1.0);
    final filled = (clamped * width).round();
    final bar =
        '${theme.accent}${filledChar * filled}${theme.reset}${theme.dim}${emptyChar * (width - filled)}${theme.reset}';
    if (showPercent) {
      final pct = (clamped * 100).round();
      gutterLine('$bar ${theme.dim}$pct%${theme.reset}');
    } else {
      gutterLine(bar);
    }
  }

  /// Writes a key-value pair line with colored value: │ key = value
  void keyValue(String key, String value, {String separator = '='}) {
    gutterLine(
        '${theme.highlight}$key${theme.reset} ${theme.dim}$separator${theme.reset} ${theme.selection}$value${theme.reset}');
  }

  /// Writes a bullet item line: │ • Item text
  void bulletItem(String content, {String bullet = '•'}) {
    gutterLine('${theme.dim}$bullet${theme.reset} $content');
  }

  /// Writes a numbered item line: │ 1. Item text
  void numberedItem(int number, String content) {
    gutterLine('${theme.dim}$number.${theme.reset} $content');
  }

  /// Writes a tree branch item: │ ├─ Item
  void treeBranch(String content, {bool isLast = false}) {
    final branch = isLast ? '└─' : '├─';
    gutterLine('${theme.gray}$branch${theme.reset} $content');
  }

  /// Writes an equation/conversion line: │ Label value → Label = value
  void equation({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
    String direction = '→',
  }) {
    final numL = '${theme.selection}$leftValue${theme.reset}';
    final numR = '${theme.selection}$rightValue${theme.reset}';
    final labL = '${theme.highlight}$leftLabel${theme.reset}';
    final labR = '${theme.highlight}$rightLabel${theme.reset}';
    final arrow = '${theme.dim}$direction${theme.reset}';
    final eq = '${theme.dim}=${theme.reset}';
    gutterLine('$labL $numL $arrow $labR $eq $numR');
  }

  /// Writes a tooltip/help hint line: │ (press Enter to continue)
  void tooltipLine(String hint) {
    gutterLine('${theme.dim}($hint)${theme.reset}');
  }

  /// Writes a separator line within the frame: │ ──────────
  void separatorLine({int width = 20}) {
    gutterLine('${theme.gray}${'─' * width}${theme.reset}');
  }

  /// Writes a blank line with optional filler character.
  void fillerLine({String? char}) {
    if (char != null) {
      gutterLine('${theme.dim}$char${theme.reset}');
    } else {
      gutterEmpty();
    }
  }
}

/// Tone for stat/styled items.
enum StatTone { info, warn, error, accent, success, neutral }

String _toneColor(StatTone tone, PromptTheme theme) {
  switch (tone) {
    case StatTone.info:
      return theme.info;
    case StatTone.warn:
      return theme.warn;
    case StatTone.error:
      return theme.error;
    case StatTone.accent:
      return theme.accent;
    case StatTone.success:
      return theme.checkboxOn;
    case StatTone.neutral:
      return theme.gray;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DISPLAY-ONLY EXTENSIONS
// ════════════════════════════════════════════════════════════════════════════

/// Extension methods for display-only (non-interactive) frame rendering.
extension FrameViewDisplayExtensions on FrameView {
  /// Renders to stdout and returns immediately.
  ///
  /// Use for display-only views that don't need interactivity.
  /// Creates a RenderOutput internally and renders the frame.
  ///
  /// Example:
  /// ```dart
  /// final frame = FrameView(title: 'Stats', theme: theme);
  /// frame.show((ctx) {
  ///   ctx.statItem('Tests', '98%', icon: '✔', tone: StatTone.success);
  ///   ctx.statItem('Coverage', '85%', icon: '◎', tone: StatTone.info);
  /// });
  /// ```
  void show(void Function(FrameContext ctx) content) {
    final out = RenderOutput();
    render(out, content);
  }

  /// Renders to a provided RenderOutput without interaction.
  ///
  /// Useful when you need to compose display-only frames with other outputs.
  void showTo(RenderOutput out, void Function(FrameContext ctx) content) {
    render(out, content);
  }

  /// Renders content only (no frame borders) to a provided RenderOutput.
  ///
  /// Useful for embedding content within other frames or custom layouts.
  void showContentTo(
      RenderOutput out, void Function(FrameContext ctx) content) {
    final frame = FramedLayout(title, theme: theme);
    final lb = LineBuilder(theme);
    final ctx = FrameContext._(out, lb, theme, frame);
    content(ctx);
  }
}

/// Extension to simplify FrameView usage with PromptRunner.
extension PromptRunnerFrameExtension on PromptRunner {
  /// Runs a prompt with FrameView-based rendering.
  ///
  /// Convenience method that combines PromptRunner with FrameView
  /// for the most common use case.
  ///
  /// Example:
  /// ```dart
  /// final runner = PromptRunner();
  /// final result = runner.runWithFrame(
  ///   frame: FrameView(title: 'My Prompt', theme: theme, bindings: bindings),
  ///   content: (ctx) {
  ///     ctx.gutterLine('Content here');
  ///   },
  ///   bindings: bindings,
  /// );
  /// ```
  PromptResult runWithFrame({
    required FrameView frame,
    required void Function(FrameContext ctx) content,
    required KeyBindings bindings,
  }) {
    return runWithBindings(
      render: (out) => frame.render(out, content),
      bindings: bindings,
    );
  }
}
