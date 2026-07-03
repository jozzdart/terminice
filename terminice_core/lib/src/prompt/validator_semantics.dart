/// Normalizes Terminice validator results.
///
/// Validators should return `null` for success. Empty strings are also treated
/// as success to preserve compatibility with older validators.
String? normalizeValidationError(String? error) {
  if (error == null || error.isEmpty) return null;
  return error;
}
