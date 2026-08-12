import 'dart:io';

import 'package:terminice_core/terminice_core.dart';

/// Reads and validates an existing file-system path in line mode.
String? fallbackExistingPath({
  required String prompt,
  Directory? startDirectory,
  required bool allowFiles,
  required bool allowDirectories,
  required bool blankSelectsBase,
}) {
  final base = (startDirectory ?? Directory.current).absolute;
  while (true) {
    final typed = FallbackPrompt.text(
      title: '$prompt (path)',
      required: false,
      returnDefaultOnEndOfInput: false,
    );
    if (typed == null) return null;
    if (typed.isEmpty) {
      if (blankSelectsBase && allowDirectories && base.existsSync()) {
        return base.path;
      }
      TerminalContext.output.writeln('Enter an existing path.');
      continue;
    }

    final resolved = File(typed).isAbsolute
        ? File(typed).absolute.path
        : base.uri.resolve(typed).toFilePath();
    final type = FileSystemEntity.typeSync(resolved, followLinks: true);
    if (type == FileSystemEntityType.file && allowFiles) {
      return File(resolved).absolute.path;
    }
    if (type == FileSystemEntityType.directory && allowDirectories) {
      return Directory(resolved).absolute.path;
    }
    TerminalContext.output.writeln(
      type == FileSystemEntityType.notFound
          ? 'Path does not exist.'
          : 'That path type is not allowed.',
    );
  }
}
