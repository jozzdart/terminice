import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

/// Accessible confirm prompt with themed buttons and sensible default focus.
extension ConfirmPromptExtensions on Terminice {
  /// Confirmation prompt with yes/no options and keyboard hints.
  ///
  /// - [prompt] is the title of the prompt (defaults to 'Confirm').
  /// - [message] is the main question asked to the user.
  /// - [yesLabel] is the text for the positive option (defaults to 'Yes').
  /// - [noLabel] is the text for the negative option (defaults to 'No').
  /// - [defaultYes] determines which option is initially focused (defaults to `true`).
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
  /// if (terminice.confirm(prompt: 'Delete', message: 'Are you sure?')) {
  ///   // User confirmed
  /// }
  /// ```
  bool confirm({
    String prompt = 'Confirm',
    required String message,
    String yesLabel = 'Yes',
    String noLabel = 'No',
    bool defaultYes = true,
  }) {
    return SimplePrompts.confirm(
      title: prompt,
      message: message,
      yesLabel: yesLabel,
      noLabel: noLabel,
      defaultYes: defaultYes,
      theme: defaultTheme,
    ).run();
  }
}
