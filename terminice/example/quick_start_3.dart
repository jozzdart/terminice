import 'package:terminice/terminice.dart';

void main() {
  // Hacker green
  terminice.matrix.password(prompt: 'Passphrase');

  // High-energy cyberpunk
  terminice.neon.slider('Memory', min: 128, max: 2048, step: 128);
}
