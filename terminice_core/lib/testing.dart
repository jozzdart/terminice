/// Testing utilities for terminice_core.
///
/// Provides mock terminal implementations for unit testing prompts and
/// terminal-based code without a real terminal attached.
///
/// ```dart
/// import 'package:terminice_core/testing.dart';
///
/// final mock = MockTerminal();
/// mock.mockInput.queueKey(KeyEventType.enter);
/// TerminalContext.current = mock;
/// ```
library testing;

export 'package:terminice_core/terminice_core.dart';
export 'src/testing/mock_terminal.dart';
