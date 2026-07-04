import '../io/terminal_context.dart';
import 'validator_semantics.dart';

/// Validator for fallback text input.
///
/// Return `null` for success, or a non-empty error message to ask again.
/// Returning `''` is also accepted as success for backwards compatibility.
typedef FallbackTextValidator = String? Function(String value);

/// Validator for fallback numeric input.
///
/// Return `null` for success, or a non-empty error message to ask again.
/// Returning `''` is also accepted as success for backwards compatibility.
typedef FallbackNumberValidator = String? Function(num value);

/// Builds a display label for a selectable fallback item.
typedef FallbackLabelBuilder<T> = String Function(T item);

/// Result returned by [FallbackPrompt.range].
class FallbackRangeResult {
  /// Ordered lower value for the accepted range.
  final num start;

  /// Ordered upper value for the accepted range.
  final num end;

  /// Creates a range result with an ordered [start] and [end].
  const FallbackRangeResult({
    required this.start,
    required this.end,
  });
}

/// Field configuration used by [FallbackPrompt.form].
class FallbackFormField {
  /// Label shown before the line-mode input prompt.
  final String label;

  /// Optional helper text included in the prompt label.
  final String? placeholder;

  /// Whether this field represents masked input in rich prompts.
  ///
  /// The fallback stays in line mode, so masked input is still visible while
  /// typed. The generated prompt label calls out that caveat.
  final bool masked;

  /// Character used by rich prompts to mask input.
  ///
  /// Line-mode fallback input does not render masks, but keeping this field in
  /// the config allows callers to map richer field configs without losing
  /// intent.
  final String maskChar;

  /// Whether richer prompts may reveal masked input.
  ///
  /// Line-mode fallback input is always visible while typed.
  final bool allowReveal;

  /// Whether the field must be non-empty.
  final bool required;

  /// Per-field validator. Return `null` for success or an error message.
  /// Returning `''` is also accepted as success for backwards compatibility.
  final FallbackTextValidator? validator;

  /// Optional initial value used when the user submits an empty line.
  final String? initialValue;

  /// Creates a fallback form field.
  const FallbackFormField({
    required this.label,
    this.placeholder,
    this.masked = false,
    this.maskChar = '•',
    this.allowReveal = false,
    this.required = false,
    this.validator,
    this.initialValue,
  });
}

/// Result returned by [FallbackPrompt.form].
class FallbackFormResult {
  /// Accepted field values in declaration order.
  final List<String> values;

  /// Creates a fallback form result.
  const FallbackFormResult(this.values);

  /// Returns the value at [index].
  String operator [](int index) => values[index];

  /// Number of accepted field values.
  int get length => values.length;
}

/// Line-mode prompt primitives for limited terminal environments.
///
/// These helpers only use [TerminalContext.input.readLineSync],
/// [TerminalContext.output.write], and [TerminalContext.output.writeln]. They
/// do not enter raw mode, hide the cursor, clear the screen, or emit ANSI
/// sequences.
class FallbackPrompt {
  FallbackPrompt._();

  /// Reads a line of text.
  ///
  /// Returns the trimmed input, [defaultValue] for empty input when provided,
  /// or [defaultValue] on end-of-input unless [returnDefaultOnEndOfInput] is
  /// `false`. Validators return `null` for success and a non-empty string for
  /// an error message. Returning `''` is also accepted as success for backwards
  /// compatibility.
  static String? text({
    required String title,
    String? defaultValue,
    bool required = false,
    FallbackTextValidator? validator,
    bool returnDefaultOnEndOfInput = true,
  }) {
    return _readText(
      title: title,
      defaultValue: defaultValue,
      required: required,
      validator: validator,
      returnDefaultOnEndOfInput: returnDefaultOnEndOfInput,
    );
  }

  /// Reads a password using the same line-mode path as [text].
  ///
  /// This fallback deliberately does not disable echo or mask characters.
  /// A plain line read cannot safely hide input across all terminal
  /// implementations. Future terminal implementations may handle hiding
  /// externally before this method reads the line.
  static String? password({
    required String title,
    bool required = true,
    FallbackTextValidator? validator,
    bool returnDefaultOnEndOfInput = true,
  }) {
    return _readText(
      title: title,
      required: required,
      validator: validator,
      returnDefaultOnEndOfInput: returnDefaultOnEndOfInput,
    );
  }

  /// Reads a yes/no answer.
  ///
  /// Empty input and end-of-input return [defaultValue]. Invalid input is
  /// reported and the prompt is shown again.
  static bool confirm({
    required String title,
    bool defaultValue = false,
  }) {
    while (true) {
      final suffix = defaultValue ? '[Y/n]' : '[y/N]';
      TerminalContext.output.write('$title $suffix: ');

      final line = TerminalContext.input.readLineSync();
      if (line == null) return defaultValue;

      final value = line.trim().toLowerCase();
      if (value.isEmpty) return defaultValue;

      if (value == 'y' || value == 'yes' || value == 'true' || value == '1') {
        return true;
      }
      if (value == 'n' || value == 'no' || value == 'false' || value == '0') {
        return false;
      }

      _writeError('Enter yes or no.');
    }
  }

  /// Reads a one-based single selection.
  ///
  /// [defaultIndex] is zero-based. Empty input returns that default item when
  /// it is in range, otherwise `null`. End-of-input follows the same policy
  /// unless [returnDefaultOnEndOfInput] is `false`, in which case it returns
  /// `null`.
  static T? singleSelect<T>({
    required String title,
    required List<T> options,
    int? defaultIndex = 0,
    FallbackLabelBuilder<T>? labelBuilder,
    bool returnDefaultOnEndOfInput = true,
  }) {
    if (options.isEmpty) return null;

    final normalizedDefault = _normalizeDefaultIndex(
      defaultIndex,
      options.length,
    );

    while (true) {
      _writeOptions(title, options, labelBuilder);

      final suffix =
          normalizedDefault == null ? '' : ' [${normalizedDefault + 1}]';
      TerminalContext.output.write(
        'Select 1-${options.length}$suffix: ',
      );

      final line = TerminalContext.input.readLineSync();
      if (line == null) {
        return returnDefaultOnEndOfInput
            ? normalizedDefault == null
                ? null
                : options[normalizedDefault]
            : null;
      }
      if (line.trim().isEmpty) {
        return normalizedDefault == null ? null : options[normalizedDefault];
      }

      final selected = int.tryParse(line.trim());
      if (selected != null && selected >= 1 && selected <= options.length) {
        return options[selected - 1];
      }

      _writeError('Enter a number from 1 to ${options.length}.');
    }
  }

  /// Reads one-based multi-selection input.
  ///
  /// [defaultIndices] and [fallbackIndex] are zero-based. Input may be comma or
  /// whitespace separated, for example `1, 3` or `1 3`. Empty input returns
  /// the default items when any valid defaults are present, otherwise the
  /// fallback item when [fallbackIndex] is in range. End-of-input follows the
  /// same policy unless [returnDefaultOnEndOfInput] is `false`, in which case
  /// it returns an empty list.
  static List<T> multiSelect<T>({
    required String title,
    required List<T> options,
    Set<int>? defaultIndices,
    int? fallbackIndex,
    FallbackLabelBuilder<T>? labelBuilder,
    bool returnDefaultOnEndOfInput = true,
  }) {
    if (options.isEmpty) return <T>[];

    final defaults = _normalizeDefaultIndices(defaultIndices, options.length);
    final fallbackDefault = _normalizeDefaultIndex(
      fallbackIndex,
      options.length,
    );
    final emptyInputSelection = _defaultOrFallbackIndices(
      defaults,
      fallbackDefault,
    );

    while (true) {
      _writeOptions(title, options, labelBuilder);

      final suffix = emptyInputSelection.isEmpty
          ? ''
          : ' [${emptyInputSelection.map((i) => i + 1).join(', ')}]';
      TerminalContext.output.write('Select one or more$suffix: ');

      final line = TerminalContext.input.readLineSync();
      if (line == null) {
        return returnDefaultOnEndOfInput
            ? _itemsAt(options, emptyInputSelection)
            : <T>[];
      }
      if (line.trim().isEmpty) {
        return _itemsAt(options, emptyInputSelection);
      }

      final indices = _parseSelectionIndices(line, options.length);
      if (indices != null) {
        return _itemsAt(options, indices);
      }

      _writeError('Enter numbers from 1 to ${options.length}.');
    }
  }

  /// Reads a number.
  ///
  /// Empty input returns [defaultValue]. End-of-input also returns
  /// [defaultValue] unless [returnDefaultOnEndOfInput] is `false`. Invalid
  /// numbers, out-of-range values, and validator errors are reported before
  /// asking again.
  static num? number({
    required String title,
    num? defaultValue,
    num? min,
    num? max,
    FallbackNumberValidator? validator,
    bool returnDefaultOnEndOfInput = true,
  }) {
    while (true) {
      _writePrompt(title, defaultValue: defaultValue?.toString());

      final line = TerminalContext.input.readLineSync();
      if (line == null) {
        return returnDefaultOnEndOfInput ? defaultValue : null;
      }

      final text = line.trim();
      if (text.isEmpty) return defaultValue;

      final value = num.tryParse(text);
      if (value == null) {
        _writeError('Enter a number.');
        continue;
      }
      if (!value.isFinite) {
        _writeError('Enter a finite number.');
        continue;
      }
      if (min != null && value < min) {
        _writeError('Enter a number at least $min.');
        continue;
      }
      if (max != null && value > max) {
        _writeError('Enter a number at most $max.');
        continue;
      }

      final error = _numberValidationError(value, validator);
      if (error != null) {
        _writeError(error);
        continue;
      }

      return value;
    }
  }

  /// Reads an ordered numeric range using the same validation path as [number].
  ///
  /// Start and end are prompted independently. Each accepted input must pass
  /// finite-number parsing, optional [min]/[max] bounds, and [validator].
  /// Defaults are clamped before they are offered. The returned values are
  /// ordered so [FallbackRangeResult.start] is always less than or equal to
  /// [FallbackRangeResult.end].
  static FallbackRangeResult? range({
    required String title,
    String? startTitle,
    String? endTitle,
    num? startDefault,
    num? endDefault,
    num? min,
    num? max,
    FallbackNumberValidator? validator,
    bool returnDefaultOnEndOfInput = true,
  }) {
    final lower = _lowerBound(min, max);
    final upper = _upperBound(min, max);
    final normalizedStartDefault = _clampFiniteDefault(
      startDefault,
      min: lower,
      max: upper,
    );
    final normalizedEndDefault = _clampFiniteDefault(
      endDefault,
      min: lower,
      max: upper,
    );

    final start = number(
      title: startTitle ?? '$title start',
      defaultValue: normalizedStartDefault,
      min: lower,
      max: upper,
      validator: validator,
      returnDefaultOnEndOfInput: returnDefaultOnEndOfInput,
    );
    if (start == null) return null;

    final end = number(
      title: endTitle ?? '$title end',
      defaultValue: normalizedEndDefault,
      min: lower,
      max: upper,
      validator: validator,
      returnDefaultOnEndOfInput: returnDefaultOnEndOfInput,
    );
    if (end == null) return null;

    final ordered = _orderedRange(
      start,
      end,
      min: lower,
      max: upper,
    );
    return FallbackRangeResult(start: ordered.start, end: ordered.end);
  }

  /// Reads a multi-field form in line mode.
  ///
  /// Fields are prompted in order. Per-field validators use the text fallback
  /// convention: return `null` for success or an error message. The optional
  /// [crossValidator] runs after all fields are accepted. Returning `''` from
  /// either validator type is also accepted as success for backwards
  /// compatibility.
  static FallbackFormResult? form({
    required List<FallbackFormField> fields,
    String? Function(List<String> values)? crossValidator,
    bool returnDefaultOnEndOfInput = true,
  }) {
    if (fields.isEmpty) return const FallbackFormResult([]);

    while (true) {
      final values = <String>[];

      for (final field in fields) {
        final value = _readText(
          title: _fallbackFormFieldTitle(field),
          defaultValue: field.masked ? null : _initialFormDefault(field),
          required: field.required,
          validator: field.validator,
          returnDefaultOnEndOfInput: returnDefaultOnEndOfInput,
        );

        if (value == null) return null;
        values.add(value);
      }

      final error = normalizeValidationError(crossValidator?.call(values));
      if (error == null) return FallbackFormResult(values);

      _writeError(error);
    }
  }

  static String? _readText({
    required String title,
    String? defaultValue,
    bool required = false,
    FallbackTextValidator? validator,
    bool returnDefaultOnEndOfInput = true,
  }) {
    while (true) {
      _writePrompt(title, defaultValue: defaultValue);

      final line = TerminalContext.input.readLineSync();
      if (line == null) {
        return returnDefaultOnEndOfInput ? defaultValue : null;
      }

      final value = line.trim();
      if (value.isEmpty && defaultValue != null) return defaultValue;

      if (required && value.isEmpty) {
        _writeError('Input cannot be empty.');
        continue;
      }

      final error = _textValidationError(value, validator);
      if (error != null) {
        _writeError(error);
        continue;
      }

      return value;
    }
  }

  static String? _textValidationError(
    String value,
    FallbackTextValidator? validator,
  ) {
    if (validator == null) return null;

    return normalizeValidationError(validator(value));
  }

  static String? _numberValidationError(
    num value,
    FallbackNumberValidator? validator,
  ) {
    if (validator == null) return null;

    return normalizeValidationError(validator(value));
  }

  static String _fallbackFormFieldTitle(FallbackFormField field) {
    final details = <String>[];
    if (field.placeholder != null && field.placeholder!.isNotEmpty) {
      details.add(field.placeholder!);
    }
    if (field.masked) {
      details.add('masked; input visible in line mode');
    }
    if (details.isEmpty) return field.label;
    return '${field.label} (${details.join(', ')})';
  }

  static String? _initialFormDefault(FallbackFormField field) {
    final initial = field.initialValue;
    if (initial == null || initial.isEmpty) return null;
    return initial;
  }

  static num? _lowerBound(num? min, num? max) {
    if (min == null || max == null) return min;
    return min <= max ? min : max;
  }

  static num? _upperBound(num? min, num? max) {
    if (min == null || max == null) return max;
    return min <= max ? max : min;
  }

  static num? _clampFiniteDefault(num? value, {num? min, num? max}) {
    if (value == null || !value.isFinite) return null;
    return _clampToBounds(value, min: min, max: max);
  }

  static FallbackRangeResult _orderedRange(
    num start,
    num end, {
    num? min,
    num? max,
  }) {
    final clampedStart = _clampToBounds(start, min: min, max: max);
    final clampedEnd = _clampToBounds(end, min: min, max: max);
    if (clampedStart <= clampedEnd) {
      return FallbackRangeResult(start: clampedStart, end: clampedEnd);
    }
    return FallbackRangeResult(start: clampedEnd, end: clampedStart);
  }

  static num _clampToBounds(num value, {num? min, num? max}) {
    var result = value;
    if (min != null && result < min) result = min;
    if (max != null && result > max) result = max;
    return result;
  }

  static void _writePrompt(String title, {String? defaultValue}) {
    final suffix = defaultValue == null ? '' : ' [$defaultValue]';
    TerminalContext.output.write('$title$suffix: ');
  }

  static void _writeError(String message) {
    TerminalContext.output.writeln(message);
  }

  static void _writeOptions<T>(
    String title,
    List<T> options,
    FallbackLabelBuilder<T>? labelBuilder,
  ) {
    TerminalContext.output.writeln(title);
    for (var i = 0; i < options.length; i++) {
      TerminalContext.output.writeln(
        '${i + 1}) ${_labelFor(options[i], labelBuilder)}',
      );
    }
  }

  static String _labelFor<T>(
    T item,
    FallbackLabelBuilder<T>? labelBuilder,
  ) {
    return labelBuilder == null ? item.toString() : labelBuilder(item);
  }

  static int? _normalizeDefaultIndex(int? index, int length) {
    if (index == null || length <= 0) return null;
    if (index < 0 || index >= length) return null;
    return index;
  }

  static Set<int> _normalizeDefaultIndices(Set<int>? indices, int length) {
    if (indices == null || length <= 0) return <int>{};
    return indices.where((i) => i >= 0 && i < length).toSet();
  }

  static Set<int> _defaultOrFallbackIndices(
    Set<int> defaults,
    int? fallbackIndex,
  ) {
    if (defaults.isNotEmpty) return defaults;
    if (fallbackIndex == null) return <int>{};
    return {fallbackIndex};
  }

  static Set<int>? _parseSelectionIndices(String line, int length) {
    final text = line.trim().toLowerCase();
    if (text == 'none') return <int>{};
    if (text == 'all') return {for (var i = 0; i < length; i++) i};

    final parts = text.split(RegExp(r'[,\s]+')).where((p) => p.isNotEmpty);
    final indices = <int>{};

    for (final part in parts) {
      final selected = int.tryParse(part);
      if (selected == null || selected < 1 || selected > length) {
        return null;
      }
      indices.add(selected - 1);
    }

    return indices;
  }

  static List<T> _itemsAt<T>(List<T> options, Set<int> indices) {
    final sorted = indices.toList()..sort();
    return [for (final index in sorted) options[index]];
  }
}
