import 'package:habot_connect_assignment/core/exceptions/lineage_exception.dart';

/// Data Transfer Object (DTO) representing compliance verification response.
class VerificationResponseDto {
  final String status;
  final String? message;
  final String? lsaId;
  final String? timestampUtc;

  const VerificationResponseDto({
    required this.status,
    this.message,
    this.lsaId,
    this.timestampUtc,
  });

  /// Deserializes raw JSON map into typed DTO with strict nullability enforcement.
  factory VerificationResponseDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw const LineageException(
        'API returned null response body — Fail-closed quarantine triggered.',
      );
    }

    final status = json['status'];
    if (status == null || status is! String || status.isEmpty) {
      throw const LineageException(
        'Data Quarantined — Compliance Failure.',
      );
    }

    return VerificationResponseDto(
      status: status,
      message: json['message'] as String?,
      lsaId: json['lsa_id'] as String?,
      timestampUtc: json['timestamp_utc'] as String?,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
  bool get isQuarantined => status.toLowerCase() == 'quarantined';
}
