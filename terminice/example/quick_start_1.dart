import 'package:terminice/terminice.dart';

void main() {
  terminice.text('Project name');
  terminice.confirm(prompt: 'Ship to production?', message: 'Are you sure?');
}
