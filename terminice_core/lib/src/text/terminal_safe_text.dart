/// Makes untrusted text safe for plain terminal output.
///
/// Printable Unicode and newlines are preserved. Every C0/C1 control
/// character, including tab, escape, carriage return, and delete, is
/// rendered as visible escaped text so it cannot affect terminal state.
String terminalSafeBlockText(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    if (rune == 0x0a || _isPrintableRune(rune)) {
      buffer.writeCharCode(rune);
      continue;
    }

    switch (rune) {
      case 0x1b:
        buffer.write(r'\x1b');
        continue;
      case 0x0d:
        buffer.write(r'\r');
        continue;
      case 0x09:
        buffer.write(r'\t');
        continue;
      case 0x7f:
        buffer.write(r'\x7f');
        continue;
      default:
        final width = rune <= 0xff ? 2 : 4;
        buffer
          ..write(r'\x')
          ..write(rune.toRadixString(16).padLeft(width, '0'));
        continue;
    }
  }
  return buffer.toString();
}

/// Makes untrusted text safe for one line of plain terminal output.
///
/// After terminal controls are escaped, whitespace (including newlines and
/// tabs) is collapsed to one ASCII space and surrounding whitespace is
/// removed.
String terminalSafeLineText(String value) {
  final withoutStructuralWhitespace =
      value.replaceAll('\n', ' ').replaceAll('\t', ' ');
  return terminalSafeBlockText(withoutStructuralWhitespace)
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _isPrintableRune(int rune) {
  return rune >= 0x20 && rune != 0x7f && (rune < 0x80 || rune > 0x9f);
}
