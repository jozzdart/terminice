import 'dart:io';
import 'package:terminice/terminice.dart';

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
    String label, {
    Directory? startDirectory,
    bool showHidden = false,
    bool foldersOnly = false,
  }) {
    List<FileSystemEntity> readEntries(Directory dir) {
      final all = dir.listSync(followLinks: false);
      all.sort((a, b) {
        final aDir = a is Directory;
        final bDir = b is Directory;
        if (aDir != bDir) return aDir ? -1 : 1;
        return _basename(a.path)
            .toLowerCase()
            .compareTo(_basename(b.path).toLowerCase());
      });
      return all
          .where((e) => showHidden || !_basename(e.path).startsWith('.'))
          .toList();
    }

    final startDir = startDirectory ?? Directory.current;
    Directory current = startDir;

    while (true) {
      // Read directory entries
      final entries = readEntries(current);
      final names = entries.map((e) {
        final isDir = e is Directory;
        final icon = isDir ? '▸' : '·';
        final name = _basename(e.path);
        return '$icon $name';
      }).toList();

      // Add a "go up" entry if not root
      if (current.parent.path != current.path) {
        names.insert(0, '↩ ..');
      }

      // Use shared search/select prompt
      final result = searchSelector(
        options: names,
        prompt: '$label (${_shortPath(current.path)})',
        showSearch: true,
        multiSelect: false,
        maxVisible: 15,
      );

      if (result.isEmpty) return null;

      final choice = result.first;

      // Handle ".." navigation
      if (choice.startsWith('↩')) {
        current = current.parent;
        continue;
      }

      // Map back to entity
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

String _basename(String path) {
  final parts = path.split(Platform.pathSeparator);
  return parts.isEmpty ? path : parts.last;
}

String _shortPath(String path) {
  return path.length > 60 ? '...${path.substring(path.length - 57)}' : path;
}
