import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Accessible confirm prompt with themed buttons and sensible default focus.
extension ConfirmPromptExtensions on Terminice {
  /// Confirmation prompt with yes/no options and keyboard hints.
  ///
  /// Controls:
  /// - ← / → change the highlighted option
  /// - Enter confirms the highlighted option
  /// - Esc cancels (returns `false`)
  ///
  /// Returns true if confirmed, false otherwise.
  ///
  /// **Example:**
  /// ```dart
  /// if (terminice.confirm(label: 'Delete', message: 'Are you sure?')) {
  ///   // User confirmed
  /// }
  /// ```
  bool confirm({
    required String label,
    required String message,
    String yesLabel = 'Yes',
    String noLabel = 'No',
    bool defaultYes = true,
  }) {
    return SimplePrompts.confirm(
      title: label,
      message: message,
      yesLabel: yesLabel,
      noLabel: noLabel,
      defaultYes: defaultYes,
      theme: defaultTheme,
    ).run();
  }
}
