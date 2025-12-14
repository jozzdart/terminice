import 'package:terminice_core/terminice_core.dart';

// ════════════════════════════════════════════════════════════════════════════
// SYNTAX HIGHLIGHTING SUPPORT
// ════════════════════════════════════════════════════════════════════════════

/// SyntaxHighlighter – theme-aware syntax highlighting utilities.
///
/// Use for highlighting code snippets within framed content.
class SyntaxHighlighter {
  final PromptTheme theme;

  const SyntaxHighlighter(this.theme);

  /// Highlights a line of Dart code.
  String dartLine(String line) {
    var out = line;

    // Line comments
    final commentIdx = out.indexOf('//');
    String? commentPart;
    if (commentIdx >= 0) {
      commentPart = out.substring(commentIdx);
      out = out.substring(0, commentIdx);
    }

    // Strings
    out = out.replaceAllMapped(
      RegExp(r'"[^"]*"'),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );
    out = out.replaceAllMapped(
      RegExp(r"'[^']*'"),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );

    // Numbers
    out = out.replaceAllMapped(
      RegExp(r'\b\d+(?:\.\d+)?\b'),
      (m) => '${theme.selection}${m[0]}${theme.reset}',
    );

    // Keywords
    const keywords = [
      'class',
      'enum',
      'import',
      'as',
      'show',
      'hide',
      'void',
      'final',
      'const',
      'var',
      'return',
      'if',
      'else',
      'for',
      'while',
      'switch',
      'case',
      'break',
      'continue',
      'try',
      'catch',
      'on',
      'throw',
      'new',
      'this',
      'super',
      'extends',
      'with',
      'implements',
      'static',
      'get',
      'set',
      'async',
      'await',
      'yield',
      'true',
      'false',
      'null'
    ];
    final kwPattern = RegExp(r'\b(' + keywords.join('|') + r')\b');
    out = out.replaceAllMapped(
      kwPattern,
      (m) => '${theme.accent}${theme.bold}${m[0]}${theme.reset}',
    );

    // Punctuation
    out = out.replaceAllMapped(
      RegExp(r'[\[\]\{\}\(\)\,\;\:]'),
      (m) => '${theme.dim}${m[0]}${theme.reset}',
    );

    if (commentPart != null) {
      out = '$out ${theme.gray}$commentPart${theme.reset}';
    }
    return out;
  }

  /// Highlights a line of JSON.
  String jsonLine(String line) {
    var out = line;

    // Keys
    out = out.replaceAllMapped(
      RegExp(r'(\")([^\"]+)(\"\s*:)'),
      (m) => '${m[1]}${theme.accent}${theme.bold}${m[2]}${theme.reset}${m[3]}',
    );

    // String values
    out = out.replaceAllMapped(
      RegExp(r'(:\s*)(\"[^\"]*\")'),
      (m) => '${m[1]}${theme.highlight}${m[2]}${theme.reset}',
    );

    // Numbers, booleans, null
    out = out.replaceAllMapped(
      RegExp(r'(:\s*)(-?\d+(?:\.\d+)?|true|false|null)\b'),
      (m) => '${m[1]}${theme.selection}${m[2]}${theme.reset}',
    );

    // Punctuation
    out = out.replaceAllMapped(
      RegExp(r'[\[\]\{\}\,\:]'),
      (m) => '${theme.dim}${m[0]}${theme.reset}',
    );

    return out;
  }

  /// Highlights a line of shell/bash.
  String shellLine(String line) {
    var out = line;

    // Full-line comment
    if (out.trimLeft().startsWith('#')) {
      return '${theme.gray}$out${theme.reset}';
    }

    // Partial comment
    final hash = out.indexOf('#');
    String? commentPart;
    if (hash > 0) {
      commentPart = out.substring(hash);
      out = out.substring(0, hash);
    }

    // Flags
    out = out.replaceAllMapped(
      RegExp(r'(\s|^)(--?[A-Za-z0-9][A-Za-z0-9\-]*)'),
      (m) => '${m[1]}${theme.accent}${m[2]}${theme.reset}',
    );

    // Strings
    out = out.replaceAllMapped(
      RegExp(r'"[^"]*"'),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );
    out = out.replaceAllMapped(
      RegExp(r"'[^']*'"),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );

    // Paths
    out = out.replaceAllMapped(
      RegExp(r'(/[^\s]+)'),
      (m) => '${theme.selection}${m[1]}${theme.reset}',
    );

    if (commentPart != null) {
      out = '$out ${theme.gray}$commentPart${theme.reset}';
    }
    return out;
  }

  /// Auto-detects language and highlights.
  String autoLine(String line) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return jsonLine(line);
    }
    if (trimmed.startsWith('#')) return shellLine(line);
    if (trimmed.startsWith('import ') ||
        trimmed.contains(' void ') ||
        trimmed.contains(' class ') ||
        trimmed.contains(' final ') ||
        trimmed.contains(' const ')) {
      return dartLine(line);
    }
    return line;
  }
}
