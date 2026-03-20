import 'package:test/test.dart';
import 'package:termistyle/termistyle.dart';

void main() {
  // Use marker-based theme to avoid ANSI-within-ANSI interference when
  // the punctuation pass runs over escape codes injected by earlier passes.
  const markers = TerminalColors(
    reset: '<R>',
    bold: '<B>',
    dim: '<D>',
    gray: '<G>',
    accent: '<A>',
    keyAccent: '<K>',
    highlight: '<H>',
    selection: '<S>',
    checkboxOn: '<ON>',
    checkboxOff: '<OFF>',
    inverse: '<I>',
    info: '<INFO>',
    warn: '<W>',
    error: '<E>',
  );
  const theme = PromptTheme(colors: markers);
  final hi = SyntaxHighlighter(theme);

  // ══════════════════════════════════════════════════════════════════════════
  // dartLine
  // ══════════════════════════════════════════════════════════════════════════

  group('dartLine', () {
    test('highlights double-quoted strings', () {
      final result = hi.dartLine('x = "hello"');
      expect(result, contains('<H>"hello"<R>'));
    });

    test('highlights single-quoted strings', () {
      final result = hi.dartLine("x = 'world'");
      expect(result, contains("<H>'world'<R>"));
    });

    test('highlights integer literals', () {
      final result = hi.dartLine('x = 42');
      expect(result, contains('<S>42<R>'));
    });

    test('highlights floating-point literals', () {
      final result = hi.dartLine('x = 3.14');
      expect(result, contains('<S>3.14<R>'));
    });

    test('highlights all recognized keywords', () {
      for (final kw in [
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
        'null',
      ]) {
        final result = hi.dartLine('$kw ');
        expect(result, contains('<A><B>$kw<R>'),
            reason: 'keyword "$kw" should be highlighted');
      }
    });

    test('does not highlight partial keyword matches', () {
      final result = hi.dartLine('classify');
      expect(result, isNot(contains('<A><B>class<R>')));
    });

    test('highlights punctuation with dim', () {
      final result = hi.dartLine('{}();,;:');
      expect(result, contains('<D>{<R>'));
      expect(result, contains('<D>}<R>'));
      expect(result, contains('<D>(<R>'));
      expect(result, contains('<D>)<R>'));
      expect(result, contains('<D>,<R>'));
      expect(result, contains('<D>;<R>'));
      expect(result, contains('<D>:<R>'));
    });

    test('highlights brackets', () {
      final result = hi.dartLine('list[0]');
      expect(result, contains('<D>[<R>'));
      expect(result, contains('<D>]<R>'));
    });

    test('extracts and highlights line comments in gray', () {
      final result = hi.dartLine('x = 1 // set x');
      expect(result, contains('<G>// set x<R>'));
    });

    test('full-line comment is rendered in gray', () {
      final result = hi.dartLine('// This is a comment');
      expect(result, contains('<G>// This is a comment<R>'));
    });

    test('code before comment is still highlighted', () {
      final result = hi.dartLine('final x = 42 // magic');
      expect(result, contains('<A><B>final<R>'));
      expect(result, contains('<S>42<R>'));
      expect(result, contains('<G>// magic<R>'));
    });

    test('returns empty string unchanged', () {
      expect(hi.dartLine(''), equals(''));
    });

    test('handles import statement', () {
      final result = hi.dartLine("<A><B>import<R> 'pkg'");
      expect(result, contains('<A><B>import<R>'));
    });

    test('import keyword is highlighted for real import line', () {
      final result = hi.dartLine("import 'package:foo/foo.dart'");
      expect(result, contains('<A><B>import<R>'));
    });

    test('handles line with only whitespace', () {
      expect(hi.dartLine('   '), equals('   '));
    });

    test('handles multiple keywords on one line', () {
      final result = hi.dartLine('if true return null');
      expect(result, contains('<A><B>if<R>'));
      expect(result, contains('<A><B>true<R>'));
      expect(result, contains('<A><B>return<R>'));
      expect(result, contains('<A><B>null<R>'));
    });

    test('handles multiple strings on one line', () {
      final result = hi.dartLine('a = "x" b = "y"');
      expect(result, contains('<H>"x"<R>'));
      expect(result, contains('<H>"y"<R>'));
    });

    test('handles number zero', () {
      final result = hi.dartLine('x = 0');
      expect(result, contains('<S>0<R>'));
    });

    test('numbers inside strings are still matched by number pass', () {
      final result = hi.dartLine('x = "42"');
      expect(result, contains('<S>42<R>'));
    });

    test('handles empty double-quoted string', () {
      final result = hi.dartLine('x = ""');
      expect(result, contains('<H>""<R>'));
    });

    test('handles empty single-quoted string', () {
      final result = hi.dartLine("x = ''");
      expect(result, contains("<H>''<R>"));
    });

    test('handles line with only a comment marker', () {
      final result = hi.dartLine('//');
      expect(result, contains('<G>//<R>'));
    });

    test('comment is separated from code with an extra space', () {
      final result = hi.dartLine('x // note');
      expect(result, equals('x  <G>// note<R>'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // jsonLine
  // ══════════════════════════════════════════════════════════════════════════

  group('jsonLine', () {
    test('highlights keys with accent+bold', () {
      final result = hi.jsonLine('"name": "Alice"');
      expect(result, contains('<A><B>name<R>'));
    });

    test('highlights string values with highlight color', () {
      final result = hi.jsonLine('"name": "Alice"');
      expect(result, contains('<H>"Alice"<R>'));
    });

    test('highlights numeric values with selection color', () {
      final result = hi.jsonLine('"age": 30');
      expect(result, contains('<S>30<R>'));
    });

    test('highlights negative numbers', () {
      final result = hi.jsonLine('"offset": -5');
      expect(result, contains('<S>-5<R>'));
    });

    test('highlights float values', () {
      final result = hi.jsonLine('"pi": 3.14');
      expect(result, contains('<S>3.14<R>'));
    });

    test('highlights boolean true', () {
      final result = hi.jsonLine('"enabled": true');
      expect(result, contains('<S>true<R>'));
    });

    test('highlights boolean false', () {
      final result = hi.jsonLine('"enabled": false');
      expect(result, contains('<S>false<R>'));
    });

    test('highlights null value', () {
      final result = hi.jsonLine('"data": null');
      expect(result, contains('<S>null<R>'));
    });

    test('highlights braces with dim', () {
      final result = hi.jsonLine('{}');
      expect(result, contains('<D>{<R>'));
      expect(result, contains('<D>}<R>'));
    });

    test('highlights brackets with dim', () {
      final result = hi.jsonLine('[]');
      expect(result, contains('<D>[<R>'));
      expect(result, contains('<D>]<R>'));
    });

    test('highlights commas with dim', () {
      final result = hi.jsonLine('1, 2');
      expect(result, contains('<D>,<R>'));
    });

    test('highlights colons with dim', () {
      final result = hi.jsonLine('"k": 1');
      expect(result, contains('<D>:<R>'));
    });

    test('handles opening brace line', () {
      final result = hi.jsonLine('{');
      expect(result, equals('<D>{<R>'));
    });

    test('handles closing brace line', () {
      final result = hi.jsonLine('}');
      expect(result, equals('<D>}<R>'));
    });

    test('handles empty string', () {
      expect(hi.jsonLine(''), equals(''));
    });

    test('handles key with empty string value', () {
      final result = hi.jsonLine('"name": ""');
      expect(result, contains('<A><B>name<R>'));
      expect(result, contains('<H>""<R>'));
    });

    test('handles multiple key-value pairs', () {
      final result = hi.jsonLine('"a": 1, "b": 2');
      expect(result, contains('<A><B>a<R>'));
      expect(result, contains('<A><B>b<R>'));
    });

    test('handles negative float value', () {
      final result = hi.jsonLine('"v": -3.14');
      expect(result, contains('<S>-3.14<R>'));
    });

    test('handles zero value', () {
      final result = hi.jsonLine('"v": 0');
      expect(result, contains('<S>0<R>'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // shellLine
  // ══════════════════════════════════════════════════════════════════════════

  group('shellLine', () {
    test('renders full-line comment entirely in gray', () {
      final result = hi.shellLine('# This is a comment');
      expect(result, equals('<G># This is a comment<R>'));
    });

    test('renders indented full-line comment in gray', () {
      final result = hi.shellLine('  # indented comment');
      expect(result, equals('<G>  # indented comment<R>'));
    });

    test('highlights single-dash flags', () {
      final result = hi.shellLine('ls -la');
      expect(result, contains('<A>-la<R>'));
    });

    test('highlights double-dash flags', () {
      final result = hi.shellLine('npm install --save-dev');
      expect(result, contains('<A>--save-dev<R>'));
    });

    test('highlights double-quoted strings', () {
      final result = hi.shellLine('echo "hello world"');
      expect(result, contains('<H>"hello world"<R>'));
    });

    test('highlights single-quoted strings', () {
      final result = hi.shellLine("echo 'hello'");
      expect(result, contains("<H>'hello'<R>"));
    });

    test('highlights file paths', () {
      final result = hi.shellLine('cat /etc/hosts');
      expect(result, contains('<S>/etc/hosts<R>'));
    });

    test('highlights paths with nested directories', () {
      final result = hi.shellLine('ls /usr/local/bin');
      expect(result, contains('<S>/usr/local/bin<R>'));
    });

    test('extracts partial comment after code', () {
      final result = hi.shellLine('ls -la # list all');
      expect(result, contains('<G># list all<R>'));
    });

    test('code before partial comment is still highlighted', () {
      final result = hi.shellLine('ls -la # list all');
      expect(result, contains('<A>-la<R>'));
      expect(result, contains('<G># list all<R>'));
    });

    test('handles empty string', () {
      expect(hi.shellLine(''), equals(''));
    });

    test('handles command with multiple flags', () {
      final result = hi.shellLine('grep -r -i -n pattern');
      expect(result, contains('<A>-r<R>'));
      expect(result, contains('<A>-i<R>'));
      expect(result, contains('<A>-n<R>'));
    });

    test('handles multiple double-quoted strings', () {
      final result = hi.shellLine('echo "a" "b"');
      expect(result, contains('<H>"a"<R>'));
      expect(result, contains('<H>"b"<R>'));
    });

    test('handles multiple single-quoted strings', () {
      final result = hi.shellLine("echo 'a' 'b'");
      expect(result, contains("<H>'a'<R>"));
      expect(result, contains("<H>'b'<R>"));
    });

    test('handles hash at position 0 as comment', () {
      final result = hi.shellLine('#!');
      expect(result, equals('<G>#!<R>'));
    });

    test('handles shebang line', () {
      final result = hi.shellLine('#!/usr/bin/env bash');
      expect(result, equals('<G>#!/usr/bin/env bash<R>'));
    });

    test('handles path-only line', () {
      final result = hi.shellLine('/usr/bin/env');
      expect(result, contains('<S>/usr/bin/env<R>'));
    });

    test('handles flag with equals sign', () {
      final result = hi.shellLine('git log --format=oneline');
      expect(result, contains('<A>--format<R>'));
    });

    test('plain command with no special tokens', () {
      final result = hi.shellLine('echo hello');
      expect(result, equals('echo hello'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // autoLine
  // ══════════════════════════════════════════════════════════════════════════

  group('autoLine', () {
    test('detects JSON when line starts with {', () {
      final line = '{"key": "value"}';
      expect(hi.autoLine(line), equals(hi.jsonLine(line)));
    });

    test('detects JSON when line starts with [', () {
      final line = '[1, 2, 3]';
      expect(hi.autoLine(line), equals(hi.jsonLine(line)));
    });

    test('detects JSON with leading whitespace', () {
      final line = '  {"key": 1}';
      expect(hi.autoLine(line), equals(hi.jsonLine(line)));
    });

    test('detects shell when line starts with #', () {
      final line = '# comment';
      expect(hi.autoLine(line), equals(hi.shellLine(line)));
    });

    test('detects shell with leading whitespace', () {
      final line = '  # comment';
      expect(hi.autoLine(line), equals(hi.shellLine(line)));
    });

    test('detects Dart via import keyword', () {
      final line = "import 'package:foo/foo.dart'";
      expect(hi.autoLine(line), equals(hi.dartLine(line)));
    });

    test('detects Dart via void keyword (not first word)', () {
      final line = 'static void main() {';
      expect(hi.autoLine(line), equals(hi.dartLine(line)));
    });

    test('detects Dart via class keyword (not first word)', () {
      final line = 'abstract class Foo {';
      expect(hi.autoLine(line), equals(hi.dartLine(line)));
    });

    test('detects Dart via final keyword (not first word)', () {
      final line = 'static final x = 1';
      expect(hi.autoLine(line), equals(hi.dartLine(line)));
    });

    test('detects Dart via const keyword (not first word)', () {
      final line = 'static const pi = 3.14';
      expect(hi.autoLine(line), equals(hi.dartLine(line)));
    });

    test('does not detect Dart when keyword is first word after trim', () {
      final line = '  void main';
      expect(hi.autoLine(line), equals(line));
    });

    test('returns unrecognized line unchanged', () {
      const line = 'just some plain text';
      expect(hi.autoLine(line), equals(line));
    });

    test('returns empty string unchanged', () {
      expect(hi.autoLine(''), equals(''));
    });

    test('returns whitespace-only line unchanged', () {
      expect(hi.autoLine('   '), equals('   '));
    });

    test('does not false-positive on words containing keywords', () {
      const line = 'finalize the constant importer';
      expect(hi.autoLine(line), equals(line));
    });

    test('JSON detection takes priority over Dart for {', () {
      final line = '{"class": "Foo"}';
      expect(hi.autoLine(line), equals(hi.jsonLine(line)));
    });

    test('shell detection takes priority over Dart for #', () {
      final line = '# final const import';
      expect(hi.autoLine(line), equals(hi.shellLine(line)));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Theme independence
  // ══════════════════════════════════════════════════════════════════════════

  group('theme independence', () {
    test('different marker themes produce different output for same input', () {
      const themeA = PromptTheme(
        colors: TerminalColors(
            accent: '«A1»',
            bold: '«B1»',
            reset: '«R1»',
            selection: '«S1»',
            dim: '«D1»',
            gray: '«G1»',
            highlight: '«H1»'),
      );
      const themeB = PromptTheme(
        colors: TerminalColors(
            accent: '«A2»',
            bold: '«B2»',
            reset: '«R2»',
            selection: '«S2»',
            dim: '«D2»',
            gray: '«G2»',
            highlight: '«H2»'),
      );
      final hiA = SyntaxHighlighter(themeA);
      final hiB = SyntaxHighlighter(themeB);

      final resultA = hiA.dartLine('final x = 42');
      final resultB = hiB.dartLine('final x = 42');

      expect(resultA, contains('«A1»«B1»final«R1»'));
      expect(resultB, contains('«A2»«B2»final«R2»'));
      expect(resultA, isNot(equals(resultB)));
    });

    test('works with fully custom marker-based theme', () {
      final result = hi.dartLine('final x = 42 // note');
      expect(result, contains('<A><B>final<R>'));
      expect(result, contains('<S>42<R>'));
      expect(result, contains('<G>// note<R>'));
    });

    test('custom theme JSON highlighting uses correct markers', () {
      final result = hi.jsonLine('"key": "val"');
      expect(result, contains('<A><B>key<R>'));
      expect(result, contains('<H>"val"<R>'));
    });

    test('custom theme shell highlighting uses correct markers', () {
      final result = hi.shellLine('curl --silent /api/data');
      expect(result, contains('<A>--silent<R>'));
      expect(result, contains('<S>/api/data<R>'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Edge cases
  // ══════════════════════════════════════════════════════════════════════════

  group('edge cases', () {
    test('dartLine handles adjacent strings', () {
      final result = hi.dartLine('"a""b"');
      expect(result, contains('<H>"a"<R>'));
      expect(result, contains('<H>"b"<R>'));
    });

    test('dartLine handles string with spaces', () {
      final result = hi.dartLine('"hello world"');
      expect(result, contains('<H>"hello world"<R>'));
    });

    test('jsonLine handles deeply nested close braces', () {
      final result = hi.jsonLine('}}}');
      expect(result, contains('<D>}<R>'));
    });

    test('jsonLine handles array brackets', () {
      final result = hi.jsonLine('[]');
      expect(result, contains('<D>[<R>'));
      expect(result, contains('<D>]<R>'));
    });

    test('shellLine with only a path', () {
      final result = hi.shellLine('/usr/bin/env');
      expect(result, contains('<S>/usr/bin/env<R>'));
    });

    test('dartLine with number at start of expression', () {
      final result = hi.dartLine('  42');
      expect(result, contains('<S>42<R>'));
    });

    test('dartLine does not fail on very long lines', () {
      final longLine = 'x = ${'"a" ' * 500}"z"';
      expect(() => hi.dartLine(longLine), returnsNormally);
    });

    test('jsonLine does not fail on very long lines', () {
      final longJson = '{"k": "${'v' * 5000}"}';
      expect(() => hi.jsonLine(longJson), returnsNormally);
    });

    test('shellLine does not fail on very long lines', () {
      final longShell = 'echo ${'--flag ' * 500}';
      expect(() => hi.shellLine(longShell), returnsNormally);
    });

    test('dartLine handles line with no highlightable content', () {
      expect(hi.dartLine('xyz'), equals('xyz'));
    });

    test('jsonLine handles line with no highlightable content', () {
      expect(hi.jsonLine('xyz'), equals('xyz'));
    });

    test('shellLine handles line with no special tokens', () {
      expect(hi.shellLine('hello world'), equals('hello world'));
    });

    test('dartLine handles tab characters', () {
      final result = hi.dartLine('\tfinal x = 1');
      expect(result, contains('<A><B>final<R>'));
    });

    test('dartLine handles mixed single and double quotes', () {
      final result = hi.dartLine("x = \"a\" + 'b'");
      expect(result, contains('<H>"a"<R>'));
      expect(result, contains("<H>'b'<R>"));
    });

    test('jsonLine handles key with special characters in value', () {
      final result = hi.jsonLine('"msg": "hello world!"');
      expect(result, contains('<H>"hello world!"<R>'));
    });

    test('shellLine handles multiple paths', () {
      final result = hi.shellLine('cp /src/file /dst/file');
      expect(result, contains('<S>/src/file<R>'));
      expect(result, contains('<S>/dst/file<R>'));
    });
  });
}
