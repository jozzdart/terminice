import 'package:test/test.dart';
import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart';

import 'mock_terminal.dart';

void main() {
  setUp(() {
    TerminalContext.reset();
  });

  tearDown(() {
    TerminalContext.reset();
  });

  group('fallback wiring', () {
    test('text fallback reads queued lines without entering raw mode', () {
      final mock = MockTerminal();
      mock.mockInput.queueLine('Ada');

      final t = terminice.fallback.withTerminal(mock);
      TerminalContext.current = MockTerminal();

      final result = t.text('Name');

      expect(result, equals('Ada'));
      expect(mock.mockInput.lineMode, isTrue);
      expect(mock.mockInput.echoMode, isTrue);
      expect(mock.mockInput.linesRemaining, equals(0));
      expect(mock.mockOutput.contains('Name'), isTrue);
    });

    test('confirm fallback respects defaults and explicit answers', () {
      final mock = MockTerminal();
      mock.mockInput.queueLines(['', 'n', 'yes']);
      final t = terminice.fallback.withTerminal(mock);

      expect(t.confirm(message: 'Default yes?'), isTrue);
      expect(t.confirm(message: 'No?'), isFalse);
      expect(t.confirm(message: 'Default no?', defaultYes: false), isTrue);
    });

    test('selector fallback returns the selected value', () {
      final mock = MockTerminal();
      mock.mockInput.queueLine('2');
      final t = terminice.fallback.withTerminal(mock);

      final result = t.searchSelector(
        prompt: 'Pick one',
        options: const ['alpha', 'beta', 'gamma'],
      );

      expect(result, equals(['beta']));
    });

    test('auto fallback uses line mode when terminal streams are unavailable',
        () {
      final mock = MockTerminal();
      mock.mockInput
        ..setHasTerminal(false)
        ..queueLine('Ada');
      mock.mockOutput.setHasTerminal(false);
      final t = terminice.autoFallback.withTerminal(mock);

      final result = t.text('Name');

      expect(result, equals('Ada'));
      expect(mock.mockInput.lineMode, isTrue);
      expect(mock.mockInput.echoMode, isTrue);
    });

    test('command palette fallback includes subtitles in numbered options', () {
      final mock = MockTerminal();
      mock.mockInput.queueLine('1');
      final t = terminice.fallback.withTerminal(mock);

      final result = t.commandPalette(
        'Commands',
        commands: const [
          CommandEntry(id: 'deploy', title: 'Deploy', subtitle: 'Production'),
          CommandEntry(id: 'preview', title: 'Deploy', subtitle: 'Preview'),
        ],
      );

      expect(result?.id, equals('deploy'));
      expect(mock.mockOutput.contains('Deploy - Production'), isTrue);
      expect(mock.mockOutput.contains('Deploy - Preview'), isTrue);
    });

    test('selector fallback blank input uses the shared default selection', () {
      final mock = MockTerminal();
      mock.mockInput.queueLine('');
      final t = terminice.fallback.withTerminal(mock);

      final result = t.gridSelector(
        prompt: 'Pick one',
        options: const ['alpha', 'beta', 'gamma'],
        initialSelection: const {2},
      );

      expect(result, equals(['gamma']));
    });

    test('multi-select fallback blank input selects the focused first item',
        () {
      final mock = MockTerminal();
      mock.mockInput.queueLine('');
      final t = terminice.fallback.withTerminal(mock);

      final result = t.checkboxSelector(
        'Pick many',
        options: const ['alpha', 'beta', 'gamma'],
      );

      expect(result, equals(['alpha']));
    });

    test('multi-select fallback explicit none selects nothing', () {
      final mock = MockTerminal();
      mock.mockInput.queueLine('none');
      final t = terminice.fallback.withTerminal(mock);

      final result = t.checkboxSelector(
        'Pick many',
        options: const ['alpha', 'beta', 'gamma'],
      );

      expect(result, isEmpty);
    });

    test('selector fallback ignores invalid initial selection on blank input',
        () {
      final mock = MockTerminal();
      mock.mockInput.queueLine('');
      final t = terminice.fallback.withTerminal(mock);

      final result = t.gridSelector(
        prompt: 'Pick one',
        options: const ['alpha', 'beta', 'gamma'],
        initialSelection: const {999},
      );

      expect(result, equals(['alpha']));
    });

    test('verified password fallback retries mismatches', () {
      final mock = MockTerminal();
      mock.mockInput.queueLines(['first', 'second', 'secret', 'secret']);
      final t = terminice.fallback.withTerminal(mock);

      final result = t.password('Password', verify: true);

      expect(result, equals('secret'));
      expect(mock.mockOutput.contains('Passwords do not match'), isTrue);
      expect(mock.mockOutput.contains('Verify password'), isTrue);
    });
  });

  test('config editor passes derived Terminice config into nested edits', () {
    final mock = MockTerminal();
    mock.mockInput
      ..queueKey(KeyEventType.arrowDown)
      ..queueKey(KeyEventType.arrowDown)
      ..queueKey(KeyEventType.enter)
      ..queueKey(KeyEventType.arrowUp)
      ..queueKey(KeyEventType.arrowUp)
      ..queueKey(KeyEventType.enter);

    final capture = _CapturingConfigurable();
    final configured = terminice.compact.legacy.fallback.withTerminal(mock);

    final result = configured.configEditor(
      'Settings',
      fields: [
        ThemeConfigurable(
          key: 'theme',
          label: 'Theme',
          value: 'fire',
        ),
        capture,
      ],
      maxVisible: 6,
    );

    expect(result, isNotNull);
    expect(capture.captured, isNotNull);

    final captured = capture.captured!;
    expect(captured.terminal, same(mock));
    expect(captured.baseTheme, equals(PromptTheme.fire));
    expect(captured.featureOverride, equals(DisplayFeatures.compact));
    expect(captured.compatibility, equals(TerminalCompatibility.legacy));
    expect(captured.fallbackMode, equals(TerminiceFallbackMode.fallback));
    expect(captured.defaultTheme.colors, equals(TerminalColors.none));
    expect(captured.defaultTheme.glyphs, equals(TerminalGlyphs.ascii));
    expect(captured.defaultTheme.features.hintStyle, equals(HintStyle.none));
  });
}

class _CapturingConfigurable extends Configurable<String> {
  Terminice? captured;

  _CapturingConfigurable()
      : super(
          key: 'capture',
          label: 'Capture',
          value: '',
        );

  @override
  String get defaultTypeIcon => 'T';

  @override
  bool edit(Terminice terminice) {
    captured = terminice;
    return false;
  }

  @override
  dynamic toJsonValue() => value;

  @override
  void loadJsonValue(dynamic jsonValue) {
    if (jsonValue is String) value = jsonValue;
  }
}
