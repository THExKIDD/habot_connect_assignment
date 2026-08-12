import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../models/verification_request.dart';

/// Data transfer object holding outbound metadata headers.
class RequestHeaders {
  final String traceId;
  final String logicHash;

  const RequestHeaders({required this.traceId, required this.logicHash});
}

/// Class encapsulating outbound header generation.
abstract final class HeaderBuilder {
  HeaderBuilder._();

  /// Generates trace_id (UUID v4) and logic_hash (SHA-256 hex string).
  static RequestHeaders build(VerificationRequest request) {
    final traceId = const Uuid().v4();
    final payload = jsonEncode(request.toJson());
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    final logicHash = digest.toString();

    return RequestHeaders(traceId: traceId, logicHash: logicHash);
  }
}
