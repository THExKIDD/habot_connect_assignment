/// Utility class for formatting UI friction log strings.
///
/// Encapsulates log formatting inside a dedicated class structure.
abstract final class FrictionLogger {
  FrictionLogger._();

  /// Formats a friction log entry for a given field hesitation duration.
  static String buildLog({
    required Duration hesitation,
    required String fieldName,
  }) {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final seconds = hesitation.inMilliseconds / 1000.0;
    return '[UI_FRICTION_LOG] Timestamp: $timestamp '
        '| Field: $fieldName '
        '| Hesitation Duration: ${seconds.toStringAsFixed(1)}s';
  }
}
