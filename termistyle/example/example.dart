import 'package:termistyle/termistyle.dart';

void main() {
  final theme = PromptTheme.matrix;

  print('${theme.accent}Matrix theme accent${theme.reset}');
  print('${theme.highlight}Highlighted text${theme.reset}');
  print('Arrow glyph: ${theme.arrow}');

  final styled = '${theme.accent}Status${theme.reset}';
  print('Visible length: ${visibleLength(styled)}');
  print('Stripped: ${stripAnsi(styled)}');

  print('\nAll built-in themes:');
  final names = [
    'dark',
    'matrix',
    'fire',
    'pastel',
    'ocean',
    'monochrome',
    'neon',
    'arcane',
    'phantom',
  ];
  final themes = [
    PromptTheme.dark,
    PromptTheme.matrix,
    PromptTheme.fire,
    PromptTheme.pastel,
    PromptTheme.ocean,
    PromptTheme.monochrome,
    PromptTheme.neon,
    PromptTheme.arcane,
    PromptTheme.phantom,
  ];
  for (var i = 0; i < names.length; i++) {
    final t = themes[i];
    print('  ${t.accent}${padRight(names[i], 12)}${t.reset} '
        '${t.borderTop}${t.borderHorizontal}${t.borderHorizontal}${t.borderBottom}');
  }
}
