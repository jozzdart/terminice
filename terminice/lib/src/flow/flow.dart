import 'dart:collection';

import 'package:terminice_core/terminice_core.dart'
    show normalizeValidationError;

import '../core/terminice_api.dart';
import '../prompts/confirm.dart';
import '../prompts/password.dart';
import '../prompts/text.dart';
import '../selectors/checkbox_selector.dart';
import '../selectors/search_selector.dart';

part 'flow_result.dart';
part 'flow_step.dart';

/// Flow helpers for running a sequence of synchronous Terminice steps.
extension TerminiceFlowExtensions on Terminice {
  /// Creates a synchronous flow with a human-readable [title].
  FlowBuilder flow(String title) => FlowBuilder._(this, title);
}

/// Builds and runs a synchronous Terminice flow.
class FlowBuilder {
  final Terminice _terminice;
  final List<_FlowStep> _steps = <_FlowStep>[];
  final Map<String, String> _stepLabelsByKey = <String, String>{};

  FlowBuilder._(this._terminice, this.title);

  /// Human-readable title for this flow.
  final String title;

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
  }) {
    _addStep(
      _CustomFlowStep<T>(
        key: key,
        label: label,
        run: run,
        validate: validate,
        when: when,
        cancelOnNull: cancelOnNull,
      ),
    );
    return this;
  }

  void _addStep(_FlowStep step) {
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
  }) {
    return custom<String>(
      key,
      prompt,
      run: (_) => _terminice.text(
        prompt,
        placeholder: placeholder,
        required: required,
        validator: validator,
      ),
      validate: validate,
      when: when,
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
  }) {
    return custom<String>(
      key,
      prompt,
      run: (_) => _terminice.password(
        prompt,
        required: required,
        maskChar: maskChar,
        allowReveal: allowReveal,
        verify: verify,
      ),
      validate: validate,
      when: when,
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
  }) {
    final optionLabels = _FlowOptionLabels<T>(
      options,
      labelBuilder: labelBuilder,
    );

    return custom<T?>(
      key,
      prompt,
      run: (_) {
        final selected = _terminice.searchSelector(
          options: optionLabels.labels,
          prompt: prompt,
          showSearch: showSearch,
          maxVisible: maxVisible,
        );
        if (selected.isEmpty) return null;
        return optionLabels.valueFor(selected.first);
      },
      validate: validate,
      when: when,
      cancelOnNull: false,
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
  }) {
    final optionLabels = _FlowOptionLabels<T>(
      options,
      labelBuilder: labelBuilder,
    );

    return custom<List<T>>(
      key,
      prompt,
      run: (_) {
        final selected = _terminice.checkboxSelector(
          prompt,
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
  }) {
    return custom<bool>(
      key,
      prompt,
      run: (_) => _terminice.confirm(
        prompt: prompt,
        message: message,
        yesLabel: yesLabel,
        noLabel: noLabel,
        defaultYes: defaultYes,
      ),
      validate: validate,
      when: when,
    );
  }

  /// Runs the flow from the first step to the last.
  FlowResult run() {
    final values = <String, Object?>{};

    for (final step in _steps) {
      final context = FlowContext._(
        terminice: _terminice,
        values: values,
      );

      _terminice.activate();
      if (!step.shouldRun(context)) continue;

      _terminice.activate();
      final value = step.run(context);

      if (value == null && step.cancelOnNull) {
        return FlowResult._cancelled(
          values,
          cancelledKey: step.key,
        );
      }

      _terminice.activate();
      final validationError = step.validationErrorFor(value, context);
      if (validationError != null) {
        throw FlowValidationException(
          key: step.key,
          label: step.label,
          message: validationError,
        );
      }

      values[step.key] = value;
    }

    return FlowResult._confirmed(values);
  }
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
