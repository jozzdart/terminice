import 'dart:async';

import 'package:terminice_core/terminice_core.dart';

import 'terminice_api.dart';
import 'terminice_config.dart';

/// Runs a custom Terminice component with a prepared component [context].
typedef TerminiceComponentCallback<T> = T Function(
  TerminiceComponentContext context,
);

/// A reusable custom component that runs against a configured [Terminice].
///
/// Components are intentionally lightweight: they receive a
/// [TerminiceComponentContext], perform work, and return a value. There is no
/// widget tree, registry, or lifecycle framework hidden behind this type.
abstract class TerminiceComponent<T> {
  /// Creates a component subclass.
  const TerminiceComponent();

  /// Creates a component from a callback.
  const factory TerminiceComponent.from(
    TerminiceComponentCallback<T> run,
  ) = _CallbackTerminiceComponent<T>;

  /// Runs this component with the prepared [context].
  T run(TerminiceComponentContext context);
}

class _CallbackTerminiceComponent<T> extends TerminiceComponent<T> {
  const _CallbackTerminiceComponent(this._run);

  final TerminiceComponentCallback<T> _run;

  @override
  T run(TerminiceComponentContext context) {
    return _run(context);
  }
}

/// Execution context for a custom [TerminiceComponent].
///
/// The terminal is captured after the owning [terminice] instance is activated.
/// All terminal, input, output, and fallback accessors use that captured
/// terminal, so components can stay stable even if global [TerminalContext]
/// changes while they are running.
class TerminiceComponentContext {
  TerminiceComponentContext._({
    required this.terminice,
    required this.terminal,
  })  : configuration = terminice.configuration,
        theme = terminice.defaultTheme,
        input = terminal.input,
        output = terminal.output,
        shouldUseFallback =
            terminice.configuration.fallbackMode.shouldUseFallback(terminal);

  /// The configured Terminice instance that created this context.
  final Terminice terminice;

  /// Immutable configuration for [terminice].
  final TerminiceConfig configuration;

  /// Effective prompt theme for [terminice].
  final PromptTheme theme;

  /// Terminal captured immediately after [terminice] was activated.
  final Terminal terminal;

  /// Input stream from the captured [terminal].
  final TerminalInput input;

  /// Output stream from the captured [terminal].
  final TerminalOutput output;

  /// Whether this context should use line-mode fallback.
  ///
  /// This decision is based on [configuration] and the captured [terminal], not
  /// on the current global [TerminalContext].
  final bool shouldUseFallback;

  /// Reinstalls the captured [terminal] as the global active terminal.
  ///
  /// Use this before calling lower-level APIs that intentionally read from
  /// [TerminalContext.current].
  void activate() {
    TerminalContext.current = terminal;
  }

  /// Runs [run] with the captured [terminal] installed as active.
  ///
  /// The previous global terminal context is restored after [run] completes.
  T withActiveTerminal<T>(T Function() run) {
    return TerminalContext.runWith(terminal, run);
  }

  /// Runs asynchronous [run] with the captured [terminal] installed as active.
  ///
  /// The previous global terminal context is restored after the returned future
  /// completes.
  Future<T> withActiveTerminalAsync<T>(FutureOr<T> Function() run) {
    return TerminalContext.runWithAsync(terminal, run);
  }

  /// Runs either [interactive] or [fallback] using this context's fallback
  /// decision.
  T runWithFallback<T>({
    required T Function() interactive,
    required T Function() fallback,
  }) {
    return withActiveTerminal<T>(
      () => shouldUseFallback ? fallback() : interactive(),
    );
  }
}

/// Shared execution helper for high-level Terminice components.
///
/// Covered components use this so terminal activation and fallback policy stay
/// centralized on the [Terminice] instance instead of being reimplemented in
/// every extension.
extension TerminiceComponentRunner on Terminice {
  /// Activates this instance, captures the intended terminal, and runs
  /// [component] with a stable [TerminiceComponentContext].
  T runComponent<T>(TerminiceComponent<T> component) {
    activate();
    final context = TerminiceComponentContext._(
      terminice: this,
      terminal: TerminalContext.current,
    );
    return component.run(context);
  }

  /// Runs a custom component callback with a stable
  /// [TerminiceComponentContext].
  T runWithComponent<T>(TerminiceComponentCallback<T> run) {
    return runComponent<T>(TerminiceComponent<T>.from(run));
  }

  /// Activates this instance, then runs either [interactive] or [fallback]
  /// according to [shouldUseFallback].
  T runWithFallback<T>({
    required T Function() interactive,
    required T Function() fallback,
  }) {
    return runWithComponent<T>(
      (context) => context.runWithFallback<T>(
        interactive: interactive,
        fallback: fallback,
      ),
    );
  }
}
