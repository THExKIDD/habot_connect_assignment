/// Logic Byt — pure function that builds the UI friction log string.
///
/// A "friction event" is logged when the user focuses [parent_consent_code]
/// and does not type or submit for more than 5 seconds. This function is
/// responsible only for formatting the log line; the caller (screen composition
/// layer) owns the [Timer] and [FocusNode] wiring.
///
/// Pure function: given the same [hesitation] and [fieldName], always returns
/// the same formatted string. No side effects, no widget dependency.
///
/// Sample output (from HPF Sample Test Data):
/// ```
/// [UI_FRICTION_LOG] Timestamp: 2026-08-07T11:31:05Z | Field: parent_consent_code | Hesitation Duration: 5.2s
/// ```
String buildFrictionLog({
  required Duration hesitation,
  required String fieldName,
}) {
  final timestamp = DateTime.now().toUtc().toIso8601String();
  final seconds = hesitation.inMilliseconds / 1000.0;
  return '[UI_FRICTION_LOG] Timestamp: $timestamp '
      '| Field: $fieldName '
      '| Hesitation Duration: ${seconds.toStringAsFixed(1)}s';
}
