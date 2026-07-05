part of 'flow.dart';

enum _FlowReviewAction {
  submit,
  edit,
  cancel,
}

class _FlowReview {
  _FlowReview({
    required Terminice terminice,
    required String flowTitle,
    required List<_FlowStep<dynamic>> steps,
    required FlowReviewOptions options,
  })  : _terminice = terminice,
        _flowTitle = flowTitle,
        _steps = steps,
        _options = options;

  final Terminice _terminice;
  final String _flowTitle;
  final List<_FlowStep<dynamic>> _steps;
  final FlowReviewOptions _options;

  _FlowReviewAction chooseAction(_FlowRunState state) {
    final items = _buildItems(state);
    _writeSummary(items);

    final optionsByLabel = _reviewActionOptions();
    final selected = _terminice.searchSelector(
      options: optionsByLabel.keys.toList(growable: false),
      prompt: _reviewTitle,
      showSearch: false,
      maxVisible: 3,
    );

    if (selected.isEmpty) return _FlowReviewAction.cancel;
    return optionsByLabel[selected.first] ?? _FlowReviewAction.cancel;
  }

  int? chooseEditStartIndex(_FlowRunState state) {
    final editableItems =
        _buildItems(state).where((item) => item.summary.editable).toList(
              growable: false,
            );

    if (editableItems.isEmpty) {
      _writeLine('No editable review items.');
      return null;
    }

    final optionLabels = <String>['Back'];
    final itemByLabel = <String, _FlowReviewItem>{};
    final totals = <String, int>{};
    final seen = <String, int>{};
    final usedLabels = <String>{'Back'};

    for (final item in editableItems) {
      final label = _reviewItemOptionLabel(item.summary);
      totals[label] = (totals[label] ?? 0) + 1;
    }

    for (final item in editableItems) {
      final label = _uniqueFlowLabel(
        _reviewItemOptionLabel(item.summary),
        totals: totals,
        seen: seen,
        usedLabels: usedLabels,
      );
      optionLabels.add(label);
      itemByLabel[label] = item;
    }

    final selected = _terminice.searchSelector(
      options: optionLabels,
      prompt: 'Edit review item',
      showSearch: true,
      maxVisible: 10,
    );

    if (selected.isEmpty || selected.first == 'Back') return null;
    return itemByLabel[selected.first]?.stepIndex;
  }

  String get _reviewTitle => _options.title ?? 'Review $_flowTitle';

  List<_FlowReviewItem> _buildItems(_FlowRunState state) {
    return _FlowReviewItems.build(
      steps: _steps,
      state: state,
      terminice: _terminice,
      reviewSummaryFor: (step, value, context) {
        return _withActiveReviewTerminal(
          () => step.reviewSummaryFor(value, context),
        );
      },
    );
  }

  T _withActiveReviewTerminal<T>(T Function() body) {
    _terminice.activate();
    try {
      return body();
    } finally {
      _terminice.activate();
    }
  }

  void _writeSummary(List<_FlowReviewItem> items) {
    _writeLine(_reviewTitle);

    if (items.isEmpty) {
      _writeLine('(no review items)');
      return;
    }

    for (final item in items) {
      _writeLine(_reviewItemOptionLabel(item.summary));
    }
  }

  void _writeLine(Object? object) {
    _terminice.activate();
    TerminalContext.output.writeln(object);
  }

  Map<String, _FlowReviewAction> _reviewActionOptions() {
    final labels = <String>[
      _options.submitLabel,
      if (_options.allowEdit) _options.editLabel,
      _options.cancelLabel,
    ];
    final actions = <_FlowReviewAction>[
      _FlowReviewAction.submit,
      if (_options.allowEdit) _FlowReviewAction.edit,
      _FlowReviewAction.cancel,
    ];

    final totals = <String, int>{};
    final seen = <String, int>{};
    final usedLabels = <String>{};
    for (final label in labels) {
      totals[label] = (totals[label] ?? 0) + 1;
    }

    final options = <String, _FlowReviewAction>{};
    for (var i = 0; i < labels.length; i++) {
      final label = _uniqueFlowLabel(
        labels[i],
        totals: totals,
        seen: seen,
        usedLabels: usedLabels,
      );
      options[label] = actions[i];
    }

    return options;
  }
}

class _FlowReviewItems {
  _FlowReviewItems._();

  static List<_FlowReviewItem> build({
    required List<_FlowStep<dynamic>> steps,
    required _FlowRunState state,
    required Terminice terminice,
    required String? Function(
      _FlowStep<dynamic> step,
      Object? value,
      FlowContext context,
    ) reviewSummaryFor,
  }) {
    final items = <_FlowReviewItem>[];

    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      if (!step.includeInReview || !state.values.containsKey(step.key)) {
        continue;
      }

      final context = state.contextFor(terminice);
      final value = state.values[step.key];
      final summary = reviewSummaryFor(step, value, context) ??
          _defaultReviewSummary(value);

      items.add(
        _FlowReviewItem(
          stepIndex: i,
          summary: FlowSummaryItem(
            key: step.key,
            label: step.reviewLabel ?? step.label,
            value: value,
            summary: summary,
            editable: step.editable,
          ),
        ),
      );
    }

    return items;
  }
}

class _FlowReviewItem {
  const _FlowReviewItem({
    required this.stepIndex,
    required this.summary,
  });

  final int stepIndex;
  final FlowSummaryItem summary;
}

String _reviewItemOptionLabel(FlowSummaryItem item) {
  final summary = item.summary;
  if (summary == null || summary.isEmpty) return item.label;
  return '${item.label}: $summary';
}

String _defaultReviewSummary(Object? value) {
  if (value == null) return 'none';
  if (value is String) return value.isEmpty ? '(empty)' : value;
  if (value is Iterable) {
    final values = value.map((item) => item.toString()).toList();
    if (values.isEmpty) return 'none';
    return values.join(', ');
  }
  return value.toString();
}

String _maskedPasswordSummary(
  String value, {
  required String maskChar,
}) {
  if (value.isEmpty) return '(empty)';
  final mask = maskChar.isEmpty ? '*' : maskChar;
  return List<String>.filled(8, mask).join();
}
