/// Exception thrown by [LineageValidator] when [predecessorId] is null or empty.
///
/// Byt boundary: pure exception type — no widget/logic dependency.
/// Throwing this exception immediately halts the pipeline (fail-closed).
class LineageException implements Exception {
  final String message;

  const LineageException(this.message);

  @override
  String toString() => 'LineageException: $message';
}
