import 'package:terminice_core/terminice_core.dart'
    show
        PromptTheme,
        TerminalColors,
        TerminalCompatibility,
        TerminalGlyphs,
        terminalSafeLineText;

import '../core/component_runner.dart';
import '../core/terminice_api.dart';
import '../core/terminice_config.dart';
import 'message_formatting.dart';

/// Adds small synchronous message primitives to [Terminice].
extension TerminiceMessageExtensions on Terminice {
  /// Writes [message] as a plain line without status decoration.
  void log(Object? message) {
    _writeMessage(this, _MessageKind.log, message);
  }

  /// Writes [message] as an informational line.
  void info(Object? message) {
    _writeMessage(this, _MessageKind.info, message);
  }

  /// Writes [message] as a success line.
  void success(Object? message) {
    _writeMessage(this, _MessageKind.success, message);
  }

  /// Writes [message] as a warning line.
  void warn(Object? message) {
    _writeMessage(this, _MessageKind.warn, message);
  }

  /// Writes [message] as an error line.
  void error(Object? message) {
    _writeMessage(this, _MessageKind.error, message);
  }

  /// Alias for [error].
  void err(Object? message) {
    error(message);
  }

  /// Writes [message] as a modest detail line.
  void detail(Object? message) {
    _writeMessage(this, _MessageKind.detail, message);
  }

  /// Writes [count] blank lines.
  void newline([int count = 1]) {
    runWithComponent<void>((context) {
      context.withActiveTerminal<void>(() {
        for (var i = 0; i < count; i++) {
          context.output.writeln();
        }
      });
    });
  }
}

enum _MessageKind { log, info, success, warn, error, detail }

void _writeMessage(Terminice terminice, _MessageKind kind, Object? message) {
  final text = message.toString();
  terminice.runWithComponent<void>((context) {
    final line = _formatMessage(
      kind: kind,
      message: text,
      theme: context.theme,
      plain: _shouldUsePlainMessages(context),
    );
    context.withActiveTerminal<void>(() {
      context.output.writeln(line);
    });
  });
}

String _formatMessage({
  required _MessageKind kind,
  required String message,
  required PromptTheme theme,
  required bool plain,
}) {
  if (plain) {
    return _plainMessage(kind, message);
  }
  return _modernMessage(kind, message, theme);
}

String _plainMessage(_MessageKind kind, String message) {
  final safeMessage = terminalSafeLineText(message);
  switch (kind) {
    case _MessageKind.log:
      return safeMessage;
    case _MessageKind.info:
      return terminiceStatusLine(terminiceInfoStatusLabel, safeMessage);
    case _MessageKind.success:
      return terminiceStatusLine(terminiceSuccessStatusLabel, safeMessage);
    case _MessageKind.warn:
      return terminiceStatusLine(terminiceWarnStatusLabel, safeMessage);
    case _MessageKind.error:
      return terminiceStatusLine(terminiceErrorStatusLabel, safeMessage);
    case _MessageKind.detail:
      return terminicePlainDetailLine(safeMessage);
  }
}

String _modernMessage(_MessageKind kind, String message, PromptTheme theme) {
  switch (kind) {
    case _MessageKind.log:
      return message;
    case _MessageKind.info:
      return _semanticLine(theme, theme.info, 'ℹ', message);
    case _MessageKind.success:
      return _semanticLine(theme, theme.checkboxOn, '✓', message);
    case _MessageKind.warn:
      return _semanticLine(theme, theme.warn, '⚠', message);
    case _MessageKind.error:
      return _semanticLine(theme, theme.error, '✗', message);
    case _MessageKind.detail:
      return terminiceModernDetailLine(theme, message);
  }
}

String _semanticLine(
  PromptTheme theme,
  String color,
  String glyph,
  String message,
) {
  return '$color$glyph${theme.reset} $message';
}

bool _shouldUsePlainMessages(TerminiceComponentContext context) {
  if (context.shouldUseFallback) return true;
  if (context.configuration.compatibility != TerminalCompatibility.modern) {
    return true;
  }
  if (_configurationRequestsPlainMessages(context)) return true;
  return false;
}

bool _configurationRequestsPlainMessages(TerminiceComponentContext context) {
  final explicitlyConfiguredTheme = context.configuration
      .copyWith(colorMode: TerminiceColorMode.always)
      .effectiveTheme;
  return _themeRequestsPlainMessages(explicitlyConfiguredTheme);
}

bool _themeRequestsPlainMessages(PromptTheme theme) {
  return _colorsArePlain(theme.colors) || _glyphsAreAscii(theme.glyphs);
}

bool _colorsArePlain(TerminalColors colors) {
  return colors.reset.isEmpty &&
      colors.bold.isEmpty &&
      colors.dim.isEmpty &&
      colors.gray.isEmpty &&
      colors.accent.isEmpty &&
      colors.keyAccent.isEmpty &&
      colors.highlight.isEmpty &&
      colors.selection.isEmpty &&
      colors.checkboxOn.isEmpty &&
      colors.checkboxOff.isEmpty &&
      colors.inverse.isEmpty &&
      colors.info.isEmpty &&
      colors.warn.isEmpty &&
      colors.error.isEmpty;
}

bool _glyphsAreAscii(TerminalGlyphs glyphs) {
  return _isAscii(glyphs.borderTop) &&
      _isAscii(glyphs.borderBottom) &&
      _isAscii(glyphs.borderVertical) &&
      _isAscii(glyphs.borderConnector) &&
      _isAscii(glyphs.borderHorizontal) &&
      _isAscii(glyphs.arrow) &&
      _isAscii(glyphs.checkboxOnSymbol) &&
      _isAscii(glyphs.checkboxOffSymbol);
}

bool _isAscii(String value) {
  return value.runes.every((rune) => rune <= 0x7F);
}
