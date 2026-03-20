import 'package:test/test.dart';
import 'package:termistyle/termistyle.dart';

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // padRight
  // ══════════════════════════════════════════════════════════════════════════

  group('padRight', () {
    test('pads shorter text with trailing spaces', () {
      expect(padRight('Hi', 5), equals('Hi   '));
    });

    test('returns text unchanged when already at target width', () {
      expect(padRight('Hello', 5), equals('Hello'));
    });

    test('returns text unchanged when longer than target width', () {
      expect(padRight('Hello!', 3), equals('Hello!'));
    });

    test('handles empty string', () {
      expect(padRight('', 4), equals('    '));
    });

    test('handles zero width', () {
      expect(padRight('Hi', 0), equals('Hi'));
    });

    test('handles width of 1 with empty string', () {
      expect(padRight('', 1), equals(' '));
    });

    test('handles single character', () {
      expect(padRight('A', 3), equals('A  '));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // padLeft
  // ══════════════════════════════════════════════════════════════════════════

  group('padLeft', () {
    test('pads shorter text with leading spaces', () {
      expect(padLeft('42', 5), equals('   42'));
    });

    test('returns text unchanged when already at target width', () {
      expect(padLeft('Hello', 5), equals('Hello'));
    });

    test('returns text unchanged when longer than target width', () {
      expect(padLeft('Hello!', 3), equals('Hello!'));
    });

    test('handles empty string', () {
      expect(padLeft('', 4), equals('    '));
    });

    test('handles zero width', () {
      expect(padLeft('Hi', 0), equals('Hi'));
    });

    test('handles single character', () {
      expect(padLeft('X', 4), equals('   X'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // truncate
  // ══════════════════════════════════════════════════════════════════════════

  group('truncate', () {
    test('returns text unchanged when it fits within width', () {
      expect(truncate('Hi', 10), equals('Hi'));
    });

    test('returns text unchanged when exactly at width', () {
      expect(truncate('Hello', 5), equals('Hello'));
    });

    test('truncates with ellipsis when text exceeds width', () {
      expect(truncate('Hello World', 8), equals('Hello W…'));
    });

    test('truncates to single character when width is 1', () {
      expect(truncate('Hello', 1), equals('H'));
    });

    test('handles empty string', () {
      expect(truncate('', 5), equals(''));
    });

    test('handles width of 2', () {
      expect(truncate('Hello', 2), equals('H…'));
    });

    test('handles width of 3', () {
      expect(truncate('Hello World', 3), equals('He…'));
    });

    test('preserves text at boundary', () {
      expect(truncate('ABCDE', 5), equals('ABCDE'));
      expect(truncate('ABCDE', 4), equals('ABC…'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // truncatePad
  // ══════════════════════════════════════════════════════════════════════════

  group('truncatePad', () {
    test('pads shorter text to fill width', () {
      expect(truncatePad('Hi', 8), equals('Hi      '));
    });

    test('returns exact text when it matches width', () {
      expect(truncatePad('Hello', 5), equals('Hello'));
    });

    test('truncates with ellipsis when text exceeds width', () {
      expect(truncatePad('Hello World', 8), equals('Hello W…'));
    });

    test('handles width of 1 on long text', () {
      expect(truncatePad('Hello', 1), equals('H'));
    });

    test('handles empty string with padding', () {
      expect(truncatePad('', 5), equals('     '));
    });

    test('pads single character to target width', () {
      expect(truncatePad('A', 4), equals('A   '));
    });

    test('truncates at boundary minus one for ellipsis', () {
      expect(truncatePad('ABCDE', 4), equals('ABC…'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // stripAnsi
  // ══════════════════════════════════════════════════════════════════════════

  group('stripAnsi', () {
    test('removes single ANSI color code', () {
      expect(stripAnsi('\x1B[32mGreen\x1B[0m'), equals('Green'));
    });

    test('removes bold and reset codes', () {
      expect(stripAnsi('\x1B[1mBold\x1B[0m'), equals('Bold'));
    });

    test('removes multiple ANSI codes', () {
      expect(
        stripAnsi('\x1B[1m\x1B[36mCyan Bold\x1B[0m'),
        equals('Cyan Bold'),
      );
    });

    test('removes 256-color sequences', () {
      expect(
        stripAnsi('\x1B[38;5;141mPurple\x1B[0m'),
        equals('Purple'),
      );
    });

    test('returns plain text unchanged', () {
      expect(stripAnsi('Hello World'), equals('Hello World'));
    });

    test('handles empty string', () {
      expect(stripAnsi(''), equals(''));
    });

    test('handles string that is only ANSI codes', () {
      expect(stripAnsi('\x1B[0m\x1B[1m\x1B[32m'), equals(''));
    });

    test('handles mixed styled and unstyled segments', () {
      expect(
        stripAnsi('Hello \x1B[31mRed\x1B[0m World'),
        equals('Hello Red World'),
      );
    });

    test('removes dim code', () {
      expect(stripAnsi('\x1B[2mDimmed\x1B[0m'), equals('Dimmed'));
    });

    test('removes inverse code', () {
      expect(stripAnsi('\x1B[7mInverse\x1B[0m'), equals('Inverse'));
    });

    test('removes gray code', () {
      expect(stripAnsi('\x1B[90mGray\x1B[0m'), equals('Gray'));
    });

    test('removes chained escape sequences', () {
      expect(
        stripAnsi('\x1B[1m\x1B[4m\x1B[31mStyled\x1B[0m'),
        equals('Styled'),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // visibleLength
  // ══════════════════════════════════════════════════════════════════════════

  group('visibleLength', () {
    test('returns correct length for styled text', () {
      expect(visibleLength('\x1B[32mHi\x1B[0m'), equals(2));
    });

    test('returns correct length for plain text', () {
      expect(visibleLength('Hello'), equals(5));
    });

    test('returns 0 for empty string', () {
      expect(visibleLength(''), equals(0));
    });

    test('returns 0 for string with only ANSI codes', () {
      expect(visibleLength('\x1B[0m\x1B[1m'), equals(0));
    });

    test('counts only visible characters in mixed content', () {
      expect(
        visibleLength('A\x1B[31mB\x1B[0mC'),
        equals(3),
      );
    });

    test('handles 256-color codes correctly', () {
      expect(
        visibleLength('\x1B[38;5;200mColor\x1B[0m'),
        equals(5),
      );
    });

    test('counts unicode runes correctly', () {
      expect(visibleLength('café'), equals(4));
    });

    test('counts unicode runes in styled text', () {
      expect(visibleLength('\x1B[32mcafé\x1B[0m'), equals(4));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // padVisibleRight
  // ══════════════════════════════════════════════════════════════════════════

  group('padVisibleRight', () {
    test('pads styled text based on visible length', () {
      final styled = '\x1B[32mHi\x1B[0m';
      final result = padVisibleRight(styled, 5);
      expect(result, equals('$styled   '));
      expect(visibleLength(result), equals(5));
    });

    test('returns styled text unchanged when visible length meets width', () {
      final styled = '\x1B[32mHello\x1B[0m';
      expect(padVisibleRight(styled, 5), equals(styled));
    });

    test('returns styled text unchanged when visible length exceeds width', () {
      final styled = '\x1B[32mHello World\x1B[0m';
      expect(padVisibleRight(styled, 5), equals(styled));
    });

    test('works with plain text', () {
      expect(padVisibleRight('Hi', 5), equals('Hi   '));
    });

    test('handles empty styled string', () {
      final styled = '\x1B[32m\x1B[0m';
      final result = padVisibleRight(styled, 3);
      expect(visibleLength(result), equals(3));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // padVisibleLeft
  // ══════════════════════════════════════════════════════════════════════════

  group('padVisibleLeft', () {
    test('pads styled text with leading spaces based on visible length', () {
      final styled = '\x1B[32m42\x1B[0m';
      final result = padVisibleLeft(styled, 5);
      expect(result, equals('   $styled'));
      expect(visibleLength(result), equals(5));
    });

    test('returns styled text unchanged when visible length meets width', () {
      final styled = '\x1B[32mHello\x1B[0m';
      expect(padVisibleLeft(styled, 5), equals(styled));
    });

    test('returns styled text unchanged when visible length exceeds width', () {
      final styled = '\x1B[32mHello World\x1B[0m';
      expect(padVisibleLeft(styled, 5), equals(styled));
    });

    test('works with plain text', () {
      expect(padVisibleLeft('42', 5), equals('   42'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // padVisibleCenter
  // ══════════════════════════════════════════════════════════════════════════

  group('padVisibleCenter', () {
    test('centers styled text with even total padding', () {
      final styled = '\x1B[31mHi\x1B[0m';
      final result = padVisibleCenter(styled, 6);
      expect(result, equals('  $styled  '));
      expect(visibleLength(result), equals(6));
    });

    test('centers styled text with odd total padding (left gets fewer)', () {
      final styled = '\x1B[31mHi\x1B[0m';
      final result = padVisibleCenter(styled, 5);
      expect(result, equals(' $styled  '));
      expect(visibleLength(result), equals(5));
    });

    test('returns styled text unchanged when visible length meets width', () {
      final styled = '\x1B[31mHello\x1B[0m';
      expect(padVisibleCenter(styled, 5), equals(styled));
    });

    test('returns styled text unchanged when visible length exceeds width', () {
      final styled = '\x1B[31mHello World\x1B[0m';
      expect(padVisibleCenter(styled, 5), equals(styled));
    });

    test('works with plain text', () {
      expect(padVisibleCenter('AB', 6), equals('  AB  '));
    });

    test('handles single character centering', () {
      final result = padVisibleCenter('X', 5);
      expect(result, equals('  X  '));
      expect(result.length, equals(5));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // clampInt
  // ══════════════════════════════════════════════════════════════════════════

  group('clampInt', () {
    test('returns value when within range', () {
      expect(clampInt(5, 1, 10), equals(5));
    });

    test('clamps to min when below range', () {
      expect(clampInt(-5, 1, 10), equals(1));
    });

    test('clamps to max when above range', () {
      expect(clampInt(15, 1, 10), equals(10));
    });

    test('returns min when value equals min', () {
      expect(clampInt(1, 1, 10), equals(1));
    });

    test('returns max when value equals max', () {
      expect(clampInt(10, 1, 10), equals(10));
    });

    test('handles min equals max', () {
      expect(clampInt(5, 3, 3), equals(3));
      expect(clampInt(3, 3, 3), equals(3));
      expect(clampInt(1, 3, 3), equals(3));
    });

    test('handles negative ranges', () {
      expect(clampInt(-5, -10, -1), equals(-5));
      expect(clampInt(0, -10, -1), equals(-1));
      expect(clampInt(-15, -10, -1), equals(-10));
    });

    test('handles zero-centered range', () {
      expect(clampInt(0, -5, 5), equals(0));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // maxOf
  // ══════════════════════════════════════════════════════════════════════════

  group('maxOf', () {
    test('finds maximum in a list of positive integers', () {
      expect(maxOf([3, 7, 2, 9, 1]), equals(9));
    });

    test('returns 0 for empty iterable', () {
      expect(maxOf([]), equals(0));
    });

    test('returns the single element for single-element list', () {
      expect(maxOf([42]), equals(42));
    });

    test('handles all equal values', () {
      expect(maxOf([5, 5, 5]), equals(5));
    });

    test('returns 0 when all values are negative', () {
      expect(maxOf([-3, -7, -1]), equals(0));
    });

    test('handles list with zero', () {
      expect(maxOf([0, 3, 1]), equals(3));
    });

    test('handles large values', () {
      expect(maxOf([1000000, 999999, 1000001]), equals(1000001));
    });

    test('works with generators', () {
      expect(maxOf([1, 2, 3].map((x) => x * 10)), equals(30));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // minOf
  // ══════════════════════════════════════════════════════════════════════════

  group('minOf', () {
    test('finds minimum in a list of positive integers', () {
      expect(minOf([3, 7, 2, 9, 1]), equals(1));
    });

    test('returns 0 for empty iterable', () {
      expect(minOf([]), equals(0));
    });

    test('returns the single element for single-element list', () {
      expect(minOf([42]), equals(42));
    });

    test('handles all equal values', () {
      expect(minOf([5, 5, 5]), equals(5));
    });

    test('handles negative values', () {
      expect(minOf([-3, -7, -1]), equals(-7));
    });

    test('handles mix of positive and negative', () {
      expect(minOf([5, -2, 3, -8, 1]), equals(-8));
    });

    test('handles list with zero', () {
      expect(minOf([0, 3, 1]), equals(0));
    });

    test('works with generators', () {
      expect(minOf([10, 20, 30].map((x) => x - 5)), equals(5));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // columnWidth
  // ══════════════════════════════════════════════════════════════════════════

  group('columnWidth', () {
    test('returns width of longest string', () {
      expect(columnWidth(['Name', 'Alice', 'Bob']), equals(5));
    });

    test('respects minimum width', () {
      expect(columnWidth(['A', 'B'], min: 10), equals(10));
    });

    test('respects maximum width', () {
      expect(columnWidth(['VeryLongName'], max: 8), equals(8));
    });

    test('clamps between min and max', () {
      expect(columnWidth(['Hi'], min: 4, max: 20), equals(4));
    });

    test('returns 0 for empty iterable with default bounds', () {
      expect(columnWidth([]), equals(0));
    });

    test('returns min for empty iterable with min set', () {
      expect(columnWidth([], min: 5), equals(5));
    });

    test('handles single element', () {
      expect(columnWidth(['Hello']), equals(5));
    });

    test('handles all empty strings', () {
      expect(columnWidth(['', '', '']), equals(0));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // columnWidthVisible
  // ══════════════════════════════════════════════════════════════════════════

  group('columnWidthVisible', () {
    test('ignores ANSI codes when computing width', () {
      final cells = [
        '\x1B[32mName\x1B[0m',
        '\x1B[31mAlice\x1B[0m',
        '\x1B[33mBob\x1B[0m',
      ];
      expect(columnWidthVisible(cells), equals(5));
    });

    test('matches columnWidth for plain text', () {
      final cells = ['Name', 'Alice', 'Bob'];
      expect(columnWidthVisible(cells), equals(columnWidth(cells)));
    });

    test('respects minimum width', () {
      final cells = ['\x1B[32mA\x1B[0m'];
      expect(columnWidthVisible(cells, min: 10), equals(10));
    });

    test('respects maximum width', () {
      final cells = ['\x1B[32mVeryLongContent\x1B[0m'];
      expect(columnWidthVisible(cells, max: 8), equals(8));
    });

    test('returns 0 for empty iterable', () {
      expect(columnWidthVisible([]), equals(0));
    });

    test('handles strings that are only ANSI codes', () {
      final cells = ['\x1B[0m', '\x1B[1m\x1B[32m'];
      expect(columnWidthVisible(cells), equals(0));
    });

    test('handles mixed styled and plain cells', () {
      final cells = [
        'Plain',
        '\x1B[32mStyled\x1B[0m',
        'Short',
      ];
      expect(columnWidthVisible(cells), equals(6));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Integration / cross-function tests
  // ══════════════════════════════════════════════════════════════════════════

  group('integration', () {
    test('padVisibleRight produces correct visible width after padding', () {
      final styled = '\x1B[1m\x1B[36mBold Cyan\x1B[0m';
      final padded = padVisibleRight(styled, 20);
      expect(visibleLength(padded), equals(20));
      expect(stripAnsi(padded), equals('Bold Cyan           '));
    });

    test('padVisibleLeft produces correct visible width after padding', () {
      final styled = '\x1B[31m42\x1B[0m';
      final padded = padVisibleLeft(styled, 8);
      expect(visibleLength(padded), equals(8));
      expect(stripAnsi(padded), equals('      42'));
    });

    test('padVisibleCenter produces correct visible width after padding', () {
      final styled = '\x1B[33mOK\x1B[0m';
      final padded = padVisibleCenter(styled, 10);
      expect(visibleLength(padded), equals(10));
      expect(stripAnsi(padded), equals('    OK    '));
    });

    test('truncatePad produces fixed-width output for varying input', () {
      const width = 10;
      expect(truncatePad('Short', width).length, equals(width));
      expect(truncatePad('Exactly 10', width).length, equals(width));
      expect(truncatePad('This is way too long', width).length, equals(width));
    });

    test('columnWidthVisible with clamp feeds into padVisibleRight', () {
      final cells = [
        '\x1B[32mName\x1B[0m',
        '\x1B[31mAlice\x1B[0m',
        '\x1B[33mBob\x1B[0m',
      ];
      final width = columnWidthVisible(cells, min: 8);
      for (final cell in cells) {
        final padded = padVisibleRight(cell, width);
        expect(visibleLength(padded), equals(width));
      }
    });

    test('stripAnsi is idempotent', () {
      final styled = '\x1B[1m\x1B[32mHello\x1B[0m';
      final stripped = stripAnsi(styled);
      expect(stripAnsi(stripped), equals(stripped));
    });

    test('visibleLength matches stripAnsi length for ASCII text', () {
      final styled = '\x1B[36mTest\x1B[0m';
      expect(visibleLength(styled), equals(stripAnsi(styled).length));
    });
  });
}
