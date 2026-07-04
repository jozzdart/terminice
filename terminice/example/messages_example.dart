import 'package:terminice/terminice.dart';

Future<void> main() async {
  final t = terminice.legacy.fallback;

  t.info('Installing dependencies');

  await t.task<void>(
    'Resolving packages',
    display: TaskDisplay.plain,
    run: () async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    success: 'Dependencies installed',
  );

  t.success('Project ready');
  t.detail('Run with --verbose for more output');
  t.newline();

  t.log('Next: dart run');
  t.warn('Using cached config');
  t.error('Publish failed');
  t.err('Retry failed too');
}
