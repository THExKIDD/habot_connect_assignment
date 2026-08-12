import '../models/lineage_exception.dart';

/// Logic Byt — validates that [predecessorId] is non-null and non-empty.
///
/// This is the data-lineage gate: if [predecessorId] is absent, the request
/// would create "orphan data" with no traceable parent record. The function
/// throws [LineageException] immediately (fail-closed) so the pipeline halts
/// before any network call is made.
///
/// Pure function: no side effects, no widget/BuildContext dependency.
/// Unit-testable in isolation without pumping a widget tree.
void validateLineage(String? predecessorId) {
  if (predecessorId == null || predecessorId.trim().isEmpty) {
    throw const LineageException(
      'predecessor_id is null or empty — orphan data detected. '
      'Network call blocked.',
    );
  }
}
