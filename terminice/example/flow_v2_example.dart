import 'package:terminice/terminice.dart';

void releaseDetails(FlowBuilder flow) {
  flow
      .text(
        'version',
        'Release version',
        placeholder: '1.2.0',
        reviewLabel: 'Version',
      )
      .select<String>(
        'channel',
        'Release channel',
        options: ['stable', 'beta', 'nightly'],
        summarize: (value, _) => value ?? 'stable',
      );
}

void main() {
  final result = terminice
      .flow('Publish release')
      .progress()
      .include(releaseDetails)
      .checkboxes<String>(
        'checks',
        'Completed checks',
        options: ['Tests', 'Docs', 'Changelog'],
        summarize: (values, _) => values.isEmpty ? 'none' : values.join(', '),
      )
      .password(
        'token',
        'Publish token',
        allowReveal: false,
        includeInReview: false,
      )
      .confirm(
        'publish',
        prompt: 'Publish',
        message: 'Publish this release?',
        reviewLabel: 'Ready to publish',
        summarize: (value, _) => value ? 'yes' : 'no',
      )
      .review(title: 'Review release')
      .run();

  if (result.cancelled || !result.flag('publish')) {
    print('Release was not published.');
    return;
  }

  final version = result.string('version');
  final channel = result.valueOr<String>('channel', 'stable');
  final checks = result.list<String>('checks');

  print('Publishing $version to $channel after ${checks.join(', ')}.');
}
