import 'package:test/test.dart';
import 'package:termistyle/termistyle.dart';

void main() {
  const theme = PromptTheme();
  final hi = theme.highlight; // '\x1B[33m'
  final rs = theme.reset; // '\x1B[0m'

  // ══════════════════════════════════════════════════════════════════════════
  // Basic matching
  // ══════════════════════════════════════════════════════════════════════════

  group('basic matching', () {
    test('highlights a substring at the start', () {
      expect(
        highlightSubstring('Hello World', 'Hello', theme),
        equals('${hi}Hello$rs World'),
      );
    });

    test('highlights a substring at the end', () {
      expect(
        highlightSubstring('Hello World', 'World', theme),
        equals('Hello ${hi}World$rs'),
      );
    });

    test('highlights a substring in the middle', () {
      expect(
        highlightSubstring('Hello World', 'lo Wo', theme),
        equals('Hel${hi}lo Wo${rs}rld'),
      );
    });

    test('highlights when query matches entire text', () {
      expect(
        highlightSubstring('Hello', 'Hello', theme),
        equals('${hi}Hello$rs'),
      );
    });

    test('highlights single character match', () {
      expect(
        highlightSubstring('abcdef', 'c', theme),
        equals('ab${hi}c${rs}def'),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Case insensitivity
  // ══════════════════════════════════════════════════════════════════════════

  group('case insensitivity', () {
    test('matches lowercase query against uppercase text', () {
      expect(
        highlightSubstring('HELLO', 'hello', theme),
        equals('${hi}HELLO$rs'),
      );
    });

    test('matches uppercase query against lowercase text', () {
      expect(
        highlightSubstring('hello', 'HELLO', theme),
        equals('${hi}hello$rs'),
      );
    });

    test('matches mixed-case query against mixed-case text', () {
      expect(
        highlightSubstring('Hello World', 'hello', theme),
        equals('${hi}Hello$rs World'),
      );
    });

    test('preserves original case of the matched segment', () {
      final result = highlightSubstring('CamelCase', 'camelcase', theme);
      expect(result, contains('CamelCase'));
      expect(result, isNot(contains('camelcase')));
    });

    test('preserves original case of surrounding text', () {
      final result = highlightSubstring('FooBarBaz', 'bar', theme);
      expect(result, equals('Foo${hi}Bar${rs}Baz'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // First occurrence only
  // ══════════════════════════════════════════════════════════════════════════

  group('first occurrence only', () {
    test('highlights only the first match when text has duplicates', () {
      final result = highlightSubstring('banana', 'an', theme);
      expect(result, equals('b${hi}an${rs}ana'));
    });

    test('highlights first match in repeated words', () {
      final result = highlightSubstring('go go go', 'go', theme);
      expect(result, equals('${hi}go$rs go go'));
    });

    test('highlights first occurrence with different cases', () {
      final result = highlightSubstring('Cat cat CAT', 'cat', theme);
      expect(result, equals('${hi}Cat$rs cat CAT'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // No match
  // ══════════════════════════════════════════════════════════════════════════

  group('no match', () {
    test('returns text unchanged when query is not found', () {
      expect(
        highlightSubstring('Hello World', 'xyz', theme),
        equals('Hello World'),
      );
    });

    test('returns text unchanged for partial non-match', () {
      expect(
        highlightSubstring('abc', 'abcd', theme),
        equals('abc'),
      );
    });

    test('returns text unchanged for completely different text', () {
      expect(
        highlightSubstring('Dart', 'Python', theme),
        equals('Dart'),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Empty / edge cases
  // ══════════════════════════════════════════════════════════════════════════

  group('empty and edge cases', () {
    test('returns text unchanged when query is empty', () {
      expect(
        highlightSubstring('Hello', '', theme),
        equals('Hello'),
      );
    });

    test('returns empty string when both text and query are empty', () {
      expect(
        highlightSubstring('', '', theme),
        equals(''),
      );
    });

    test('returns empty string when text is empty and query is non-empty', () {
      expect(
        highlightSubstring('', 'search', theme),
        equals(''),
      );
    });

    test('handles single character text and query', () {
      expect(
        highlightSubstring('a', 'a', theme),
        equals('${hi}a$rs'),
      );
    });

    test('handles single character text with no match', () {
      expect(
        highlightSubstring('a', 'b', theme),
        equals('a'),
      );
    });

    test('handles text with spaces only', () {
      expect(
        highlightSubstring('   ', ' ', theme),
        equals('$hi $rs  '),
      );
    });

    test('handles query with spaces', () {
      expect(
        highlightSubstring('Hello World', ' ', theme),
        equals('Hello$hi ${rs}World'),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // enabled flag
  // ══════════════════════════════════════════════════════════════════════════

  group('enabled flag', () {
    test('returns text unchanged when enabled is false', () {
      expect(
        highlightSubstring('Hello World', 'Hello', theme, enabled: false),
        equals('Hello World'),
      );
    });

    test('returns text unchanged when enabled is false even with match', () {
      expect(
        highlightSubstring('abc', 'abc', theme, enabled: false),
        equals('abc'),
      );
    });

    test('highlights normally when enabled is true (default)', () {
      expect(
        highlightSubstring('Hello', 'Hello', theme),
        equals('${hi}Hello$rs'),
      );
    });

    test('highlights when enabled is explicitly true', () {
      expect(
        highlightSubstring('Hello', 'Hello', theme, enabled: true),
        equals('${hi}Hello$rs'),
      );
    });

    test('enabled false takes precedence over valid match', () {
      final result = highlightSubstring('banana', 'an', theme, enabled: false);
      expect(result, equals('banana'));
      expect(result, isNot(contains(hi)));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Different themes
  // ══════════════════════════════════════════════════════════════════════════

  group('different themes', () {
    test('uses matrix theme highlight color', () {
      const t = PromptTheme.matrix;
      final result = highlightSubstring('Hello', 'Hello', t);
      expect(result, contains(t.highlight));
      expect(result, contains(t.reset));
      expect(result, equals('${t.highlight}Hello${t.reset}'));
    });

    test('uses ocean theme highlight color', () {
      const t = PromptTheme.ocean;
      final result = highlightSubstring('World', 'World', t);
      expect(result, equals('${t.highlight}World${t.reset}'));
    });

    test('uses arcane theme highlight color (256-color)', () {
      const t = PromptTheme.arcane;
      final result = highlightSubstring('Arcane', 'arc', t);
      expect(result, equals('${t.highlight}Arc${t.reset}ane'));
    });

    test('uses custom theme colors', () {
      const custom = PromptTheme(
        colors: TerminalColors(
          highlight: '\x1B[38;5;200m',
          reset: '\x1B[0m',
        ),
      );
      final result = highlightSubstring('test', 'es', custom);
      expect(result, equals('t\x1B[38;5;200mes\x1B[0mt'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Special characters
  // ══════════════════════════════════════════════════════════════════════════

  group('special characters', () {
    test('highlights substring containing special regex chars', () {
      final result = highlightSubstring('price: \$10.00', '\$10', theme);
      expect(result, equals('price: $hi\$10$rs.00'));
    });

    test('handles parentheses in query', () {
      final result = highlightSubstring('fn(x)', '(x)', theme);
      expect(result, equals('fn$hi(x)$rs'));
    });

    test('handles brackets in text and query', () {
      final result = highlightSubstring('[item]', '[item]', theme);
      expect(result, equals('$hi[item]$rs'));
    });

    test('handles unicode characters', () {
      final result = highlightSubstring('café latte', 'café', theme);
      expect(result, equals('${hi}café$rs latte'));
    });

    test('handles newlines in text', () {
      final result = highlightSubstring('line1\nline2', 'line1', theme);
      expect(result, equals('${hi}line1$rs\nline2'));
    });

    test('handles tab characters', () {
      final result = highlightSubstring('col1\tcol2', 'col1', theme);
      expect(result, equals('${hi}col1$rs\tcol2'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Output structure
  // ══════════════════════════════════════════════════════════════════════════

  group('output structure', () {
    test('wraps match with exactly highlight + reset', () {
      final result = highlightSubstring('abcdef', 'cd', theme);
      expect(result, equals('ab${hi}cd${rs}ef'));
    });

    test('before segment contains no ANSI codes', () {
      final result = highlightSubstring('Hello World', 'World', theme);
      final before = result.split(hi).first;
      expect(before, equals('Hello '));
      expect(stripAnsi(before), equals(before));
    });

    test('after segment contains no ANSI codes', () {
      final result = highlightSubstring('Hello World', 'Hello', theme);
      final after = result.split(rs).last;
      expect(after, equals(' World'));
      expect(stripAnsi(after), equals(after));
    });

    test('stripping ANSI from result recovers original text', () {
      final result = highlightSubstring('Hello World', 'lo Wo', theme);
      expect(stripAnsi(result), equals('Hello World'));
    });

    test('stripping ANSI from no-match result recovers original text', () {
      final result = highlightSubstring('Hello', 'xyz', theme);
      expect(stripAnsi(result), equals('Hello'));
    });

    test('stripping ANSI from full-match result recovers original text', () {
      final result = highlightSubstring('test', 'test', theme);
      expect(stripAnsi(result), equals('test'));
    });

    test('visible length of highlighted result equals original length', () {
      final original = 'The quick brown fox';
      final result = highlightSubstring(original, 'quick', theme);
      expect(visibleLength(result), equals(original.length));
    });

    test('visible length unchanged for no-match', () {
      final original = 'abcdef';
      final result = highlightSubstring(original, 'xyz', theme);
      expect(visibleLength(result), equals(original.length));
    });

    test('visible length unchanged when disabled', () {
      final original = 'abcdef';
      final result = highlightSubstring(original, 'abc', theme, enabled: false);
      expect(visibleLength(result), equals(original.length));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Boundary positions
  // ══════════════════════════════════════════════════════════════════════════

  group('boundary positions', () {
    test('match at position 0', () {
      final result = highlightSubstring('abcdef', 'ab', theme);
      expect(result, equals('${hi}ab${rs}cdef'));
    });

    test('match at last possible position', () {
      final result = highlightSubstring('abcdef', 'ef', theme);
      expect(result, equals('abcd${hi}ef$rs'));
    });

    test('single char match at position 0', () {
      final result = highlightSubstring('xyz', 'x', theme);
      expect(result, equals('${hi}x${rs}yz'));
    });

    test('single char match at last position', () {
      final result = highlightSubstring('xyz', 'z', theme);
      expect(result, equals('xy${hi}z$rs'));
    });

    test('match leaving empty before segment', () {
      final result = highlightSubstring('Hello', 'He', theme);
      expect(result.startsWith(hi), isTrue);
    });

    test('match leaving empty after segment', () {
      final result = highlightSubstring('Hello', 'lo', theme);
      expect(result.endsWith(rs), isTrue);
    });
  });
}
