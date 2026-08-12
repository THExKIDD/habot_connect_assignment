import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/metadata_interceptor.dart';
import '../models/verification_request.dart';

/// Service layer — wraps the POST /v1/compliance/verify API call.
///
/// Responsibilities:
/// - Stores the pre-computed [traceId] and [logicHash] in [RequestOptions.extra]
///   so [MetadataInterceptor] can attach them as headers automatically.
/// - Throws on any non-2xx response or null [status] field (fail-closed).
///
/// Note: The API endpoint (api.habotconnect.com) does not exist — this is a
/// hiring exercise. For the running demo the service makes the real HTTP call;
/// the network will fail with a [DioException] which ComplianceCubit catches
/// and maps to [ComplianceQuarantined]. To demonstrate Case 1 (Success), use
/// the [ComplianceCubit.verify] with a mock service injected via the constructor.
class ComplianceApiService {
  final Dio _dio;

  ComplianceApiService({Dio? dio}) : _dio = dio ?? buildApiClient();

  /// Sends the compliance verification request.
  ///
  /// Throws [DioException] on network failure, non-2xx status, or null response.
  /// The caller ([ComplianceCubit]) treats any thrown exception as a quarantine trigger.
  Future<void> verify({
    required VerificationRequest request,
    required String traceId,
    required String logicHash,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/compliance/verify',
      data: request.toJson(),
      options: Options(
        extra: {
          MetadataInterceptor.kTraceIdKey: traceId,
          MetadataInterceptor.kLogicHashKey: logicHash,
        },
      ),
    );

    // Fail-closed: treat null status field as a compliance failure.
    final status = response.data?['status'];
    if (status == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'API returned null status — fail-closed quarantine triggered.',
        type: DioExceptionType.badResponse,
      );
    }
  }
}
