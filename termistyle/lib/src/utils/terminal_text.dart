import 'package:characters/characters.dart';

import 'terminal_text_unicode_data.dart';

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
  if (runes.every(_isZeroWidth)) return 0;

  final hasEmojiPresentation = runes.any(_isEmojiPresentation) ||
      (runes.contains(0xfe0f) && runes.any(_isEmojiVariationBase)) ||
      (runes.contains(0x200d) &&
          runes.where(_isEmojiCapableBase).length >= 2) ||
      runes.where(_isRegionalIndicator).length >= 2 ||
      (runes.contains(0x20e3) && runes.any(_isKeycapBase));
  if (hasEmojiPresentation) return 2;
  if (runes.any((rune) => !_isZeroWidth(rune) && _isWide(rune))) return 2;
  return runes.any((rune) => !_isZeroWidth(rune)) ? 1 : 0;
}

bool _isRegionalIndicator(int rune) => rune >= 0x1f1e6 && rune <= 0x1f1ff;

bool _isKeycapBase(int rune) =>
    rune == 0x23 || rune == 0x2a || (rune >= 0x30 && rune <= 0x39);

bool _isEmojiCapableBase(int rune) =>
    _isEmojiPresentation(rune) || _isEmojiVariationBase(rune);

bool _isEmojiPresentation(int rune) =>
    !_isRegionalIndicator(rune) &&
    !(rune >= 0x1f3fb && rune <= 0x1f3ff) &&
    _isInSortedRanges(rune, terminalTextEmojiPresentationRanges);

bool _isEmojiVariationBase(int rune) =>
    _isInSortedRanges(rune, terminalTextEmojiVariationBaseRanges);

bool _isWide(int rune) => _isInSortedRanges(rune, terminalTextWideRanges);

bool _isZeroWidth(int rune) =>
    rune < 0x20 ||
    (rune >= 0x7f && rune < 0xa0) ||
    (rune >= 0x1f3fb && rune <= 0x1f3ff) ||
    _isInSortedRanges(rune, terminalTextZeroWidthRanges);

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
