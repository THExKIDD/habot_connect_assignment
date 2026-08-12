
import 'package:habot_connect_assignment/core/exceptions/lineage_exception.dart';

/// Class encapsulating data lineage verification logic.
///
/// Ensures no orphaned data (missing predecessor_id) ever proceeds.
abstract final class LineageValidator {
  LineageValidator._();

  /// Validates [predecessorId] is non-null and non-empty.
  /// Throws [LineageException] immediately on failure.
  static void validate(String? predecessorId) {
    if (predecessorId == null || predecessorId.trim().isEmpty) {
      throw const LineageException(
        'predecessor_id is null or empty — orphan data detected. Network call blocked.',
      );
    }
  }
}
