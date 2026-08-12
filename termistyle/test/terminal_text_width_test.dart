import 'package:termistyle/termistyle.dart';
import 'package:test/test.dart';

void main() {
  group('ASCII regression', () {
    test('padding and truncation retain their exact output', () {
      expect(padRight('Hi', 5), 'Hi   ');
      expect(padLeft('42', 5), '   42');
      expect(truncate('Hello World', 8), 'Hello W…');
      expect(truncate('Hello', 1), 'H');
      expect(truncatePad('Hi', 5), 'Hi   ');
    });

    test('zero-width truncation remains empty', () {
      expect(truncate('Hello', 0), '');
      expect(truncatePad('Hello', 0), '');
    });
  });

  group('terminal-cell width', () {
    test('measures CJK and full-width characters as two cells', () {
      expect(visibleLength('界Ａ'), 4);
      expect(padRight('界', 4), '界  ');
      expect(padLeft('界', 4), '  界');
    });

    test('measures decomposed accents as one grapheme and one cell', () {
      const accent = 'e\u0301';
      expect(visibleLength(accent), 1);
      expect(truncate('${accent}x', 1), accent);
    });

    test('measures common emoji clusters as two cells', () {
      expect(visibleLength('🙂'), 2);
      expect(visibleLength('👍🏽'), 2);
      expect(visibleLength('🇮🇱'), 2);
      expect(visibleLength('👨‍👩‍👧‍👦'), 2);
    });

    test('variation selector chooses emoji presentation', () {
      expect(visibleLength('❤'), 1);
      expect(visibleLength('❤️'), 2);
    });

    test('emoji controls need a valid emoji-capable base sequence', () {
      expect(visibleLength('\uFE0F'), 0);
      expect(visibleLength('\u200D'), 0);
      expect(visibleLength('\u20E3'), 0);
      expect(visibleLength('A\uFE0F'), 1);
      expect(visibleLength('a\u200D'), 1);
    });

    test('valid variation, keycap, and ZWJ emoji stay wide', () {
      expect(visibleLength('❤️'), 2);
      expect(visibleLength('1️⃣'), 2);
      expect(visibleLength('👨‍👩‍👧‍👦'), 2);
    });

    test('never splits an emoji or a wide grapheme', () {
      expect(truncate('🙂x', 1), '');
      expect(truncate('界x', 1), '');
      expect(truncate('界x', 2), '…');
      expect(truncatePad('界x', 2), '… ');
      expect(truncate('👨‍👩‍👧‍👦xy', 3), '👨‍👩‍👧‍👦…');
    });

    test('ambiguous-width characters stay narrow', () {
      expect(visibleLength('·Ω'), 2);
      expect(visibleLength('\u{1F100}'), 1); // DIGIT ZERO FULL STOP
      expect(visibleLength('\u{1F12F}'), 1); // COPYLEFT SYMBOL
    });

    test('supplementary emoji presentation remains wide', () {
      expect(visibleLength('\u{1F004}'), 2); // Mahjong red dragon
      expect(visibleLength('\u{1F600}'), 2); // Grinning face
      expect(visibleLength('\u{1FAE0}'), 2); // Melting face
    });
  });

  group('ANSI-aware truncation', () {
    test('preserves emitted SGR and closes an active style', () {
      const styled = '\x1B[31mHello\x1B[0m';
      final result = truncate(styled, 4);
      expect(result, '\x1B[31mHel…\x1B[0m');
      expect(stripAnsi(result), 'Hel…');
      expect(visibleLength(result), 4);
    });

    test('closes colon-form true-color SGR when clipped', () {
      const styled = '\x1B[38:2::255:0:0mHello';
      expect(truncate(styled, 4), '\x1B[38:2::255:0:0mHel…\x1B[0m');
    });

    test('tracks resets mixed with colon-form SGR state', () {
      const resetThenColor = '\x1B[0;38:2::255:0:0mHello';
      expect(
        truncate(resetThenColor, 4),
        '\x1B[0;38:2::255:0:0mHel…\x1B[0m',
      );

      const colorThenReset = '\x1B[38:2::255:0:0;0mHello';
      expect(
        truncate(colorThenReset, 4),
        '\x1B[38:2::255:0:0;0mHel…',
      );
    });

    test('does not add a reset when no active SGR was emitted', () {
      const styled = '\x1B[31mH\x1B[0mello';
      expect(truncate(styled, 4), '\x1B[31mH\x1B[0mel…');
    });

    test('closes an unterminated SGR even when text fits', () {
      expect(truncate('\x1B[31mHi', 5), '\x1B[31mHi\x1B[0m');
      expect(truncatePad('\x1B[31mHi', 5), '\x1B[31mHi\x1B[0m   ');
    });

    test('recognizes non-SGR CSI as zero-width', () {
      const value = 'A\x1B[2KB';
      expect(stripAnsi(value), 'AB');
      expect(visibleLength(value), 2);
    });

    test('strips OSC terminated by BEL or ST', () {
      expect(stripAnsi('\x1B]0;title\x07Text'), 'Text');
      expect(stripAnsi('\x1B]0;title\x1B\\Text'), 'Text');
    });

    test('preserves and closes an OSC 8 hyperlink when clipped', () {
      const linked = '\x1B]8;;https://example.com\x1B\\Hello'
          '\x1B]8;;\x1B\\';
      final result = truncate(linked, 4);
      expect(
        result,
        '\x1B]8;;https://example.com\x1B\\Hel…\x1B]8;;\x1B\\',
      );
      expect(stripAnsi(result), 'Hel…');
      expect(visibleLength(result), 4);
    });

    test('styled wide text truncates and pads to the cell budget', () {
      const styled = '\x1B[32m界界界\x1B[0m';
      final result = truncatePad(styled, 4);
      expect(stripAnsi(result), '界… ');
      expect(visibleLength(result), 4);
      expect(result.endsWith('\x1B[0m '), isTrue);
    });
  });

  group('cell-aware layout helpers', () {
    test('pads styled Unicode on either side and in the center', () {
      const styled = '\x1B[36m界\x1B[0m';
      expect(padVisibleRight(styled, 5), '$styled   ');
      expect(padVisibleLeft(styled, 5), '   $styled');
      expect(padVisibleCenter(styled, 5), ' $styled  ');
    });

    test('sizes plain and styled columns in terminal cells', () {
      expect(columnWidth(['A', '界界']), 4);
      expect(
        columnWidthVisible(['A', '\x1B[31m界界\x1B[0m']),
        4,
      );
      expect(columnWidth(['界界'], max: 3), 3);
      expect(columnWidthVisible(['界'], min: 5), 5);
    });
  });
}
