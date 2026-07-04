import 'package:terminice/testing.dart';

Future<void> main() async {
  final fallbackTester = TerminiceTester.fallback(
    lines: ['launchpad', 'yes'],
  );

  final project = fallbackTester.run(
    (t) => t
        .flow('Create project')
        .text('name', 'Project name')
        .confirm('publish', message: 'Publish now?')
        .run(),
  );

  _check(project.value<String>('name') == 'launchpad', 'name was captured');
  _check(project.value<bool>('publish'), 'publish confirmation was captured');
  _check(
    fallbackTester.output.plainText.contains('Publish now?'),
    'fallback prompt output was captured',
  );

  final interactiveTester = TerminiceTester.interactive(
    script: TerminalScript.build((script) => script.right().enter()),
  );

  final publish = interactiveTester.run(
    (t) => t.confirm(message: 'Publish release?'),
  );

  _check(!publish, 'interactive script selected No');
  _check(
    interactiveTester.output.containsAnsiControls,
    'interactive prompt rendered terminal controls',
  );

  final taskTester = TerminiceTester.nonInteractive();
  final artifactCount = await taskTester.runAsync(
    (t) => t.task<int>(
      'Build artifacts',
      run: () async => 3,
      success: 'artifacts ready',
    ),
  );

  _check(artifactCount == 3, 'task returned its typed result');
  _check(
    taskTester.output.normalizedText == 'OK: artifacts ready',
    'task output was captured without ANSI controls',
  );
}

void _check(bool condition, String message) {
  if (!condition) {
    throw StateError('Expected $message.');
  }
}
