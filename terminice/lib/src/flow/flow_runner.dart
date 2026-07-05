part of 'flow.dart';

class _FlowRunner {
  _FlowRunner({
    required Terminice terminice,
    required List<_FlowStep<dynamic>> steps,
    required String flowTitle,
    required FlowReviewOptions? reviewOptions,
    required FlowProgressOptions? progressOptions,
  })  : _terminice = terminice,
        _steps = steps,
        _flowTitle = flowTitle,
        _reviewOptions = reviewOptions,
        _progress = _FlowProgressFormatter.fromOptions(progressOptions);

  final Terminice _terminice;
  final List<_FlowStep<dynamic>> _steps;
  final String _flowTitle;
  final FlowReviewOptions? _reviewOptions;
  final _FlowProgressFormatter? _progress;

  FlowResult run() {
    final state = _FlowRunState();
    final cancelledKey = _runFrom(0, state);

    if (cancelledKey != null) {
      return FlowResult._cancelled(
        state.values,
        cancelledKey: cancelledKey,
      );
    }

    final reviewOptions = _reviewOptions;
    if (reviewOptions != null) {
      return _runReviewLoop(state, reviewOptions);
    }

    return FlowResult._confirmed(state.values);
  }

  String? _runFrom(int startIndex, _FlowRunState state) {
    state.truncateFrom(startIndex, _steps);

    for (final step in _stepsFrom(startIndex)) {
      final cancelledKey = _runStep(step, state);
      if (cancelledKey != null) return cancelledKey;
    }

    return null;
  }

  Iterable<_FlowStep<dynamic>> _stepsFrom(int startIndex) {
    if (startIndex == 0) return _steps;
    return _steps.skip(startIndex);
  }

  String? _runStep(_FlowStep<dynamic> step, _FlowRunState state) {
    final context = state.contextFor(
      _terminice,
      progress: _progress,
      stepIndex: _steps.indexOf(step),
      stepCount: _steps.length,
    );

    if (!_withActiveFlowTerminal(() => step.shouldRun(context))) return null;

    final value = _withActiveFlowTerminal(() => step.run(context));

    if (value == null && step.cancelOnNull) return step.key;

    final validationError = _withActiveFlowTerminal(
      () => step.validationErrorFor(value, context),
    );
    if (validationError != null) {
      throw FlowValidationException(
        key: step.key,
        label: step.label,
        message: validationError,
      );
    }

    state.values[step.key] = value;
    return null;
  }

  T _withActiveFlowTerminal<T>(T Function() body) {
    _terminice.activate();
    try {
      return body();
    } finally {
      _terminice.activate();
    }
  }

  FlowResult _runReviewLoop(
    _FlowRunState state,
    FlowReviewOptions reviewOptions,
  ) {
    final review = _FlowReview(
      terminice: _terminice,
      flowTitle: _flowTitle,
      steps: _steps,
      options: reviewOptions,
    );

    while (true) {
      switch (review.chooseAction(state)) {
        case _FlowReviewAction.submit:
          return FlowResult._confirmed(state.values);
        case _FlowReviewAction.cancel:
          return FlowResult._cancelled(state.values, cancelledKey: null);
        case _FlowReviewAction.edit:
          final startIndex = review.chooseEditStartIndex(state);
          if (startIndex == null) continue;
          _runEditFrom(startIndex, state);
      }
    }
  }

  void _runEditFrom(int startIndex, _FlowRunState state) {
    final snapshot = state.snapshot();
    final cancelledKey = _runFrom(startIndex, state);
    if (cancelledKey == null) return;
    state.replaceWith(snapshot);
  }
}

class _FlowRunState {
  _FlowRunState([Map<String, Object?>? values])
      : values =
            values == null ? <String, Object?>{} : <String, Object?>{...values};

  final Map<String, Object?> values;

  void truncateFrom(int startIndex, List<_FlowStep<dynamic>> steps) {
    for (final step in steps.skip(startIndex)) {
      values.remove(step.key);
    }
  }

  Map<String, Object?> snapshot() => _orderedCopy(values);

  void replaceWith(Map<String, Object?> snapshot) {
    values
      ..clear()
      ..addAll(snapshot);
  }

  FlowContext contextFor(
    Terminice terminice, {
    _FlowProgressFormatter? progress,
    int? stepIndex,
    int? stepCount,
  }) {
    return FlowContext._(
      terminice: terminice,
      values: values,
      progress: progress,
      stepIndex: stepIndex,
      stepCount: stepCount,
    );
  }
}

class _FlowProgressFormatter {
  const _FlowProgressFormatter(this._options);

  final FlowProgressOptions _options;

  static _FlowProgressFormatter? fromOptions(FlowProgressOptions? options) {
    if (options == null) return null;
    return _FlowProgressFormatter(options);
  }

  String titleFor(String title, {required int index, required int total}) {
    switch (_options.style) {
      case FlowProgressStyle.title:
        return 'Step ${index + 1}/$total - $title';
    }
  }
}
