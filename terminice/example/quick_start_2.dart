import 'package:terminice/terminice.dart';

void main() {
  terminice.searchSelector(
    prompt: 'Language',
    options: ['Dart', 'Go', 'Rust', 'TypeScript'],
    showSearch: true,
  );
}
