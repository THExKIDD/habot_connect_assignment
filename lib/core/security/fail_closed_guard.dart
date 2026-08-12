
import 'package:habot_connect_assignment/core/exceptions/lineage_exception.dart';

/// Class encapsulating generic fail-closed security guards.
///
/// Prevents global top-level functions and provides strict null/empty checks.
abstract final class FailClosedGuard {
  FailClosedGuard._();

  /// Returns [value] if non-null; otherwise throws [LineageException].
  static T guardNotNull<T>(T? value, String reason) {
    if (value == null) {
      throw LineageException(reason);
    }
    return value;
  }

  /// Validates string is non-null and non-empty.
  static String guardNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      throw LineageException('$fieldName must not be null or empty.');
    }
    return value.trim();
  }
}
