import 'dart:math' as math;

import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Shared editor loop used by both the top-level config editor and nested
/// [GroupConfigurable] editors.
///
/// When [isRoot] is `true`, shows a "✓ Save & confirm" action and treats
/// Esc as a cancellation (returns `false`). When `false` (nested group),
/// shows "← Back" and both Esc and the back action return `true` — edits
/// are preserved in-place and only the root save decides confirmation.
///
/// Returns `true` if the user confirmed (or went back from a group),
/// `false` if cancelled.
bool runEditorLoop({
  required Terminice terminice,
  required String title,
  required List<Configurable> fields,
  required bool isRoot,
  int maxVisible = 18,
}) {
  if (fields.isEmpty) return true;

  var theme = terminice.defaultTheme;

  for (final f in fields) {
    if (f is ThemeConfigurable) {
      theme = f.selectedTheme;
      final previous = f.onChanged;
      f.onChanged = (newTheme) {
        theme = newTheme;
        previous?.call(newTheme);
      };
    }
  }

  final totalItems = fields.length + 1;
  final nav = ListNavigator(
    itemCount: totalItems,
    maxVisible: math.min(totalItems, maxVisible),
  );

  final searchBuffer = TextInputBuffer();
  var searchActive = true;
  var cancelled = false;
  var confirmed = false;

  var filteredIndices = List.generate(fields.length, (i) => i);

  void updateFilter() {
    if (!searchActive || searchBuffer.isEmpty) {
      filteredIndices = List.generate(fields.length, (i) => i);
    } else {
      final query = searchBuffer.text.toLowerCase();
      filteredIndices = <int>[];
      for (var i = 0; i < fields.length; i++) {
        final f = fields[i];
        if (f.label.toLowerCase().contains(query) ||
            f.key.toLowerCase().contains(query)) {
          filteredIndices.add(i);
        }
      }
    }
    nav.itemCount = filteredIndices.length + 1;
    nav.reset();
  }

  final bindings = KeyBindings.searchableList(
    onUp: () => nav.moveUp(),
    onDown: () => nav.moveDown(),
    onSearchToggle: () {
      searchActive = !searchActive;
      if (!searchActive) searchBuffer.clear();
      updateFilter();
    },
    searchBuffer: searchBuffer,
    isSearchEnabled: () => searchActive,
    onSearchInput: updateFilter,
    onCancel: () => cancelled = true,
  );

  int maxLabelLen() {
    var w = 0;
    for (final f in fields) {
      if (f.label.length > w) w = f.label.length;
    }
    return w.clamp(8, 40);
  }

  void render(RenderOutput out) {
    final rows = TerminalInfo.rows;
    final available = rows > 7 ? rows - 7 : 5;
    nav.maxVisible = available.clamp(1, math.min(totalItems, maxVisible));

    final frame = FrameView(title: title, theme: theme, bindings: bindings);
    frame.render(out, (ctx) {
      ctx.searchLine(
        searchBuffer.textWithCursor(),
        enabled: searchActive,
      );
      ctx.writeConnector();

      final itemCount = filteredIndices.length + 1;
      final window = nav.visibleWindow(
        List.generate(itemCount, (i) => i),
      );

      final labelWidth = maxLabelLen();

      ctx.listWindow(
        window,
        selectedIndex: nav.selectedIndex,
        renderItem: (int itemIdx, int absoluteIndex, bool isFocused) {
          if (itemIdx == 0) {
            renderEditorAction(ctx, isFocused, theme, isRoot: isRoot);
          } else {
            final fieldIdx = filteredIndices[itemIdx - 1];
            renderFieldItem(
              ctx,
              fields[fieldIdx],
              isFocused,
              theme,
              labelWidth,
              searchActive ? searchBuffer.text : null,
            );
          }
        },
      );

      if (filteredIndices.isEmpty) {
        ctx.emptyMessage('no matches');
      }
    });
  }

  Terminice themedInstance() => terminice.themed(theme);

  final session = TerminalSession(hideCursor: true, rawMode: true);
  final output = RenderOutput();

  session.start();
  render(output);

  try {
    while (!cancelled && !confirmed) {
      final event = KeyEventReader.read();
      final result = bindings.handle(event);

      switch (result) {
        case KeyActionResult.confirmed:
          final idx = nav.selectedIndex;
          if (idx == 0) {
            confirmed = true;
          } else if (idx - 1 < filteredIndices.length) {
            final fieldIdx = filteredIndices[idx - 1];

            output.clear();
            session.end();

            fields[fieldIdx].edit(themedInstance());

            session.start();
            render(output);
          }
          break;
        case KeyActionResult.cancelled:
          cancelled = true;
          break;
        case KeyActionResult.handled:
        case KeyActionResult.ignored:
          output.clear();
          render(output);
          break;
      }
    }
  } finally {
    session.end();
    output.clear();
  }

  // Non-root editors always preserve edits — Esc just means "go back"
  if (!isRoot) return true;
  return !cancelled;
}

/// Renders the action row (save or back) at the top of the field list.
void renderEditorAction(
  FrameContext ctx,
  bool isFocused,
  PromptTheme theme, {
  required bool isRoot,
}) {
  final arrow = ctx.lb.arrow(isFocused);
  final String icon;
  final String text;

  if (isRoot) {
    icon = '✓';
    text = 'Save & confirm';
  } else {
    icon = '←';
    text = 'Back';
  }

  final styledIcon = '${theme.accent}$icon${theme.reset}';
  final styledLabel = isFocused
      ? '${theme.bold}${theme.accent}$text${theme.reset}'
      : '${theme.accent}$text${theme.reset}';
  ctx.highlightedLine('$arrow $styledIcon $styledLabel',
      highlighted: isFocused);
}

/// Renders a single configurable field as a list row.
///
/// Groups and leaf fields are handled uniformly — visual distinction
/// comes from each field's [Configurable.typeIcon] and [Configurable.displayValue].
void renderFieldItem(
  FrameContext ctx,
  Configurable field,
  bool isFocused,
  PromptTheme theme,
  int labelWidth,
  String? searchQuery,
) {
  final arrow = ctx.lb.arrow(isFocused);
  final isGroup = field is GroupConfigurable;

  final icon = '${theme.accent}${field.typeIcon}${theme.reset}';

  var labelStr = field.label;
  if (labelStr.length > labelWidth) {
    labelStr = '${labelStr.substring(0, labelWidth - 1)}…';
  }
  final paddedLabel = labelStr.padRight(labelWidth);

  final String displayLabel;
  if (isGroup) {
    final base = '${theme.bold}$paddedLabel${theme.reset}';
    displayLabel = searchQuery != null && searchQuery.isNotEmpty
        ? highlightSubstring(base, searchQuery, theme)
        : base;
  } else {
    displayLabel = searchQuery != null && searchQuery.isNotEmpty
        ? highlightSubstring(paddedLabel, searchQuery, theme)
        : paddedLabel;
  }

  final valueStr = field.displayValue;
  final String valueDisplay;
  if (isGroup) {
    valueDisplay = '${theme.accent}$valueStr${theme.reset}';
  } else {
    valueDisplay = '${theme.dim}$valueStr${theme.reset}';
  }

  final modified = field.isModified ? ' ${theme.accent}*${theme.reset}' : '';
  final nav = isGroup ? ' ${theme.dim}→${theme.reset}' : '';

  ctx.highlightedLine(
    '$arrow $icon $displayLabel  $valueDisplay$modified$nav',
    highlighted: isFocused,
  );

  if (isFocused && field.description != null && field.description!.isNotEmpty) {
    final maxDescLen = math.max(20, TerminalInfo.columns - 10);
    var desc = field.description!;
    if (desc.length > maxDescLen) {
      desc = '${desc.substring(0, maxDescLen - 1)}…';
    }
    ctx.gutterLine(
      '    ${theme.dim}$desc${theme.reset}',
    );
  }
}
