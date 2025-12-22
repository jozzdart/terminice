import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  terminice.themeDemo();

  // Example 1: Manual frame control
  print('Example 1: Manual spinner updates\n');
  final spinner = terminice.loadingSpinner(
    'Initializing',
    message: 'Preparing workspace',
    style: SpinnerStyle.dots,
  );
  for (int i = 0; i < 20; i++) {
    spinner.show(i);
    sleep(const Duration(milliseconds: 80));
  }
  spinner.clear();

  // Example 2: Using runWith callback
  print('\nExample 2: Using runWith callback\n');
  LoadingSpinner(
    'Processing',
    message: 'Compiling assets',
    style: SpinnerStyle.bars,
    theme: PromptTheme.fire,
  ).runWith((tick) {
    for (int i = 0; i < 15; i++) {
      sleep(const Duration(milliseconds: 100));
      tick();
    }
  });

  // Example 3: Simple spinner
  print('\nExample 3: Simple inline spinner\n');
  final simple =
      terminice.inlineSpinner('Working...', style: SpinnerStyle.bars);
  for (int i = 0; i < 12; i++) {
    simple.show(i);
    sleep(const Duration(milliseconds: 150));
  }
  simple.clear();

  // Example 4: Framed progress bar
  print('\nExample 4: Framed progress bar\n');
  final bar = terminice.progressBar('Downloading assets');
  bar.runWith((update) {
    for (int i = 0; i <= 100; i += 5) {
      sleep(const Duration(milliseconds: 120));
      update(i, 100);
    }
  });

  // Example 5: Inline progress bar for log output
  print('\nExample 5: Inline progress bar\n');
  final inlineBar = terminice.inlineProgressBar('Uploading snapshot');
  for (int i = 0; i <= 10; i++) {
    inlineBar.show(current: i, total: 10);
    sleep(const Duration(milliseconds: 140));
  }
  inlineBar.clear();

  // Example 6: Progress dots indicator
  print('\nExample 6: Progress dots\n');
  final dots = terminice.progressDots('Indexing cache');
  for (int phase = 0; phase < 12; phase++) {
    dots.show(phase: phase);
    sleep(const Duration(milliseconds: 100));
  }
  dots.clear();

  print('Done!');
}
