import 'package:characters/characters.dart';

/// Parsed terminal text used by all layout-oriented string helpers.
///
/// This is intentionally not a terminal emulator. It recognizes control
/// sequences commonly embedded in layout text and treats them as zero-width,
/// while measuring printable text in conventional terminal cells.
class TerminalText {
  TerminalText(this.source) : _tokens = _tokenize(source);

  final String source;
  final List<_Token> _tokens;

  int get width {
    var result = 0;
    for (final token in _tokens) {
      result += token.width;
    }
    return result;
  }

  String get plainText {
    final result = StringBuffer();
    for (final token in _tokens) {
      if (token is _GraphemeToken) result.write(token.value);
    }
    return result.toString();
  }

  String truncate(int cellWidth) {
    if (cellWidth < 0) {
      throw RangeError.range(cellWidth, 0, null, 'width');
    }
    if (width <= cellWidth) return _closedSource;
    if (cellWidth == 0) return '';

    // Preserve the historical ASCII behavior at width 1 (the first character,
    // without an ellipsis), while refusing to split a two-cell grapheme.
    final contentWidth = cellWidth == 1 ? 1 : cellWidth - 1;
    final output = StringBuffer();
    final pendingControls = <_ControlToken>[];
    var used = 0;
    var emittedGrapheme = false;
    var sgrActive = false;
    var hyperlinkActive = false;

    for (final token in _tokens) {
      if (token is _ControlToken) {
        pendingControls.add(token);
        continue;
      }

      final grapheme = token as _GraphemeToken;
      if (used + grapheme.width > contentWidth) break;

      for (final control in pendingControls) {
        output.write(control.value);
        final state = control.updateState(sgrActive, hyperlinkActive);
        sgrActive = state.sgrActive;
        hyperlinkActive = state.hyperlinkActive;
      }
      pendingControls.clear();
      output.write(grapheme.value);
      used += grapheme.width;
      emittedGrapheme = true;
    }

    // Avoid returning only invisible styling when the first grapheme cannot fit.
    if (!emittedGrapheme && cellWidth == 1) return '';
    if (cellWidth > 1) output.write('…');
    if (hyperlinkActive) output.write('\x1B]8;;\x1B\\');
    if (sgrActive) output.write('\x1B[0m');
    return output.toString();
  }

  String get _closedSource {
    var sgrActive = false;
    var hyperlinkActive = false;
    for (final token in _tokens) {
      if (token is! _ControlToken) continue;
      final state = token.updateState(sgrActive, hyperlinkActive);
      sgrActive = state.sgrActive;
      hyperlinkActive = state.hyperlinkActive;
    }
    if (!sgrActive && !hyperlinkActive) return source;
    final output = StringBuffer(source);
    if (hyperlinkActive) output.write('\x1B]8;;\x1B\\');
    if (sgrActive) output.write('\x1B[0m');
    return output.toString();
  }

  static List<_Token> _tokenize(String input) {
    final tokens = <_Token>[];
    var textStart = 0;
    var index = 0;

    void addText(int end) {
      if (end <= textStart) return;
      for (final grapheme in input.substring(textStart, end).characters) {
        tokens.add(_GraphemeToken(grapheme, _graphemeWidth(grapheme)));
      }
    }

    while (index < input.length) {
      if (input.codeUnitAt(index) != 0x1b) {
        index++;
        continue;
      }

      final escapeEnd = _escapeSequenceEnd(input, index);
      if (escapeEnd == null) {
        index++;
        continue;
      }
      addText(index);
      tokens.add(_ControlToken(input.substring(index, escapeEnd)));
      index = escapeEnd;
      textStart = index;
    }
    addText(input.length);
    return tokens;
  }
}

abstract class _Token {
  const _Token(this.value, this.width);

  final String value;
  final int width;
}

class _GraphemeToken extends _Token {
  const _GraphemeToken(super.value, super.width);
}

class _ControlToken extends _Token {
  const _ControlToken(String value) : super(value, 0);

  _StyleState updateState(bool sgrActive, bool hyperlinkActive) {
    if (value.startsWith('\x1B[') && value.endsWith('m')) {
      final parameters = value.substring(2, value.length - 1);
      final codes = parameters.isEmpty
          ? const <int>[0]
          : parameters
              .split(';')
              // ISO 8613-6 color forms use colon-separated subparameters,
              // whose first value is still the SGR function (for example
              // `38:2::255:0:0`).
              .map((part) => int.tryParse(part.split(':').first) ?? 0)
              .toList();
      final lastReset = codes.lastIndexOf(0);
      sgrActive = codes.skip(lastReset + 1).any((code) => code != 0) ||
          (lastReset < 0 && codes.any((code) => code != 0));
    } else if (value.startsWith('\x1B]8;')) {
      final terminatorLength = value.endsWith('\x07') ? 1 : 2;
      final payload = value.substring(4, value.length - terminatorLength);
      final separator = payload.indexOf(';');
      if (separator >= 0) {
        hyperlinkActive = payload.substring(separator + 1).isNotEmpty;
      }
    }
    return _StyleState(sgrActive, hyperlinkActive);
  }
}

class _StyleState {
  const _StyleState(this.sgrActive, this.hyperlinkActive);

  final bool sgrActive;
  final bool hyperlinkActive;
}

int? _escapeSequenceEnd(String input, int start) {
  if (start + 1 >= input.length) return null;
  final kind = input.codeUnitAt(start + 1);

  // CSI: parameters/intermediates followed by a final byte.
  if (kind == 0x5b) {
    for (var i = start + 2; i < input.length; i++) {
      final code = input.codeUnitAt(i);
      if (code >= 0x40 && code <= 0x7e) return i + 1;
    }
    return null;
  }

  // OSC: terminated by BEL or String Terminator (ESC backslash).
  if (kind == 0x5d) {
    for (var i = start + 2; i < input.length; i++) {
      final code = input.codeUnitAt(i);
      if (code == 0x07) return i + 1;
      if (code == 0x1b &&
          i + 1 < input.length &&
          input.codeUnitAt(i + 1) == 0x5c) {
        return i + 2;
      }
    }
    return null;
  }

  // Other common two-byte ESC sequences are non-printing too.
  if (kind >= 0x30 && kind <= 0x7e) return start + 2;
  return null;
}

int _graphemeWidth(String grapheme) {
  final runes = grapheme.runes.toList();
  if (runes.isEmpty) return 0;

  final hasEmojiPresentation = runes.any(_isEmojiPresentation) ||
      (runes.contains(0xfe0f) && runes.any(_isEmojiVariationBase)) ||
      (runes.contains(0x200d) &&
          runes.where(_isEmojiCapableBase).length >= 2) ||
      runes.where(_isRegionalIndicator).length >= 2 ||
      (runes.contains(0x20e3) && runes.any(_isKeycapBase));
  if (hasEmojiPresentation) return 2;
  if (runes.any(_isWide)) return 2;
  return runes.any((rune) => !_isZeroWidth(rune)) ? 1 : 0;
}

bool _isRegionalIndicator(int rune) => rune >= 0x1f1e6 && rune <= 0x1f1ff;

bool _isKeycapBase(int rune) =>
    rune == 0x23 || rune == 0x2a || (rune >= 0x30 && rune <= 0x39);

bool _isEmojiCapableBase(int rune) =>
    _isEmojiPresentation(rune) || _isEmojiVariationBase(rune);

bool _isEmojiPresentation(int rune) =>
    (rune >= 0x231a && rune <= 0x231b) ||
    (rune >= 0x23e9 && rune <= 0x23ec) ||
    rune == 0x23f0 ||
    rune == 0x23f3 ||
    (rune >= 0x25fd && rune <= 0x25fe) ||
    (rune >= 0x2614 && rune <= 0x2615) ||
    (rune >= 0x2648 && rune <= 0x2653) ||
    rune == 0x267f ||
    rune == 0x2693 ||
    rune == 0x26a1 ||
    (rune >= 0x26aa && rune <= 0x26ab) ||
    (rune >= 0x26bd && rune <= 0x26be) ||
    (rune >= 0x26c4 && rune <= 0x26c5) ||
    rune == 0x26ce ||
    rune == 0x26d4 ||
    rune == 0x26ea ||
    (rune >= 0x26f2 && rune <= 0x26f3) ||
    rune == 0x26f5 ||
    rune == 0x26fa ||
    rune == 0x26fd ||
    rune == 0x2705 ||
    (rune >= 0x270a && rune <= 0x270b) ||
    rune == 0x2728 ||
    rune == 0x274c ||
    rune == 0x274e ||
    (rune >= 0x2753 && rune <= 0x2755) ||
    rune == 0x2757 ||
    (rune >= 0x2795 && rune <= 0x2797) ||
    rune == 0x27b0 ||
    rune == 0x27bf ||
    (rune >= 0x2b1b && rune <= 0x2b1c) ||
    rune == 0x2b50 ||
    rune == 0x2b55 ||
    _isSupplementaryEmojiPresentation(rune);

// Merged supplementary-plane ranges from Unicode 15.1's
// `Emoji_Presentation` property. Regional indicators are intentionally omitted:
// terminals conventionally render a single indicator narrowly, while the
// paired flag grapheme is handled explicitly in [_graphemeWidth].
// dart format off
const _supplementaryEmojiPresentationRanges = <int>[
  0x1f004,
  0x1f004,
  0x1f0cf,
  0x1f0cf,
  0x1f18e,
  0x1f18e,
  0x1f191,
  0x1f19a,
  0x1f201,
  0x1f201,
  0x1f21a,
  0x1f21a,
  0x1f22f,
  0x1f22f,
  0x1f232,
  0x1f236,
  0x1f238,
  0x1f23a,
  0x1f250,
  0x1f251,
  0x1f300,
  0x1f320,
  0x1f32d,
  0x1f335,
  0x1f337,
  0x1f37c,
  0x1f37e,
  0x1f393,
  0x1f3a0,
  0x1f3ca,
  0x1f3cf,
  0x1f3d3,
  0x1f3e0,
  0x1f3f0,
  0x1f3f4,
  0x1f3f4,
  0x1f3f8,
  0x1f43e,
  0x1f440,
  0x1f440,
  0x1f442,
  0x1f4fc,
  0x1f4ff,
  0x1f53d,
  0x1f54b,
  0x1f54e,
  0x1f550,
  0x1f567,
  0x1f57a,
  0x1f57a,
  0x1f595,
  0x1f596,
  0x1f5a4,
  0x1f5a4,
  0x1f5fb,
  0x1f64f,
  0x1f680,
  0x1f6c5,
  0x1f6cc,
  0x1f6cc,
  0x1f6d0,
  0x1f6d2,
  0x1f6d5,
  0x1f6d7,
  0x1f6dc,
  0x1f6df,
  0x1f6eb,
  0x1f6ec,
  0x1f6f4,
  0x1f6fc,
  0x1f7e0,
  0x1f7eb,
  0x1f7f0,
  0x1f7f0,
  0x1f90c,
  0x1f93a,
  0x1f93c,
  0x1f945,
  0x1f947,
  0x1f9ff,
  0x1fa70,
  0x1fa7c,
  0x1fa80,
  0x1fa88,
  0x1fa90,
  0x1fabd,
  0x1fabf,
  0x1fac5,
  0x1face,
  0x1fadb,
  0x1fae0,
  0x1fae8,
  0x1faf0,
  0x1faf8
];
// dart format on

bool _isSupplementaryEmojiPresentation(int rune) =>
    _isInSortedRanges(rune, _supplementaryEmojiPresentationRanges);

// Text-default characters for which Unicode 15.1 defines an emoji variation
// sequence. Default-emoji characters are already covered by
// [_isEmojiPresentation], so excluding them keeps this table compact.
// dart format off
const _emojiVariationBaseRanges = <int>[
  0x23,
  0x23,
  0x2a,
  0x2a,
  0x30,
  0x39,
  0xa9,
  0xa9,
  0xae,
  0xae,
  0x203c,
  0x203c,
  0x2049,
  0x2049,
  0x2122,
  0x2122,
  0x2139,
  0x2139,
  0x2194,
  0x2199,
  0x21a9,
  0x21aa,
  0x2328,
  0x2328,
  0x23cf,
  0x23cf,
  0x23ed,
  0x23ef,
  0x23f1,
  0x23f2,
  0x23f8,
  0x23fa,
  0x24c2,
  0x24c2,
  0x25aa,
  0x25ab,
  0x25b6,
  0x25b6,
  0x25c0,
  0x25c0,
  0x25fb,
  0x25fc,
  0x2600,
  0x2604,
  0x260e,
  0x260e,
  0x2611,
  0x2611,
  0x2618,
  0x2618,
  0x261d,
  0x261d,
  0x2620,
  0x2620,
  0x2622,
  0x2623,
  0x2626,
  0x2626,
  0x262a,
  0x262a,
  0x262e,
  0x262f,
  0x2638,
  0x263a,
  0x2640,
  0x2640,
  0x2642,
  0x2642,
  0x265f,
  0x2660,
  0x2663,
  0x2663,
  0x2665,
  0x2666,
  0x2668,
  0x2668,
  0x267b,
  0x267b,
  0x267e,
  0x267e,
  0x2692,
  0x2692,
  0x2694,
  0x2697,
  0x2699,
  0x2699,
  0x269b,
  0x269c,
  0x26a0,
  0x26a0,
  0x26a7,
  0x26a7,
  0x26b0,
  0x26b1,
  0x26c8,
  0x26c8,
  0x26cf,
  0x26cf,
  0x26d1,
  0x26d1,
  0x26d3,
  0x26d3,
  0x26e9,
  0x26e9,
  0x26f0,
  0x26f1,
  0x26f4,
  0x26f4,
  0x26f7,
  0x26f9,
  0x2702,
  0x2702,
  0x2708,
  0x2709,
  0x270c,
  0x270d,
  0x270f,
  0x270f,
  0x2712,
  0x2712,
  0x2714,
  0x2714,
  0x2716,
  0x2716,
  0x271d,
  0x271d,
  0x2721,
  0x2721,
  0x2733,
  0x2734,
  0x2744,
  0x2744,
  0x2747,
  0x2747,
  0x2763,
  0x2764,
  0x27a1,
  0x27a1,
  0x2934,
  0x2935,
  0x2b05,
  0x2b07,
  0x3030,
  0x3030,
  0x303d,
  0x303d,
  0x3297,
  0x3297,
  0x3299,
  0x3299,
  0x1f170,
  0x1f171,
  0x1f17e,
  0x1f17f,
  0x1f202,
  0x1f202,
  0x1f237,
  0x1f237,
  0x1f321,
  0x1f321,
  0x1f324,
  0x1f32c,
  0x1f336,
  0x1f336,
  0x1f37d,
  0x1f37d,
  0x1f396,
  0x1f397,
  0x1f399,
  0x1f39b,
  0x1f39e,
  0x1f39f,
  0x1f3cb,
  0x1f3ce,
  0x1f3d4,
  0x1f3df,
  0x1f3f3,
  0x1f3f3,
  0x1f3f5,
  0x1f3f5,
  0x1f3f7,
  0x1f3f7,
  0x1f43f,
  0x1f43f,
  0x1f441,
  0x1f441,
  0x1f4fd,
  0x1f4fd,
  0x1f549,
  0x1f54a,
  0x1f56f,
  0x1f570,
  0x1f573,
  0x1f579,
  0x1f587,
  0x1f587,
  0x1f58a,
  0x1f58d,
  0x1f590,
  0x1f590,
  0x1f5a5,
  0x1f5a5,
  0x1f5a8,
  0x1f5a8,
  0x1f5b1,
  0x1f5b2,
  0x1f5bc,
  0x1f5bc,
  0x1f5c2,
  0x1f5c4,
  0x1f5d1,
  0x1f5d3,
  0x1f5dc,
  0x1f5de,
  0x1f5e1,
  0x1f5e1,
  0x1f5e3,
  0x1f5e3,
  0x1f5e8,
  0x1f5e8,
  0x1f5ef,
  0x1f5ef,
  0x1f5f3,
  0x1f5f3,
  0x1f5fa,
  0x1f5fa,
  0x1f6cb,
  0x1f6cb,
  0x1f6cd,
  0x1f6cf,
  0x1f6e0,
  0x1f6e5,
  0x1f6e9,
  0x1f6e9,
  0x1f6f0,
  0x1f6f0,
  0x1f6f3,
  0x1f6f3
];
// dart format on

bool _isEmojiVariationBase(int rune) =>
    _isInSortedRanges(rune, _emojiVariationBaseRanges);

bool _isInSortedRanges(int rune, List<int> ranges) {
  var low = 0;
  var high = ranges.length ~/ 2 - 1;
  while (low <= high) {
    final middle = (low + high) ~/ 2;
    final start = ranges[middle * 2];
    final end = ranges[middle * 2 + 1];
    if (rune < start) {
      high = middle - 1;
    } else if (rune > end) {
      low = middle + 1;
    } else {
      return true;
    }
  }
  return false;
}

bool _isWide(int rune) =>
    rune >= 0x1100 &&
    (rune <= 0x115f ||
        rune == 0x2329 ||
        rune == 0x232a ||
        (rune >= 0x2e80 && rune <= 0xa4cf && rune != 0x303f) ||
        (rune >= 0xac00 && rune <= 0xd7a3) ||
        (rune >= 0xf900 && rune <= 0xfaff) ||
        (rune >= 0xfe10 && rune <= 0xfe19) ||
        (rune >= 0xfe30 && rune <= 0xfe6f) ||
        (rune >= 0xff00 && rune <= 0xff60) ||
        (rune >= 0xffe0 && rune <= 0xffe6) ||
        (rune >= 0x20000 && rune <= 0x3fffd));

bool _isZeroWidth(int rune) =>
    rune == 0 ||
    rune < 0x20 ||
    (rune >= 0x7f && rune < 0xa0) ||
    (rune >= 0x300 && rune <= 0x36f) ||
    (rune >= 0x483 && rune <= 0x489) ||
    (rune >= 0x591 && rune <= 0x5bd) ||
    rune == 0x5bf ||
    (rune >= 0x5c1 && rune <= 0x5c2) ||
    (rune >= 0x5c4 && rune <= 0x5c5) ||
    rune == 0x5c7 ||
    (rune >= 0x610 && rune <= 0x61a) ||
    (rune >= 0x64b && rune <= 0x65f) ||
    rune == 0x670 ||
    (rune >= 0x6d6 && rune <= 0x6ed) ||
    (rune >= 0x200b && rune <= 0x200f) ||
    (rune >= 0x202a && rune <= 0x202e) ||
    (rune >= 0x2060 && rune <= 0x206f) ||
    (rune >= 0x20d0 && rune <= 0x20ff) ||
    (rune >= 0xfe00 && rune <= 0xfe0f) ||
    rune == 0xfeff ||
    (rune >= 0x1f3fb && rune <= 0x1f3ff) ||
    (rune >= 0xe0100 && rune <= 0xe01ef);
