# Terminal text Unicode data

`generate_terminal_text_unicode_data.dart` downloads the authoritative,
versioned Unicode 15.1 files named in its source and regenerates
`lib/src/utils/terminal_text_unicode_data.dart`.

From the `termistyle` directory:

```sh
dart run tool/generate_terminal_text_unicode_data.dart
dart run tool/generate_terminal_text_unicode_data.dart --check
```

The first command updates the checked-in data file. The second exits non-zero
if regeneration would change it. Runtime code never downloads Unicode data.
