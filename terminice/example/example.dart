import 'package:terminice/src/pickers/color_picker.dart';
import 'package:terminice/terminice.dart';

void main() {
  final color = terminice.colorPicker('Color');
  print(color);

  final result = terminice.fire.toggleGroup(
    title: 'Settings',
    items: [
      ToggleItem('Option 1', initialOn: false),
      ToggleItem('Option 2', initialOn: false),
      ToggleItem('Option 3', initialOn: false),
      ToggleItem('Option 4', initialOn: false),
      ToggleItem('Option 5', initialOn: false),
      ToggleItem('Option 6', initialOn: false),
      ToggleItem('Option 7', initialOn: false),
      ToggleItem('Option 8', initialOn: false),
      ToggleItem('Option 9', initialOn: false),
      ToggleItem('Option 10', initialOn: false),
    ],
  );
  print(result);

  final date = terminice.date('Date');
  print(date);
}
