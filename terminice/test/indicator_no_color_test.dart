import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('standalone async indicators keep explicit colors under NO_COLOR',
      () async {
    final environment = Map<String, String>.of(Platform.environment)
      ..['NO_COLOR'] = '1';
    final result = await Process.run(
      Platform.resolvedExecutable,
      ['run', 'test/fixtures/indicator_color_probe.dart'],
      environment: environment,
    );

    expect(result.exitCode, equals(0), reason: result.stderr.toString());
    expect(
      result.stdout.toString().trim(),
      equals('true,true,true,false,false'),
    );
  });
}
