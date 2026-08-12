import 'dart:math' as math;

import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Shared editor loop used by both the top-level config editor and nested
/// [GroupConfigurable] editors.
///
/// When [isRoot] is `true`, shows a "✓ Save & confirm" action and treats
/// Esc as a cancellation (returns `false`). When `false` (nested group),
/// shows "← Back" and both Esc and the back action return `true` - edits
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
  return terminice.runWithExecutionMode<bool>(
    rich: () => runRichEditorLoop(
      terminice: terminice,
      title: title,
      fields: fields,
      isRoot: isRoot,
      maxVisible: maxVisible,
    ),
    line: () => runLineEditorLoop(
      terminice: terminice,
      title: title,
      fields: fields,
      isRoot: isRoot,
    ),
    unattended: () => false,
  );
}

/// Runs the existing full-screen editor without changing its rich behavior.
bool runRichEditorLoop({
  required Terminice terminice,
  required String title,
  required List<Configurable> fields,
  required bool isRoot,
  int maxVisible = 18,
}) {
  if (fields.isEmpty) return true;

  var activeTerminice = terminice;
  PromptTheme currentTheme() => activeTerminice.defaultTheme;

  for (final f in fields) {
    if (f is ThemeConfigurable) {
      activeTerminice = terminice.themed(f.selectedTheme);
      final previous = f.onChanged;
      f.onChanged = (newTheme) {
        activeTerminice = terminice.themed(newTheme);
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

    final theme = currentTheme();
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

            fields[fieldIdx].edit(activeTerminice);

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

  // Non-root editors always preserve edits - Esc just means "go back"
  if (!isRoot) return true;
  return !cancelled;
}

/// Runs a numbered, line-oriented editor that never changes terminal modes.
bool runLineEditorLoop({
  required Terminice terminice,
  required String title,
  required List<Configurable> fields,
  required bool isRoot,
}) {
  if (fields.isEmpty) return true;

  final output = TerminalContext.output;
  final input = TerminalContext.input;

  while (true) {
    output.writeln(terminalSafeLineText(title));
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      final value = field is PasswordConfigurable
          ? field.formatValue()
          : field.displayValue;
      output.writeln(
        '${i + 1}. ${terminalSafeLineText(field.label)}: '
        '${terminalSafeLineText(value)}',
      );
    }

    if (isRoot) {
      output.write('Select field, [r]eview, [s]ave, or [c]ancel: ');
    } else {
      output.write('Select field, [r]eview, or [b]ack: ');
    }

    final line = input.readLineSync();
    if (line == null) return !isRoot;
    final command = line.trim().toLowerCase();

    if (command == 'r' || command == 'review') {
      output.writeln('Current values:');
      continue;
    }
    if (!isRoot && (command == 'b' || command == 'back')) return true;
    if (isRoot && (command == 'c' || command == 'cancel')) return false;
    if (isRoot && (command == 's' || command == 'save')) {
      final validationError = _firstValidationError(fields);
      if (validationError == null) return true;
      output.writeln('Cannot save: ${terminalSafeLineText(validationError)}');
      continue;
    }

    final selected = int.tryParse(command);
    if (selected == null || selected < 1 || selected > fields.length) {
      final range = fields.length == 1 ? '1' : '1-${fields.length}';
      output.writeln('Enter a field number ($range) or a listed command.');
      continue;
    }

    final activeTerminice = _terminiceForFields(terminice, fields);
    fields[selected - 1].edit(activeTerminice);
  }
}

/// Returns the first validation error in editor order, or `null` when valid.
String? firstEditorValidationError(List<Configurable> fields) =>
    _firstValidationError(fields);

String? _firstValidationError(List<Configurable> fields) {
  for (final field in fields) {
    final error = field.validate();
    if (error != null) return '${field.label}: $error';
  }
  return null;
}

Terminice _terminiceForFields(
  Terminice terminice,
  List<Configurable> fields,
) {
  for (final field in fields) {
    if (field is ThemeConfigurable) {
      return terminice.themed(field.selectedTheme);
    }
  }
  return terminice;
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
/// Groups and leaf fields are handled uniformly - visual distinction
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
