/// Sealed class representing all possible compliance pipeline states.
///
/// Byt boundary: pure data — no widget/logic dependency.
/// ComplianceCubit is the only entity allowed to emit these states.
sealed class ComplianceState {
  const ComplianceState();
}

/// Default state — form is ready for input, no operation in flight.
final class ComplianceIdle extends ComplianceState {
  const ComplianceIdle();
}

/// Network call is in-flight — UI should lock the submit button.
final class ComplianceProcessing extends ComplianceState {
  const ComplianceProcessing();
}

/// Fail-closed halt — any null/invalid/error condition lands here.
/// [reason] is a human-readable description for the status banner.
final class ComplianceQuarantined extends ComplianceState {
  final String reason;
  const ComplianceQuarantined(this.reason);
}

/// Happy path — request accepted, compliance verified.
/// [traceId] is the x-trace-id UUID echoed back for audit.
final class ComplianceSuccess extends ComplianceState {
  final String traceId;
  const ComplianceSuccess(this.traceId);
}
