import 'dart:io';

/// Extracts the final path segment (file or directory name).
String pathBasename(String path) {
  final parts = path.split(Platform.pathSeparator);
  return parts.isEmpty ? path : parts.last;
}

/// Truncates [path] to at most 60 visible characters with a leading ellipsis.
String shortPath(String path) {
  return path.length > 60 ? '...${path.substring(path.length - 57)}' : path;
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
