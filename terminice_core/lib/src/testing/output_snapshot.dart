import 'dart:convert';

import 'mock_terminal.dart';

/// Captured terminal output with assertion-friendly derived text.
class TerminalOutputSnapshot {
  static final RegExp _terminalControlSequences = RegExp(
    r'\x1B(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1B\\)|[PX^_].*?\x1B\\|[@-Z\\-_])|\x9B[0-?]*[ -/]*[@-~]',
    dotAll: true,
  );

  static final RegExp _nonLineControlCharacters = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]',
  );

  static final RegExp _terminalControlCharacters = RegExp(
    r'[\x00-\x08\x0B\x0C\x0D\x0E-\x1F\x7F-\x9F]',
  );

  static final RegExp _lineEndings = RegExp(r'\r\n?');
  static final RegExp _trailingHorizontalWhitespace = RegExp(r'[ \t]+$');
  static final RegExp _trailingNewlines = RegExp(r'\n+$');

  /// The exact output captured by the mock output.
  final String raw;

  /// [raw] with terminal escape/control sequences removed.
  final String plainText;

  /// Plain text with line endings normalized, line-end spaces removed, and
  /// final newlines trimmed.
  final String normalizedText;

  /// Raw output split into lines.
  final List<String> lines;

  /// Plain text split into lines.
  final List<String> plainLines;

  /// Whether [raw] contains terminal control sequences or control characters.
  final bool containsAnsiControls;

  /// Whether [raw] is entirely ASCII.
  final bool isAscii;

  /// Creates a snapshot for [raw].
  TerminalOutputSnapshot(String raw)
      : raw = raw,
        plainText = stripTerminalControls(raw),
        normalizedText = normalizeText(stripTerminalControls(raw)),
        lines = List.unmodifiable(const LineSplitter().convert(raw)),
        plainLines = List.unmodifiable(
          const LineSplitter().convert(stripTerminalControls(raw)),
        ),
        containsAnsiControls = hasTerminalControls(raw),
        isAscii = raw.runes.every((rune) => rune <= 0x7F);

  /// Creates a snapshot from [output].
  factory TerminalOutputSnapshot.fromOutput(MockTerminalOutput output) {
    return TerminalOutputSnapshot(output.allOutput);
  }

  /// Removes terminal escape sequences and non-line control characters.
  static String stripTerminalControls(String text) {
    return text
        .replaceAll(_terminalControlSequences, '')
        .replaceAll(_nonLineControlCharacters, '');
  }

  /// Returns whether [text] contains terminal controls.
  static bool hasTerminalControls(String text) {
    return _terminalControlSequences.hasMatch(text) ||
        _terminalControlCharacters.hasMatch(text);
  }

  /// Normalizes stripped terminal output for stable text assertions.
  static String normalizeText(String text) {
    final normalizedLines = text
        .replaceAll(_lineEndings, '\n')
        .split('\n')
        .map((line) => line.replaceFirst(_trailingHorizontalWhitespace, ''))
        .join('\n');

    return normalizedLines.replaceFirst(_trailingNewlines, '');
  }
}

/// Snapshot conveniences for [MockTerminalOutput].
extension MockTerminalOutputSnapshotExtension on MockTerminalOutput {
  /// Captures the current output buffer.
  TerminalOutputSnapshot get snapshot =>
      TerminalOutputSnapshot.fromOutput(this);
}

/// Snapshot conveniences for [MockTerminal].
extension MockTerminalSnapshotExtension on MockTerminal {
  /// Captures the current output buffer.
  TerminalOutputSnapshot get outputSnapshot => mockOutput.snapshot;
}
