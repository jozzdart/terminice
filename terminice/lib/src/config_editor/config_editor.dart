import 'dart:math' as math;

import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Config editor that presents a themed, searchable list of configurable fields
/// and lets the user edit each one using the appropriate prompt.
///
/// Runs as a single terminal session that temporarily yields to sub-editors
/// (text, slider, confirm, etc.) when a field is selected, then resumes.
/// This avoids rendering artifacts from multiple prompt sessions.
///
/// If any field is a [ThemeConfigurable], changing it updates the editor's
/// own theme in real time -- the frame, icons, and hints re-render immediately
/// with the newly selected palette.
///
/// Controls:
/// - ↑ / ↓ navigate through fields
/// - / toggles search filter
/// - Enter opens the editor for the focused field
/// - Select "✓ Save & confirm" to return the result
/// - Esc / Ctrl+C cancels (returns `null`)
///
/// ```dart
/// final result = terminice.configEditor(
///   title: 'App Settings',
///   fields: [
///     ThemeConfigurable(key: 'theme', label: 'Theme', value: 'dark'),
///     BoolConfigurable(key: 'darkMode', label: 'Dark Mode', value: true),
///     StringConfigurable(key: 'name', label: 'App Name', value: 'My App'),
///   ],
/// );
/// ```
extension ConfigEditorExtensions on Terminice {
  /// Opens a config editor for the given [fields].
  ///
  /// Returns a [ConfigResult] on confirmation, or `null` if cancelled.
  ConfigResult? configEditor({
    required String title,
    required List<Configurable> fields,
    int maxVisible = 18,
  }) {
    if (fields.isEmpty) {
      return ConfigResult(fields: fields, confirmed: true);
    }

    // Mutable theme -- ThemeConfigurable can swap it live
    var theme = defaultTheme;

    // Auto-wire ThemeConfigurable instances for live switching
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

    // +1 for the save action at index 0
    final totalItems = fields.length + 1;
    final nav = ListNavigator(
      itemCount: totalItems,
      maxVisible: math.min(totalItems, maxVisible),
    );

    final searchBuffer = TextInputBuffer();
    bool searchActive = true;
    bool cancelled = false;
    bool confirmed = false;

    List<int> filteredIndices = List.generate(fields.length, (i) => i);

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
              _renderSaveAction(ctx, isFocused, theme);
            } else {
              final fieldIdx = filteredIndices[itemIdx - 1];
              _renderField(
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

    // Build a themed Terminice instance that reads from the mutable theme.
    // Sub-editors launched from here will use whatever theme is current.
    Terminice themedInstance() => themed(theme);

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

    if (cancelled) return null;
    return ConfigResult(fields: fields, confirmed: true);
  }
}

void _renderSaveAction(FrameContext ctx, bool isFocused, PromptTheme theme) {
  final arrow = ctx.lb.arrow(isFocused);
  final icon = '${theme.accent}✓${theme.reset}';
  final label = isFocused
      ? '${theme.bold}${theme.accent}Save & confirm${theme.reset}'
      : '${theme.accent}Save & confirm${theme.reset}';
  ctx.highlightedLine('$arrow $icon $label', highlighted: isFocused);
}

void _renderField(
  FrameContext ctx,
  Configurable field,
  bool isFocused,
  PromptTheme theme,
  int labelWidth,
  String? searchQuery,
) {
  final arrow = ctx.lb.arrow(isFocused);

  final icon = '${theme.accent}${field.typeIcon}${theme.reset}';

  var labelStr = field.label;
  if (labelStr.length > labelWidth) {
    labelStr = '${labelStr.substring(0, labelWidth - 1)}…';
  }
  final paddedLabel = labelStr.padRight(labelWidth);
  final displayLabel = searchQuery != null && searchQuery.isNotEmpty
      ? highlightSubstring(paddedLabel, searchQuery, theme)
      : paddedLabel;

  final valueStr = field.displayValue;
  final valueDisplay = '${theme.dim}$valueStr${theme.reset}';

  final modified = field.isModified ? ' ${theme.accent}*${theme.reset}' : '';

  ctx.highlightedLine(
    '$arrow $icon $displayLabel  $valueDisplay$modified',
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
