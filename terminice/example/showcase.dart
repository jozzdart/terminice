import 'package:terminice/terminice.dart';

void main() async {
  // 1. Text prompt with default theme
  final name = terminice.text(
    prompt: 'Project name',
    placeholder: 'my_awesome_app',
  );

  // 2. Password prompt with Arcane theme
  // ignore: unused_local_variable
  final secret = terminice.arcane.password(
    prompt: 'Vault passphrase',
    maskChar: '✦',
  );

  // 3. Slider with Ocean theme
  final memory = terminice.ocean.slider(
    'Memory allocation',
    min: 128,
    max: 2048,
    initial: 512,
    step: 128,
    unit: 'MB',
  );

  // 4. Searchable list with Fire theme
  final language = terminice.fire.searchSelector(
    prompt: 'Primary language',
    options: ['Dart', 'Go', 'Rust', 'TypeScript', 'Python', 'C++', 'Java'],
    showSearch: true,
    maxVisible: 4,
  );

  // 5. Multiline editor with Matrix theme
  final notes = terminice.matrix.multiline(
    label: 'Release notes (Ctrl+D to save)',
    visibleLines: 4,
  );

  // 6. Confirm with Neon theme
  final confirmed = terminice.neon.confirm(
    label: 'Deploy',
    message: 'Ship $name to production?',
  );

  if (confirmed == true) {
    print('\n🚀 Deploying $name...');
    print('   Language: ${language.isNotEmpty ? language.first : "None"}');
    print('   Memory:   ${memory}MB');
    print('   Notes:    ${notes?.replaceAll('\n', ' ') ?? "None"}');
  } else {
    print('\n❌ Deployment cancelled.');
  }
}
