import 'terminice_api.dart';

/// Shared execution helper for high-level Terminice components.
///
/// Covered components use this so terminal activation and fallback policy stay
/// centralized on the [Terminice] instance instead of being reimplemented in
/// every extension.
extension TerminiceComponentRunner on Terminice {
  /// Activates this instance, then runs either [interactive] or [fallback]
  /// according to [shouldUseFallback].
  T runWithFallback<T>({
    required T Function() interactive,
    required T Function() fallback,
  }) {
    activate();
    return shouldUseFallback ? fallback() : interactive();
  }
}
