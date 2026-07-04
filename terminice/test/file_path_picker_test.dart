import 'dart:io';

import 'package:terminice/terminice.dart';
import 'package:terminice_core/terminice_core.dart' show KeyEventType;
import 'package:test/test.dart';

import 'mock_terminal.dart';

void main() {
  group('filePicker and pathPicker', () {
    setUp(TerminalContext.reset);
    tearDown(TerminalContext.reset);

    test('filePicker foldersOnly directories navigate and cancel returns null',
        () {
      final root =
          Directory.systemTemp.createTempSync('terminice_file_picker_');
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });

      final child = Directory(_join(root.path, 'child'))..createSync();
      File(_join(root.path, 'root.txt')).writeAsStringSync('root');
      File(_join(child.path, 'inside.txt')).writeAsStringSync('inside');

      final mock = MockTerminal();
      mock.mockInput.queueKey(KeyEventType.arrowDown);
      mock.mockInput.queueKey(KeyEventType.enter);
      mock.mockInput.queueKey(KeyEventType.esc);

      final result = Terminice(terminal: mock).filePicker(
        'Select file',
        startDirectory: root,
        foldersOnly: true,
      );

      expect(result, isNull);
      expect(mock.mockOutput.allOutput, contains('inside.txt'));
    });

    test('pathPicker can confirm the current directory', () {
      final root =
          Directory.systemTemp.createTempSync('terminice_path_picker_');
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });

      final mock = MockTerminal();
      mock.mockInput.queueKey(KeyEventType.arrowDown);
      mock.mockInput.queueKey(KeyEventType.enter);

      final result = Terminice(terminal: mock).pathPicker(
        'Select directory',
        startDirectory: root,
      );

      expect(result, root.path);
    });
  });
}

String _join(String directory, String basename) {
  return '$directory${Platform.pathSeparator}$basename';
}
