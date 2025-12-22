import 'dart:io';

import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

extension PathPickerExtensions on Terminice {
  /// Launches the dynamic path picker for selecting directories (and optional files).
  ///
  /// This picker renders a live-updating list of the current directory using
  /// `DynamicListPrompt`, pinning the active path in the header and keeping
  /// directories ordered above files. Pass [startDirectory] to control the entry
  /// point, [showHidden] to surface dot folders, [allowFiles] when you want to
  /// confirm files in addition to directories, and tune [maxVisible] to fit the
  /// terminal height.
  ///
  /// Returns the absolute path chosen by the user, or `null` if the prompt is
  /// dismissed.
  ///
  /// Example:
  /// ```dart
  /// final projectRoot = terminice.pathPicker(
  ///   'Select project root',
  ///   startDirectory: Directory.current,
  ///   allowFiles: false,
  /// );
  /// if (projectRoot != null) {
  ///   print('Working in $projectRoot');
  /// }
  /// ```
  String? pathPicker(
    String label, {
    Directory? startDirectory,
    bool showHidden = false,
    bool allowFiles = false,
    int maxVisible = 18,
  }) {
    final theme = defaultTheme;
    Directory current = startDirectory ?? Directory.current;
    String? selectedPath;

    final prompt = DynamicListPrompt<_Entry>(
      title: label,
      theme: theme,
      maxVisible: maxVisible,
    );

    final result = prompt.run(
      buildItems: () => _readEntries(current, showHidden, allowFiles),
      onPrimary: (entry, index) {
        switch (entry.type) {
          case _EntryType.up:
            current = Directory(entry.path);
            return DynamicAction.rebuildAndReset;
          case _EntryType.confirmDir:
            selectedPath = current.path;
            return DynamicAction.confirm;
          case _EntryType.directory:
            current = Directory(entry.path);
            return DynamicAction.rebuildAndReset;
          case _EntryType.file:
            if (allowFiles) {
              selectedPath = entry.path;
              return DynamicAction.confirm;
            }
            return DynamicAction.none;
        }
      },
      onSecondary: (entry, index) {
        // Go to parent
        if (current.parent.path != current.path) {
          current = current.parent;
          return DynamicAction.rebuildAndReset;
        }
        return DynamicAction.none;
      },
      beforeItems: (ctx) {
        final shortPath = current.path.length > 60
            ? '...${current.path.substring(current.path.length - 57)}'
            : current.path;
        ctx.headerLine('Path', shortPath);
        ctx.writeConnector();
      },
      renderItem: (ctx, entry, index, isFocused) {
        final arrow = ctx.lb.arrow(isFocused);
        ctx.highlightedLine('$arrow ${entry.label}', highlighted: isFocused);
      },
    );

    if (result == null) return null;
    return selectedPath;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// INTERNAL HELPERS
// ════════════════════════════════════════════════════════════════════════════

class _Entry {
  final String label;
  final String path;
  final _EntryType type;

  _Entry(this.label, this.path, this.type);
}

enum _EntryType { up, confirmDir, directory, file }

List<_Entry> _readEntries(Directory dir, bool showHidden, bool allowFiles) {
  final List<_Entry> list = [];

  // Parent navigation
  final hasParent = dir.parent.path != dir.path;
  if (hasParent) {
    list.add(_Entry('↩ ..', dir.parent.path, _EntryType.up));
  }

  // Select current directory
  list.add(_Entry('✓ Select this directory', dir.path, _EntryType.confirmDir));

  // List directory contents
  try {
    final raw = dir.listSync(followLinks: false);
    raw.sort((a, b) {
      final aDir = a is Directory;
      final bDir = b is Directory;
      if (aDir != bDir) return aDir ? -1 : 1;
      return _basename(a.path)
          .toLowerCase()
          .compareTo(_basename(b.path).toLowerCase());
    });

    final filtered = raw
        .where((e) => showHidden || !_basename(e.path).startsWith('.'))
        .toList();

    for (final e in filtered) {
      if (e is Directory) {
        list.add(
            _Entry('▸ ${_basename(e.path)}', e.path, _EntryType.directory));
      } else if (allowFiles && e is File) {
        list.add(_Entry('· ${_basename(e.path)}', e.path, _EntryType.file));
      }
    }
  } catch (_) {
    // Handle permission errors silently
  }

  return list;
}

String _basename(String path) {
  final parts = path.split(Platform.pathSeparator);
  return parts.isEmpty ? path : parts.last;
}
