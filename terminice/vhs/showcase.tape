# VHS Tape for terminice showcase
# Run with: vhs showcase.tape

Output assets/showcase.gif

Require dart

Set Margin 0
Set BorderRadius 0
Set WindowBar ""

Set FontSize 20
Set Width 1125
Set Height 310
Set Padding 20
Set Theme "OneDark"

Hide
Type "clear && dart run example/showcase.dart"
Enter
Show

# 1. Text prompt
Sleep 1s
Type "terminice_demo"
Sleep 500ms
Enter

# 2. Password prompt
Sleep 1s
Type "supersecret"
Sleep 500ms
Enter

# 3. Slider prompt
Sleep 1s
Right 4
Sleep 500ms
Left 2
Sleep 500ms
Enter

# 4. SearchSelector prompt
Sleep 1s
Type "script"
Sleep 800ms
Backspace 6
Sleep 500ms
Type "ru"
Sleep 500ms
Enter

# 5. Multiline prompt
Sleep 1s
Type "Added beautiful new CLI prompts."
Enter
Type "Fixed memory leaks."
Sleep 500ms
Ctrl+D

# 6. Confirm prompt
Sleep 1s
Right
Sleep 500ms
Left
Sleep 500ms
Enter

Sleep 3s
