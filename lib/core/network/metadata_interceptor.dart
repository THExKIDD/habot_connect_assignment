import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Dio interceptor that injects mandatory metadata headers on every outbound request.
///
/// Headers injected (per HPF API contract):
/// - [x-trace-id]   → UUID v4, unique per request (audit tracing).
/// - [x-logic-hash] → SHA-256 hex digest of the request payload.
///
/// The [x-logic-hash] for a specific request is pre-computed by [buildHeaders]
/// and stored in [RequestOptions.extra] under the key [kLogicHashKey] by
/// [ComplianceApiService] before Dio dispatches the call.
/// The interceptor reads it here and attaches it to the header map.
///
/// If no pre-computed hash is present (e.g., non-compliance requests), the
/// interceptor fails-closed: it blocks the request to prevent any metadata-
/// free call from leaving the app.
class MetadataInterceptor extends Interceptor {
  static const String kLogicHashKey = 'x_logic_hash';
  static const String kTraceIdKey = 'x_trace_id';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Retrieve pre-computed values stored by the service layer.
    final traceId = options.extra[kTraceIdKey] as String? ?? const Uuid().v4();
    final logicHash = options.extra[kLogicHashKey] as String?;

    // Fail-closed: if logic_hash is missing, reject the request.
    if (logicHash == null || logicHash.isEmpty) {
      handler.reject(
        DioException(
          requestOptions: options,
          message: 'MetadataInterceptor: x-logic-hash missing — request blocked (fail-closed).',
          type: DioExceptionType.cancel,
        ),
        true,
      );
      return;
    }

    options.headers['x-trace-id'] = traceId;
    options.headers['x-logic-hash'] = logicHash;

    handler.next(options);
  }
}
