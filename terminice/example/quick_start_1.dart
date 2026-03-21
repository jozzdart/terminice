import 'package:terminice/terminice.dart';

void main() {
  terminice.text(prompt: 'Project name');
  terminice.confirm(message: 'Ship to production?');
}
