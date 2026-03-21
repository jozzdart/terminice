import 'package:terminice/terminice.dart';

import '../editor_loop.dart';

/// A configurable that groups child fields into a nested editor.
///
/// Appears in the parent editor list with a `▸` icon and a summary of its
/// children (e.g. "5 fields" or "2/5 modified"). Pressing Enter opens a
/// sub-editor scoped to the group's [children], with a "← Back" action
/// instead of "✓ Save & confirm".
///
/// Groups can be nested arbitrarily deep — each level opens its own
/// editor session and returns to the parent on Esc or "← Back".
/// Only the root-level config editor has the save action.
///
/// ```dart
/// GroupConfigurable(
///   key: 'network',
///   label: 'Network',
///   description: 'Connection and proxy settings',
///   children: [
///     StringConfigurable(key: 'host', label: 'Host', value: 'localhost'),
///     NumberConfigurable(key: 'port', label: 'Port', value: 8080),
///     GroupConfigurable(
///       key: 'proxy',
///       label: 'Proxy',
///       children: [
///         BoolConfigurable(key: 'enabled', label: 'Enabled', value: false),
///         StringConfigurable(key: 'url', label: 'URL', value: ''),
///       ],
///     ),
///   ],
/// )
/// ```
class GroupConfigurable extends Configurable<Map<String, dynamic>> {
  /// The child fields managed by this group.
  final List<Configurable> children;

  GroupConfigurable({
    required super.key,
    required super.label,
    required this.children,
    super.description,
    super.hint,
    super.icon,
  }) : super(value: const {});

  @override
  String get defaultTypeIcon => '⊞';

  @override
  Map<String, dynamic> get value =>
      {for (final c in children) c.key: c.toJsonValue()};

  @override
  String get displayValue {
    final total = children.length;
    final mod = children.where((c) => c.isModified).length;
    if (mod > 0) return '$mod/$total modified';
    return '$total fields';
  }

  @override
  bool get isModified => children.any((c) => c.isModified);

  @override
  void reset() {
    for (final c in children) {
      c.reset();
    }
  }

  @override
  String? validate() {
    for (final c in children) {
      final error = c.validate();
      if (error != null) return '${c.label}: $error';
    }
    return null;
  }

  @override
  bool edit(Terminice terminice) {
    runEditorLoop(
      terminice: terminice,
      title: label,
      fields: children,
      isRoot: false,
    );
    return isModified;
  }

  @override
  dynamic toJsonValue() => {for (final c in children) c.key: c.toJsonValue()};

  @override
  void loadJsonValue(dynamic jsonValue) {
    if (jsonValue is Map<String, dynamic>) {
      for (final c in children) {
        if (jsonValue.containsKey(c.key)) {
          c.loadJsonValue(jsonValue[c.key]);
        }
      }
    }
  }
}
