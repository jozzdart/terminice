import 'package:terminice_core/terminice_core.dart';

/// Plain fallback status label for informational messages.
const String terminiceInfoStatusLabel = 'INFO';

/// Plain fallback status label for successful work.
const String terminiceSuccessStatusLabel = 'OK';

/// Plain fallback status label for warning messages.
const String terminiceWarnStatusLabel = 'WARN';

/// Plain fallback status label for error messages.
const String terminiceErrorStatusLabel = 'ERROR';

/// Plain fallback status label for canceled work.
const String terminiceCanceledStatusLabel = 'CANCELED';

/// Formats a plain status line shared by tasks and message fallbacks.
String terminiceStatusLine(String status, String message,
    [String suffix = '']) {
  return '$status: $message$suffix';
}

/// Formats a plain detail line with Terminice's modest detail indentation.
String terminicePlainDetailLine(String message) {
  return '  $message';
}

/// Formats a dimmed modern detail line with the same detail indentation.
String terminiceModernDetailLine(PromptTheme theme, String message) {
  return '${theme.dim}${terminicePlainDetailLine(message)}${theme.reset}';
}
