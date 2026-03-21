import 'package:terminice/terminice.dart';

Future<void> themeShowcase(Terminice t) async {
  // 1. Text
  t.text('Text Prompt', placeholder: 'Type here...', required: false);

  // 2. Password
  t.password('Password Prompt', required: false);

  // 3. Confirm
  t.confirm(message: 'Are you sure?');

  // 4. Slider
  t.slider('Slider Prompt', min: 0, max: 100, initial: 50);

  // 5. Multiline
  t.multiline('Multiline Prompt');

  // 6. Date
  t.date('Date Prompt');

  // 7. Range
  t.range('Range Prompt', min: 0, max: 100, startInitial: 20, endInitial: 80);

  // 8. Rating
  t.rating('Rating Prompt', maxStars: 5, initial: 3);

  // 9. Choice Selector
  t.choiceSelector('Choice Selector', items: [
    ChoiceItem('Option 1', subtitle: 'First option'),
    ChoiceItem('Option 2', subtitle: 'Second option'),
  ]);

  // 10. Checkbox Selector
  t.checkboxSelector('Checkbox Selector',
      options: ['Option 1', 'Option 2', 'Option 3']);

  // 11. Search Selector
  t.searchSelector(
      prompt: 'Search Selector', options: ['Apple', 'Banana', 'Cherry']);

  // 12. Toggle Group
  t.toggleGroup('Toggle Group', items: [
    ToggleItem('On', initialOn: true),
    ToggleItem('Off', initialOn: false),
  ]);

  // 13. Command Palette
  t.commandPalette('Command Palette', commands: [
    CommandEntry(id: '1', title: 'Command 1', subtitle: 'First'),
    CommandEntry(id: '2', title: 'Command 2', subtitle: 'Second'),
  ]);

  // 14. Tag Selector
  t.tagSelector(prompt: 'Tag Selector', tags: ['Tag 1', 'Tag 2']);

  // 15. Grid Selector
  t.gridSelector(
      prompt: 'Grid Selector', options: ['A', 'B', 'C', 'D'], columns: 2);

  // REMOVED BECAUSE THEME DOES NOT CHANGE THAT MUCH WHEN THE COLOR PICKER IS SHOWN
  // Color Picker
  // t.colorPicker('Color Picker', initialHex: '#FF0000');

  // File Picker
  // t.filePicker('File Picker', startDirectory: Directory.current);

  // Path Picker
  // t.pathPicker('Path Picker', startDirectory: Directory.current);

  // 18. Date Picker
  t.datePicker('Date Picker', initialDate: DateTime.now());

  // 19. Hotkey Guide
  t.hotkeyGuide(title: 'Hotkey Guide', shortcuts: [
    ['Ctrl+C', 'Exit'],
    ['Enter', 'Confirm'],
  ]);

  // 20. Help Center
  t.helpCenter(title: 'Help Center', docs: [
    HelpDoc(id: '1', title: 'Topic 1', content: 'Description 1'),
    HelpDoc(id: '2', title: 'Topic 2', content: 'Description 2'),
  ]);

  // 21. Loading Spinner
  final spinner = t.loadingSpinner('Loading Spinner');
  for (int i = 0; i < 5; i++) {
    spinner.show(i);
    await Future.delayed(Duration(milliseconds: 100));
  }

  // 22. Progress Dots
  final dots = t.progressDots('Progress Dots');
  for (int i = 0; i < 5; i++) {
    dots.show(phase: i);
    await Future.delayed(Duration(milliseconds: 100));
  }

  // 23. Inline Spinner
  final inlineSpinner = t.inlineSpinner('Inline Spinner');
  for (int i = 0; i < 5; i++) {
    inlineSpinner.show(i);
    await Future.delayed(Duration(milliseconds: 100));
  }

  // 24. Progress Bar
  final progressBar = t.progressBar('Progress Bar');
  for (int i = 0; i <= 100; i += 20) {
    progressBar.show(current: i, total: 100, shimmerPhase: i);
    await Future.delayed(Duration(milliseconds: 100));
  }

  // 25. Inline Progress Bar
  final inlineProgressBar = t.inlineProgressBar('Inline Progress Bar');
  for (int i = 0; i <= 100; i += 20) {
    inlineProgressBar.show(current: i, total: 100);
    await Future.delayed(Duration(milliseconds: 100));
  }
}

void main() async {
  await themeShowcase(terminice.themed(PromptTheme.pastel.copyWith(
    features: DisplayFeatures.verbose,
  )));
}
