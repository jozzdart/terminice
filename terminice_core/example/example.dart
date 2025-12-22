import 'package:terminice_core/terminice_core.dart';

void main() {
  // Confirm prompt
  final confirmed = SimplePrompts.confirm(
    title: 'Confirm',
    message: 'Do you want to continue?',
  ).run();
  print('Confirmed: $confirmed');

  // Single-select list
  final language = SelectableListPrompt.single<String>(
    title: 'Select Language',
    items: ['Dart', 'Go', 'Rust', 'TypeScript', 'Python'],
  );
  print('Selected: $language');

  // Multi-select list
  final features = SelectableListPrompt.multi<String>(
    title: 'Enable Features',
    items: ['Dark mode', 'Notifications', 'Auto-save', 'Sync'],
    initialSelection: {0, 2},
  );
  print('Enabled: ${features.join(", ")}');
}
