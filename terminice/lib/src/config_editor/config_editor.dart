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
///   'App Settings',
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
  ConfigResult? configEditor(
    String prompt, {
    required List<Configurable> fields,
    int maxVisible = 18,
  }) {
    if (fields.isEmpty) {
      return ConfigResult(fields: fields, confirmed: true);
    }

    return runWithExecutionMode<ConfigResult?>(
      rich: () {
        final confirmed = runRichEditorLoop(
          terminice: this,
          title: prompt,
          fields: fields,
          isRoot: true,
          maxVisible: maxVisible,
        );
        if (!confirmed) return null;
        return ConfigResult(fields: fields, confirmed: true);
      },
      line: () {
        final transaction = _ConfigTransaction.capture(fields);
        final confirmed = runLineEditorLoop(
          terminice: this,
          title: prompt,
          fields: fields,
          isRoot: true,
        );
        if (!confirmed) {
          transaction.restore();
          return null;
        }
        return ConfigResult(fields: fields, confirmed: true);
      },
      // Current values are safe to snapshot only when validation is already
      // complete; unattended execution cannot ask the user to resolve errors.
      unattended: () => firstEditorValidationError(fields) == null
          ? ConfigResult(fields: fields, confirmed: true)
          : null,
    );
  }
}

class _ConfigTransaction {
  _ConfigTransaction._(this._fields, this._values);

  final List<Configurable> _fields;
  final List<dynamic> _values;

  factory _ConfigTransaction.capture(List<Configurable> fields) {
    return _ConfigTransaction._(
      fields,
      fields.map((field) => _copyConfigValue(field.toJsonValue())).toList(),
    );
  }

  void restore() {
    for (var i = 0; i < _fields.length; i++) {
      _fields[i].loadJsonValue(_copyConfigValue(_values[i]));
    }
  }
}

dynamic _copyConfigValue(dynamic value) {
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key.toString(): _copyConfigValue(entry.value),
    };
  }
  if (value is List) return value.map(_copyConfigValue).toList();
  return value;
}
