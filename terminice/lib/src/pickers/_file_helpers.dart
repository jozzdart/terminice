import 'dart:io';

import 'package:terminice_core/terminice_core.dart';

import '../core/layout_text.dart';

/// Extracts the final path segment (file or directory name).
String pathBasename(String path) {
  final parts = path.split(Platform.pathSeparator);
  return parts.isEmpty ? path : parts.last;
}

/// Truncates [path] to at most 60 visible characters with a leading ellipsis.
String shortPath(String path) {
  final safePath = _safePath(path);
  final pathWidth = visibleLength(safePath);
  if (pathWidth <= 60) return safePath;

  const suffixWidth = 57;
  var prefixCells = pathWidth - suffixWidth;
  var prefix = clipWithoutEllipsis(safePath, prefixCells);
  var suffix = safePath.substring(prefix.length);

  // A requested cut can land inside a two-cell grapheme. Advance to the next
  // centralized grapheme boundary until the suffix fits its cell budget.
  while (visibleLength(suffix) > suffixWidth) {
    prefixCells++;
    prefix = clipWithoutEllipsis(safePath, prefixCells);
    suffix = safePath.substring(prefix.length);
  }
  return '...$suffix';
}

String _safePath(String path) {
  final hasControl = path.runes.any(
    (rune) => rune < 0x20 || (rune >= 0x7f && rune < 0xa0),
  );
  return hasControl ? terminalSafeLineText(path) : path;
}

/// Lists [dir] contents sorted directories-first, then case-insensitive name.
///
/// Hidden entries (names starting with `.`) are excluded unless [showHidden]
/// is `true`. Symbolic links are not followed.
List<FileSystemEntity> sortedEntries(Directory dir, {bool showHidden = false}) {
  final all = dir.listSync(followLinks: false);
  all.sort((a, b) {
    final aDir = a is Directory;
    final bDir = b is Directory;
    if (aDir != bDir) return aDir ? -1 : 1;
    return pathBasename(a.path)
        .toLowerCase()
        .compareTo(pathBasename(b.path).toLowerCase());
  });
  return all
      .where((e) => showHidden || !pathBasename(e.path).startsWith('.'))
      .toList();
}
