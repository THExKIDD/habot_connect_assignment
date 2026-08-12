import '../../../features/lsa_verification/models/lineage_exception.dart';

/// Security Byt — generic fail-closed null guard.
///
/// Returns [value] if it is non-null; otherwise throws immediately.
/// Use this as the canonical "halt on null" utility so every check
/// site in the codebase communicates its intent uniformly.
///
/// Example:
/// ```dart
/// final id = guardNotNull(rawId, 'predecessor_id must not be null');
/// ```
T guardNotNull<T>(T? value, String reason) {
  if (value == null) {
    throw LineageException(reason);
  }
  return value;
}
