/// Immutable data class representing the outbound API request payload.
///
/// Byt boundary: pure data carrier — no logic, no widget dependency.
/// All fields are final; construct a new instance via [copyWith] if mutation needed.
class VerificationRequest {
  final String predecessorId;
  final String lsaId;
  final String parentConsentCode;
  final String timestampUtc;

  const VerificationRequest({
    required this.predecessorId,
    required this.lsaId,
    required this.parentConsentCode,
    required this.timestampUtc,
  });

  /// Serialises the request to the exact JSON schema required by the API.
  ///
  /// Schema reference (from HPF Sample Test Data):
  /// ```json
  /// {
  ///   "predecessor_id": "PRED-9982-XYZ",
  ///   "lsa_id": "LSA-7049",
  ///   "parent_consent_code": "PCC-2026-9901",
  ///   "timestamp_utc": "2026-08-07T11:30:00Z"
  /// }
  /// ```
  Map<String, dynamic> toJson() => {
        'predecessor_id': predecessorId,
        'lsa_id': lsaId,
        'parent_consent_code': parentConsentCode,
        'timestamp_utc': timestampUtc,
      };

  VerificationRequest copyWith({
    String? predecessorId,
    String? lsaId,
    String? parentConsentCode,
    String? timestampUtc,
  }) {
    return VerificationRequest(
      predecessorId: predecessorId ?? this.predecessorId,
      lsaId: lsaId ?? this.lsaId,
      parentConsentCode: parentConsentCode ?? this.parentConsentCode,
      timestampUtc: timestampUtc ?? this.timestampUtc,
    );
  }
}
