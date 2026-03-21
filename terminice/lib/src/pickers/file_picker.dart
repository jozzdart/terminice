import 'dart:io';
import 'package:terminice/terminice.dart';

import '_file_helpers.dart';

/// Adds the [filePicker] method to [Terminice] for interactive file and directory selection.
extension FilePickerExtensions on Terminice {
  /// Opens a keyboard-driven picker for choosing a file or directory.
  ///
  /// The prompt lists the contents of [startDirectory] (or the current working
  /// directory when omitted), sorts directories first, and lets users drill down
  /// or navigate up with the built-in `↩ ..` entry. Hidden entries stay filtered
  /// unless [showHidden] is enabled, and passing [foldersOnly] ensures only
  /// directories can be confirmed, which is useful for export targets.
  ///
  /// Returns the resolved path of the selected entity or `null` if the flow is
  /// cancelled.
  ///
  /// Example:
  /// ```dart
  /// final download = terminice.filePicker(
  ///   'Select download',
  ///   startDirectory: Directory('/tmp'),
  ///   showHidden: true,
  /// );
  /// if (download != null) {
  ///   print('Selected $download');
  /// }
  /// ```
  String? filePicker(
    String prompt, {
    Directory? startDirectory,
    bool showHidden = false,
    bool foldersOnly = false,
  }) {
    final startDir = startDirectory ?? Directory.current;
    Directory current = startDir;

    while (true) {
      final entries = sortedEntries(current, showHidden: showHidden);
      final names = entries.map((e) {
        final isDir = e is Directory;
        final icon = isDir ? '▸' : '·';
        final name = pathBasename(e.path);
        return '$icon $name';
      }).toList();

      if (current.parent.path != current.path) {
        names.insert(0, '↩ ..');
      }

      final result = searchSelector(
        prompt: '$prompt (${shortPath(current.path)})',
        options: names,
        showSearch: true,
        multiSelect: false,
        maxVisible: 15,
      );

      if (result.isEmpty) return null;

      final choice = result.first;

      if (choice.startsWith('↩')) {
        current = current.parent;
        continue;
      }

      final idx = names.indexOf(choice);
      final entity = (current.parent.path != current.path)
          ? entries[idx - 1]
          : entries[idx];

      if (entity is Directory) {
        current = entity;
        continue;
      } else if (!foldersOnly && entity is File) {
        return entity.path;
      }
    }
  }
}
