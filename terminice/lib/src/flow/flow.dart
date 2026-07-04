import 'dart:collection';

import 'package:terminice_core/terminice_core.dart'
    show TerminalContext, normalizeValidationError;

import '../core/terminice_api.dart';
import '../prompts/confirm.dart';
import '../prompts/password.dart';
import '../prompts/text.dart';
import '../selectors/checkbox_selector.dart';
import '../selectors/search_selector.dart';

part 'flow_result.dart';
part 'flow_review.dart';
part 'flow_runner.dart';
part 'flow_step.dart';

/// Flow helpers for running a sequence of synchronous Terminice steps.
extension TerminiceFlowExtensions on Terminice {
  /// Creates a synchronous flow with a human-readable [title].
  FlowBuilder flow(String title) => FlowBuilder._(this, title);
}

/// Progress display styles supported by flow metadata.
enum FlowProgressStyle {
  /// Display progress by updating the flow title.
  title,
}

/// Review screen options used by [FlowBuilder.review].
class FlowReviewOptions {
  /// Creates review metadata for a flow.
  const FlowReviewOptions({
    this.title,
    this.submitLabel = 'Submit',
    this.editLabel = 'Edit',
    this.cancelLabel = 'Cancel',
    this.allowEdit = true,
  });

  /// Optional title displayed by the review screen.
  final String? title;

  /// Label for the review submit action.
  final String submitLabel;

  /// Label for the review edit action.
  final String editLabel;

  /// Label for the review cancel action.
  final String cancelLabel;

  /// Whether the review screen should allow editing collected values.
  final bool allowEdit;
}

/// Progress display options used by [FlowBuilder.progress].
class FlowProgressOptions {
  /// Creates progress metadata for a flow.
  const FlowProgressOptions({
    this.style = FlowProgressStyle.title,
  });

  /// Progress display style requested for this flow.
  final FlowProgressStyle style;
}

/// Builds and runs a synchronous Terminice flow.
class FlowBuilder {
  final Terminice _terminice;
  final List<_FlowStep<dynamic>> _steps = <_FlowStep<dynamic>>[];
  final Map<String, String> _stepLabelsByKey = <String, String>{};
  FlowReviewOptions? _reviewOptions;
  FlowProgressOptions? _progressOptions;

  FlowBuilder._(this._terminice, this.title);

  /// Human-readable title for this flow.
  final String title;

  /// Review options configured for this flow.
  FlowReviewOptions? get reviewOptions => _reviewOptions;

  /// Progress options configured for this flow.
  FlowProgressOptions? get progressOptions => _progressOptions;

  /// Includes reusable steps declared by [template].
  ///
  /// The template runs immediately and uses the same duplicate-key validation
  /// as steps added directly to this builder.
  FlowBuilder include(FlowTemplate template) {
    template(this);
    return this;
  }

  /// Enables a review screen after all applicable steps complete.
  FlowBuilder review({
    String? title,
    String submitLabel = 'Submit',
    String editLabel = 'Edit',
    String cancelLabel = 'Cancel',
    bool allowEdit = true,
  }) {
    _reviewOptions = FlowReviewOptions(
      title: title,
      submitLabel: submitLabel,
      editLabel: editLabel,
      cancelLabel: cancelLabel,
      allowEdit: allowEdit,
    );
    return this;
  }

  /// Enables progress labels for built-in flow prompts.
  FlowBuilder progress({
    FlowProgressStyle style = FlowProgressStyle.title,
  }) {
    _progressOptions = FlowProgressOptions(style: style);
    return this;
  }

  /// Adds a custom synchronous step to the flow.
  ///
  /// Returning `null` cancels the flow by default. Set [cancelOnNull] to
  /// `false` to store `null` for [key] and continue.
  FlowBuilder custom<T>(
    String key,
    String label, {
    required FlowStepRunner<T> run,
    FlowValidator<T>? validate,
    FlowCondition? when,
    bool cancelOnNull = true,
    String? reviewLabel,
    FlowSummary<T>? summarize,
    bool includeInReview = false,
    bool editable = false,
  }) {
    _addStep(
      _CustomFlowStep<T>(
        key: key,
        label: label,
        run: run,
        validate: validate,
        when: when,
        cancelOnNull: cancelOnNull,
        reviewLabel: reviewLabel,
        summarize: summarize,
        includeInReview: includeInReview,
        editable: editable,
      ),
    );
    return this;
  }

  void _addStep(_FlowStep<dynamic> step) {
    if (step.key.trim().isEmpty) {
      throw ArgumentError.value(
        step.key,
        'key',
        'Flow step key must not be empty.',
      );
    }

    if (_stepLabelsByKey.containsKey(step.key)) {
      final existingLabel = _stepLabelsByKey[step.key]!;
      throw ArgumentError.value(
        step.key,
        'key',
        "Flow '$title' already contains step key '${step.key}' "
            "for '$existingLabel'. Duplicate label: '${step.label}'.",
      );
    }

    _steps.add(step);
    _stepLabelsByKey[step.key] = step.label;
  }

  /// Adds a text prompt step to the flow.
  ///
  /// [validator] runs inside the prompt for immediate per-input validation.
  /// [validate] runs after the step completes and can inspect earlier flow
  /// values through [FlowContext].
  FlowBuilder text(
    String key,
    String prompt, {
    String? placeholder,
    bool required = true,
    String? Function(String)? validator,
    FlowValidator<String>? validate,
    FlowCondition? when,
    String? reviewLabel,
    FlowSummary<String>? summarize,
    bool includeInReview = true,
    bool editable = true,
  }) {
    return custom<String>(
      key,
      prompt,
      run: (context) => _terminice.text(
        context._promptTitle(prompt),
        placeholder: placeholder,
        required: required,
        validator: validator,
      ),
      validate: validate,
      when: when,
      reviewLabel: reviewLabel,
      summarize: summarize,
      includeInReview: includeInReview,
      editable: editable,
    );
  }

  /// Adds a password prompt step to the flow.
  ///
  /// [validate] runs after the step completes and can inspect earlier flow
  /// values through [FlowContext].
  FlowBuilder password(
    String key,
    String prompt, {
    bool required = true,
    String maskChar = '•',
    bool allowReveal = true,
    bool verify = false,
    FlowValidator<String>? validate,
    FlowCondition? when,
    String? reviewLabel,
    FlowSummary<String>? summarize,
    bool includeInReview = true,
    bool editable = true,
  }) {
    return custom<String>(
      key,
      prompt,
      run: (context) => _terminice.password(
        context._promptTitle(prompt),
        required: required,
        maskChar: maskChar,
        allowReveal: allowReveal,
        verify: verify,
      ),
      validate: validate,
      when: when,
      reviewLabel: reviewLabel,
      summarize: summarize ??
          (value, _) => _maskedPasswordSummary(value, maskChar: maskChar),
      includeInReview: includeInReview,
      editable: editable,
    );
  }

  /// Adds a single-select step to the flow and stores the selected option.
  ///
  /// If the selector returns no selection, the step stores `null` and the flow
  /// continues. Use [validate] to reject `null` when a selection is required.
  FlowBuilder select<T>(
    String key,
    String prompt, {
    required List<T> options,
    String Function(T value)? labelBuilder,
    bool showSearch = true,
    int maxVisible = 10,
    FlowValidator<T?>? validate,
    FlowCondition? when,
    String? reviewLabel,
    FlowSummary<T?>? summarize,
    bool includeInReview = true,
    bool editable = true,
  }) {
    final optionLabels = _FlowOptionLabels<T>(
      options,
      labelBuilder: labelBuilder,
    );

    return custom<T?>(
      key,
      prompt,
      run: (context) {
        final selected = _terminice.searchSelector(
          options: optionLabels.labels,
          prompt: context._promptTitle(prompt),
          showSearch: showSearch,
          maxVisible: maxVisible,
        );
        if (selected.isEmpty) return null;
        return optionLabels.valueFor(selected.first);
      },
      validate: validate,
      when: when,
      cancelOnNull: false,
      reviewLabel: reviewLabel,
      summarize: summarize,
      includeInReview: includeInReview,
      editable: editable,
    );
  }

  /// Adds a multi-select checkbox step to the flow.
  ///
  /// The stored list is unmodifiable so result and context snapshots cannot
  /// mutate the flow's collected checkbox value.
  FlowBuilder checkboxes<T>(
    String key,
    String prompt, {
    required List<T> options,
    Set<int>? initialSelected,
    String Function(T value)? labelBuilder,
    int maxVisible = 12,
    FlowValidator<List<T>>? validate,
    FlowCondition? when,
    String? reviewLabel,
    FlowSummary<List<T>>? summarize,
    bool includeInReview = true,
    bool editable = true,
  }) {
    final optionLabels = _FlowOptionLabels<T>(
      options,
      labelBuilder: labelBuilder,
    );

    return custom<List<T>>(
      key,
      prompt,
      run: (context) {
        final selected = _terminice.checkboxSelector(
          context._promptTitle(prompt),
          options: optionLabels.labels,
          initialSelected: initialSelected,
          maxVisible: maxVisible,
        );
        final values = <T>[];
        for (final label in selected) {
          values.add(optionLabels.valueFor(label));
        }
        return List<T>.unmodifiable(values);
      },
      validate: validate,
      when: when,
      reviewLabel: reviewLabel,
      summarize: summarize,
      includeInReview: includeInReview,
      editable: editable,
    );
  }

  /// Adds a confirmation step to the flow.
  FlowBuilder confirm(
    String key, {
    String prompt = 'Confirm',
    required String message,
    String yesLabel = 'Yes',
    String noLabel = 'No',
    bool defaultYes = true,
    FlowValidator<bool>? validate,
    FlowCondition? when,
    String? reviewLabel,
    FlowSummary<bool>? summarize,
    bool includeInReview = true,
    bool editable = true,
  }) {
    return custom<bool>(
      key,
      prompt,
      run: (context) => _terminice.confirm(
        prompt: context._promptTitle(prompt),
        message: context._fallbackPromptTitle(message),
        yesLabel: yesLabel,
        noLabel: noLabel,
        defaultYes: defaultYes,
      ),
      validate: validate,
      when: when,
      reviewLabel: reviewLabel,
      summarize: summarize,
      includeInReview: includeInReview,
      editable: editable,
    );
  }

  /// Runs the flow from the first step to the last.
  FlowResult run() => _FlowRunner(
        terminice: _terminice,
        steps: _steps,
        flowTitle: title,
        reviewOptions: _reviewOptions,
        progressOptions: _progressOptions,
      ).run();
}

class _FlowOptionLabels<T> {
  _FlowOptionLabels(
    List<T> options, {
    required String Function(T value)? labelBuilder,
  }) {
    final baseLabels = <String>[];
    final totals = <String, int>{};

    for (final option in options) {
      final label = _flowOptionLabel(option, labelBuilder);
      baseLabels.add(label);
      totals[label] = (totals[label] ?? 0) + 1;
    }

    final seen = <String, int>{};
    final usedLabels = <String>{};
    for (var i = 0; i < options.length; i++) {
      final label = _uniqueFlowLabel(
        baseLabels[i],
        totals: totals,
        seen: seen,
        usedLabels: usedLabels,
      );
      labels.add(label);
      _valuesByLabel[label] = options[i];
    }
  }

  final List<String> labels = <String>[];
  final Map<String, T> _valuesByLabel = <String, T>{};

  T valueFor(String label) {
    if (!_valuesByLabel.containsKey(label)) {
      throw StateError("Flow option '$label' was not found.");
    }
    return _valuesByLabel[label] as T;
  }
}

String _flowOptionLabel<T>(
  T value,
  String Function(T value)? labelBuilder,
) {
  final label = labelBuilder == null ? value.toString() : labelBuilder(value);
  return label;
}

String _uniqueFlowLabel(
  String baseLabel, {
  required Map<String, int> totals,
  required Map<String, int> seen,
  required Set<String> usedLabels,
}) {
  final total = totals[baseLabel] ?? 0;
  var label = baseLabel;

  if (total > 1) {
    final index = (seen[baseLabel] ?? 0) + 1;
    seen[baseLabel] = index;
    label = '$baseLabel ($index)';
  } else {
    seen[baseLabel] = 1;
  }

  if (usedLabels.add(label)) return label;

  var suffix = 2;
  var uniqueLabel = '$label ($suffix)';
  while (!usedLabels.add(uniqueLabel)) {
    suffix++;
    uniqueLabel = '$label ($suffix)';
  }
  return uniqueLabel;
}
