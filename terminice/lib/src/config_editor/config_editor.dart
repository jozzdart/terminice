import 'package:terminice/terminice.dart';

import 'editor_loop.dart';

/// Config editor that presents a themed, searchable list of configurable fields
/// and lets the user edit each one using the appropriate prompt.
///
/// Runs as a single terminal session that temporarily yields to sub-editors
/// (text, slider, confirm, etc.) when a field is selected, then resumes.
/// This avoids rendering artifacts from multiple prompt sessions.
///
/// If any field is a [ThemeConfigurable], changing it updates the editor's
/// own theme in real time -- the frame, icons, and hints re-render immediately
/// with the newly selected palette.
///
/// Groups ([GroupConfigurable]) appear alongside regular fields and open a
/// nested editor on Enter. Only the root level shows a "✓ Save & confirm"
/// action; nested editors show "← Back" instead.
///
/// Controls:
/// - ↑ / ↓ navigate through fields
/// - / toggles search filter
/// - Enter opens the editor for the focused field (or enters a group)
/// - Select "✓ Save & confirm" to return the result
/// - Esc / Ctrl+C cancels (returns `null`)
///
/// ```dart
/// final result = terminice.configEditor(
///   title: 'App Settings',
///   fields: [
///     ThemeConfigurable(key: 'theme', label: 'Theme', value: 'dark'),
///     BoolConfigurable(key: 'darkMode', label: 'Dark Mode', value: true),
///     GroupConfigurable(
///       key: 'network',
///       label: 'Network',
///       children: [
///         StringConfigurable(key: 'host', label: 'Host', value: 'localhost'),
///         NumberConfigurable(key: 'port', label: 'Port', value: 8080),
///       ],
///     ),
///   ],
/// );
/// ```
extension ConfigEditorExtensions on Terminice {
  /// Opens a config editor for the given [fields].
  ///
  /// Returns a [ConfigResult] on confirmation, or `null` if cancelled.
  ConfigResult? configEditor({
    required String title,
    required List<Configurable> fields,
    int maxVisible = 18,
  }) {
    if (fields.isEmpty) {
      return ConfigResult(fields: fields, confirmed: true);
    }

    final confirmed = runEditorLoop(
      terminice: this,
      title: title,
      fields: fields,
      isRoot: true,
      maxVisible: maxVisible,
    );

    if (!confirmed) return null;
    return ConfigResult(fields: fields, confirmed: true);
  }
}
