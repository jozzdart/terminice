import 'package:terminice/terminice.dart';

void main() {
  // Text input
  final name = terminice.text(
    prompt: 'Your name',
    placeholder: 'Ada Lovelace',
  );
  print('Hello, $name!');

  // Password input (masked)
  final secret = terminice.password(prompt: 'Enter password');
  print('Password length: ${secret?.length ?? 0}');

  // Confirmation dialog
  final proceed = terminice.confirm(
    label: 'Continue',
    message: 'Ready to proceed?',
  );
  print('Proceed: $proceed');

  // Single-select list with search
  final language = terminice.searchSelector(
    prompt: 'Favorite language',
    options: ['Dart', 'Go', 'Rust', 'TypeScript', 'Python'],
    showSearch: true,
  );
  print('Selected: ${language.isNotEmpty ? language.first : "none"}');

  // Multi-select checkboxes
  final features = terminice.checkboxSelector(
    label: 'Enable features',
    options: ['Dark mode', 'Notifications', 'Auto-save', 'Sync'],
    initialSelected: {0},
  );
  print('Enabled: ${features.join(", ")}');
}
