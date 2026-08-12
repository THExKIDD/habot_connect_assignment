import 'dart:async';
import 'package:dio/dio.dart';

/// Network Byt — Mock interceptor for the HabotConnect compliance API.
///
/// Encapsulated in `lib/core/network/mock_api_interceptor.dart`.
///
/// Intercepts network calls to `/v1/compliance/verify` and simulates responses
/// for the three HPF required test scenarios:
///
/// - **Case 1 (Valid Submission)**: `parent_consent_code = "PCC-2026-9901"` & `predecessor_id = "PRED-9982-XYZ"`
///   -> Responds with HTTP 200 OK and `{"status": "success"}`.
/// - **Case 2 (Missing Lineage)**: `predecessor_id` is null or empty.
///   -> (Note: Intercepted locally by [LineageValidator] before network fire,
///      but if bypassed, returns 400 Bad Request).
/// - **Case 3 (Null API / 500 Timeout)**: Any invalid/error consent code (e.g. `"PCC-FAIL-500"` or `"PCC-NULL-STATUS"`)
///   -> Responds with HTTP 500 or `{"status": null}` payload, triggering fail-closed quarantine.
class MockApiInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains('/v1/compliance/verify')) {
      // Simulate network latency for realistic UX
      await Future<void>.delayed(const Duration(milliseconds: 750));

      final data = options.data;
      if (data is Map<String, dynamic>) {
        final consentCode = data['parent_consent_code'] as String?;
        final predecessorId = data['predecessor_id'] as String?;

        // ── Case 1: Valid Submission ─────────────────────────────────────
        if (consentCode == 'PCC-2026-9901' &&
            predecessorId == 'PRED-9982-XYZ') {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'status': 'success',
                'message': 'LSA Compliance Verification Approved',
                'lsa_id': data['lsa_id'],
                'timestamp_utc': DateTime.now().toUtc().toIso8601String(),
              },
            ),
          );
          return;
        }

        // ── Case 3a: Null API Response Status Payload ─────────────────────
        if (consentCode == 'PCC-NULL-STATUS') {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'status': null,
                'message': 'Corrupted Status Payload',
              },
            ),
          );
          return;
        }
      }

      // ── Case 3b: HTTP 500 / Server Error / Timeout ─────────────────────
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 500,
            statusMessage: 'Internal Server Error',
            data: {
              'status': null,
              'error': 'Compliance Gate Gateway Failure',
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    handler.next(options);
  }
}
