import 'package:terminice/testing.dart';

import 'command_app_example.dart';

Future<void> main() async {
  final initTester = TerminiceTester.fallback(
    lines: const ['comet', '1', '1,3', 'yes'],
  );
  final initCode = await initTester.runAsync(
    (t) => runCommandApp(const ['init'], t),
  );

  _check(initCode == 0, 'init completed successfully');
  _check(
    initTester.output.plainText.contains('Created comet'),
    'init output included the project name',
  );

  final publishTester = TerminiceTester.nonInteractive();
  final publishCode = await publishTester.runAsync(
    (t) => runCommandApp(const ['publish', '--ci', '--yes'], t),
  );

  _check(publishCode == 0, 'CI publish completed successfully');
  _check(
    !publishTester.output.containsAnsiControls,
    'CI publish used plain output',
  );
  _check(
    publishTester.output.normalizedText.contains('OK: Package published'),
    'CI publish output was captured',
  );

  final unknownTester = TerminiceTester.nonInteractive();
  final unknownCode = await unknownTester.runAsync(
    (t) => runCommandApp(const ['deploy'], t),
  );

  _check(unknownCode != 0, 'unknown command failed');
  _check(
    unknownTester.output.plainText.contains('Unknown command: deploy'),
    'unknown command output explained the failure',
  );

  final unknownFlagTester = TerminiceTester.nonInteractive();
  final unknownFlagCode = await unknownFlagTester.runAsync(
    (t) => runCommandApp(const ['publish', '--ci', '--yes', '--bogus'], t),
  );

  _check(unknownFlagCode == 64, 'unknown flag returned a usage error');
  _check(
    unknownFlagTester.output.plainText.contains('Unknown option: --bogus'),
    'unknown flag output explained the failure',
  );
  _check(
    unknownFlagTester.output.plainText.contains('publish [--yes] [--ci]'),
    'unknown flag output included command usage',
  );

  print('Command app example checks passed.');
}

void _check(bool condition, String message) {
  if (!condition) {
    throw StateError('Expected $message.');
  }
}
