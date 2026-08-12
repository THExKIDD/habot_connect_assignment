import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../models/verification_request.dart';

/// Result type carrying both mandatory outbound metadata headers.
class RequestHeaders {
  /// UUID v4 used as [x-trace-id] for end-to-end audit tracing.
  final String traceId;

  /// SHA-256 hex digest of the serialised request payload, used as [x-logic-hash].
  /// Ensures the payload has not been tampered with in transit.
  final String logicHash;

  const RequestHeaders({required this.traceId, required this.logicHash});
}

/// Logic Byt — builds the mandatory metadata headers for an outbound request.
///
/// [x-trace-id]  → UUID v4 (unique per request).
/// [x-logic-hash] → SHA-256 hex string of the JSON-encoded request payload.
///
/// These headers are generated here as pure values; the [MetadataInterceptor]
/// then attaches them to every Dio request automatically.
///
/// Pure function: deterministic for a given [request]; no side effects.
RequestHeaders buildHeaders(VerificationRequest request) {
  final traceId = const Uuid().v4();
  final payload = jsonEncode(request.toJson());
  final bytes = utf8.encode(payload);
  final digest = sha256.convert(bytes);
  final logicHash = digest.toString();

  return RequestHeaders(traceId: traceId, logicHash: logicHash);
}
