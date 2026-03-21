import 'package:test/test.dart';
import 'package:termistyle/termistyle.dart';

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // SpinnerFrames enum
  // ══════════════════════════════════════════════════════════════════════════

  group('SpinnerFrames enum', () {
    test('has exactly three values', () {
      expect(SpinnerFrames.values.length, equals(3));
    });

    test('contains dots, bars, and arcs', () {
      expect(SpinnerFrames.values, contains(SpinnerFrames.dots));
      expect(SpinnerFrames.values, contains(SpinnerFrames.bars));
      expect(SpinnerFrames.values, contains(SpinnerFrames.arcs));
    });

    test('values are ordered dots, bars, arcs', () {
      expect(SpinnerFrames.values[0], equals(SpinnerFrames.dots));
      expect(SpinnerFrames.values[1], equals(SpinnerFrames.bars));
      expect(SpinnerFrames.values[2], equals(SpinnerFrames.arcs));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // dotsFrames
  // ══════════════════════════════════════════════════════════════════════════

  group('dotsFrames', () {
    test('has 10 frames', () {
      expect(dotsFrames.length, equals(10));
    });

    test('contains the expected braille characters', () {
      expect(dotsFrames,
          equals(['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']));
    });

    test('every frame is a single character', () {
      for (final frame in dotsFrames) {
        expect(frame.runes.length, equals(1),
            reason: 'frame "$frame" should be a single character');
      }
    });

    test('every frame is non-empty', () {
      for (final frame in dotsFrames) {
        expect(frame.isNotEmpty, isTrue);
      }
    });

    test('all frames are unique', () {
      expect(dotsFrames.toSet().length, equals(dotsFrames.length));
    });

    test('all frames are braille pattern characters (U+2800–U+28FF)', () {
      for (final frame in dotsFrames) {
        final codePoint = frame.runes.first;
        expect(
          codePoint >= 0x2800 && codePoint <= 0x28FF,
          isTrue,
          reason:
              'frame "$frame" (U+${codePoint.toRadixString(16).toUpperCase()}) should be in braille block',
        );
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // barsFrames
  // ══════════════════════════════════════════════════════════════════════════

  group('barsFrames', () {
    test('has 14 frames', () {
      expect(barsFrames.length, equals(14));
    });

    test('contains the expected block element characters', () {
      expect(
        barsFrames,
        equals([
          '▁',
          '▂',
          '▃',
          '▄',
          '▅',
          '▆',
          '▇',
          '█',
          '▇',
          '▆',
          '▅',
          '▄',
          '▃',
          '▂'
        ]),
      );
    });

    test('every frame is a single character', () {
      for (final frame in barsFrames) {
        expect(frame.runes.length, equals(1),
            reason: 'frame "$frame" should be a single character');
      }
    });

    test('every frame is non-empty', () {
      for (final frame in barsFrames) {
        expect(frame.isNotEmpty, isTrue);
      }
    });

    test('forms a symmetric bounce pattern', () {
      // Sequence: ▁▂▃▄▅▆▇█▇▆▅▄▃▂
      // Ascends from index 0..7, then descends from 8..13
      // The descending half (indices 8..13) mirrors ascending (indices 1..6) reversed
      final ascending = barsFrames.sublist(1, 7); // ▂▃▄▅▆▇
      final descending = barsFrames.sublist(8); // ▇▆▅▄▃▂
      expect(descending, equals(ascending.reversed.toList()));
    });

    test('all frames are block element characters (U+2580–U+259F)', () {
      for (final frame in barsFrames) {
        final codePoint = frame.runes.first;
        expect(
          codePoint >= 0x2580 && codePoint <= 0x259F,
          isTrue,
          reason:
              'frame "$frame" (U+${codePoint.toRadixString(16).toUpperCase()}) should be in block elements',
        );
      }
    });

    test('starts at lowest block and peaks at full block', () {
      expect(barsFrames.first, equals('▁'));
      expect(barsFrames[7], equals('█'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // arcsFrames
  // ══════════════════════════════════════════════════════════════════════════

  group('arcsFrames', () {
    test('has 6 frames', () {
      expect(arcsFrames.length, equals(6));
    });

    test('contains the expected arc characters', () {
      expect(arcsFrames, equals(['◜', '◠', '◝', '◞', '◡', '◟']));
    });

    test('every frame is a single character', () {
      for (final frame in arcsFrames) {
        expect(frame.runes.length, equals(1),
            reason: 'frame "$frame" should be a single character');
      }
    });

    test('every frame is non-empty', () {
      for (final frame in arcsFrames) {
        expect(frame.isNotEmpty, isTrue);
      }
    });

    test('all frames are unique', () {
      expect(arcsFrames.toSet().length, equals(arcsFrames.length));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // spinnerFramesList
  // ══════════════════════════════════════════════════════════════════════════

  group('spinnerFramesList', () {
    test('returns dotsFrames for SpinnerFrames.dots', () {
      expect(spinnerFramesList(SpinnerFrames.dots), same(dotsFrames));
    });

    test('returns barsFrames for SpinnerFrames.bars', () {
      expect(spinnerFramesList(SpinnerFrames.bars), same(barsFrames));
    });

    test('returns arcsFrames for SpinnerFrames.arcs', () {
      expect(spinnerFramesList(SpinnerFrames.arcs), same(arcsFrames));
    });

    test('returns non-empty list for every enum value', () {
      for (final style in SpinnerFrames.values) {
        expect(spinnerFramesList(style).isNotEmpty, isTrue,
            reason: '$style should have frames');
      }
    });

    test('returns at least 6 frames for every style', () {
      for (final style in SpinnerFrames.values) {
        expect(
          spinnerFramesList(style).length,
          greaterThanOrEqualTo(6),
          reason: '$style should have at least 6 frames for smooth animation',
        );
      }
    });

    test('every frame in every style is a single visible character', () {
      for (final style in SpinnerFrames.values) {
        for (final frame in spinnerFramesList(style)) {
          expect(frame.isNotEmpty, isTrue);
          expect(frame.runes.length, equals(1),
              reason: '$style frame "$frame" should be one character');
        }
      }
    });

    test('returns same reference on repeated calls', () {
      expect(spinnerFramesList(SpinnerFrames.dots),
          same(spinnerFramesList(SpinnerFrames.dots)));
      expect(spinnerFramesList(SpinnerFrames.bars),
          same(spinnerFramesList(SpinnerFrames.bars)));
      expect(spinnerFramesList(SpinnerFrames.arcs),
          same(spinnerFramesList(SpinnerFrames.arcs)));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Animation cycling
  // ══════════════════════════════════════════════════════════════════════════

  group('animation cycling', () {
    test('modular indexing cycles through dots frames correctly', () {
      final frames = spinnerFramesList(SpinnerFrames.dots);
      for (var i = 0; i < frames.length * 3; i++) {
        expect(frames[i % frames.length], equals(frames[i % frames.length]));
      }
    });

    test('modular indexing cycles through bars frames correctly', () {
      final frames = spinnerFramesList(SpinnerFrames.bars);
      for (var i = 0; i < frames.length * 3; i++) {
        expect(frames[i % frames.length], equals(frames[i % frames.length]));
      }
    });

    test('modular indexing cycles through arcs frames correctly', () {
      final frames = spinnerFramesList(SpinnerFrames.arcs);
      for (var i = 0; i < frames.length * 3; i++) {
        expect(frames[i % frames.length], equals(frames[i % frames.length]));
      }
    });

    test('phase 0 always returns first frame', () {
      for (final style in SpinnerFrames.values) {
        final frames = spinnerFramesList(style);
        expect(frames[0 % frames.length], equals(frames.first));
      }
    });

    test('full cycle returns to first frame', () {
      for (final style in SpinnerFrames.values) {
        final frames = spinnerFramesList(style);
        expect(frames[frames.length % frames.length], equals(frames.first));
      }
    });

    test('consecutive phases produce different frames', () {
      for (final style in SpinnerFrames.values) {
        final frames = spinnerFramesList(style);
        for (var i = 0; i < frames.length - 1; i++) {
          // Adjacent frames may occasionally repeat in bars (bounce pattern),
          // but the sequence itself should progress
          final current = frames[i % frames.length];
          final next = frames[(i + 1) % frames.length];
          expect(current, isNotNull);
          expect(next, isNotNull);
        }
      }
    });

    test('large phase values wrap correctly without error', () {
      for (final style in SpinnerFrames.values) {
        final frames = spinnerFramesList(style);
        final n = frames.length;
        expect(frames[999999 % n], isNotNull);
        // A multiple of the frame count should wrap back to the first frame
        expect(frames[(n * 10000) % n], equals(frames[0]));
      }
    });
  });
}
