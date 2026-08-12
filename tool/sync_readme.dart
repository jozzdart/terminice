import 'dart:io';

/// Copies the Terminice package README to the repository root and adjusts
/// package-relative links so they still resolve from the new location.
void main() {
  final script = File.fromUri(Platform.script);
  final repository = script.parent.parent;
  final package = Directory.fromUri(repository.uri.resolve('terminice/'));
  final source = File.fromUri(package.uri.resolve('README.md'));
  final destination = File.fromUri(repository.uri.resolve('README.md'));

  if (!source.existsSync()) {
    stderr.writeln('Could not find ${source.path}.');
    exitCode = 1;
    return;
  }

  var rewrittenPaths = 0;
  var inCodeFence = false;
  final output = source.readAsLinesSync().map((line) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      inCodeFence = !inCodeFence;
      return line;
    }
    if (inCodeFence) return line;

    return _rewriteReadmeLine(line, package, () => rewrittenPaths++);
  }).join('\n');

  final sourceEndsWithNewline = source.readAsStringSync().endsWith('\n');
  destination.writeAsStringSync('$output${sourceEndsWithNewline ? '\n' : ''}');
  stdout.writeln(
    'Synced terminice/README.md to README.md and adjusted '
    '$rewrittenPaths local paths.',
  );
}

String _rewriteReadmeLine(
  String line,
  Directory package,
  void Function() onRewrite,
) {
  var result = line.replaceAllMapped(
    RegExp(r'(!?\[[^\]]*\]\()([^)]*)(\))'),
    (match) {
      final destination = match.group(2)!;
      final rewritten = _rewriteMarkdownDestination(destination, package);
      if (rewritten != destination) onRewrite();
      return '${match.group(1)}$rewritten${match.group(3)}';
    },
  );

  result = result.replaceAllMapped(
    RegExp(r'''(\b(?:src|href)\s*=\s*["'])([^"']+)(["'])''',
        caseSensitive: false),
    (match) {
      final destination = match.group(2)!;
      final rewritten = _rewriteLocalPath(destination, package);
      if (rewritten != destination) onRewrite();
      return '${match.group(1)}$rewritten${match.group(3)}';
    },
  );

  return result;
}

String _rewriteMarkdownDestination(String destination, Directory package) {
  if (destination.startsWith('<')) {
    final closingBracket = destination.indexOf('>');
    if (closingBracket == -1) return destination;
    final path = destination.substring(1, closingBracket);
    final rewritten = _rewriteLocalPath(path, package);
    return '<$rewritten>${destination.substring(closingBracket + 1)}';
  }

  final whitespace = RegExp(r'\s').firstMatch(destination)?.start;
  if (whitespace == null) return _rewriteLocalPath(destination, package);

  final path = destination.substring(0, whitespace);
  return '${_rewriteLocalPath(path, package)}${destination.substring(whitespace)}';
}

String _rewriteLocalPath(String destination, Directory package) {
  if (destination.isEmpty ||
      destination.startsWith('#') ||
      destination.startsWith('/') ||
      destination.startsWith('//')) {
    return destination;
  }

  final uri = Uri.tryParse(destination);
  if (uri == null || uri.hasScheme) return destination;

  final path = uri.path;
  if (path.isEmpty || path.startsWith('../')) return destination;

  final entity = package.uri.resolve(path).toFilePath();
  if (FileSystemEntity.typeSync(entity) == FileSystemEntityType.notFound) {
    return destination;
  }

  return 'terminice/$destination';
}
