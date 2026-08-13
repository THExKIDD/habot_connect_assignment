import 'dart:io';
import 'package:dio/dio.dart';
import 'package:habot_connect_assignment/core/exceptions/lineage_exception.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/metadata_interceptor.dart';
import '../models/verification_request.dart';
import '../models/verification_response_dto.dart';

/// Repository layer — manages compliance verification endpoint communication.
///
/// Injects [ApiClient] for network interactions and provides production-grade,
/// fail-closed error handling mapping all network, format, and HTTP anomalies.
class ComplianceRepository {
  final ApiClient _apiClient;

  ComplianceRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Submits compliance verification request to `/v1/compliance/verify`.
  ///
  /// Production error handling guarantees that timeouts, connection failures,
  /// malformed JSON, and server error responses are intercepted and mapped into
  /// strict, explicit fail-closed exceptions.
  Future<VerificationResponseDto> verifyCompliance({
    required VerificationRequest request,
    required String traceId,
    required String logicHash,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/v1/compliance/verify',
        data: request.toJson(),
        options: Options(
          extra: {
            MetadataInterceptor.kTraceIdKey: traceId,
            MetadataInterceptor.kLogicHashKey: logicHash,
          },
        ),
      );

      return VerificationResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } on SocketException catch (e) {
      throw LineageException(
        'Network Connection Failed: ${e.message} — Data Quarantined.',
      );
    } on FormatException catch (e) {
      throw LineageException(
        'Response Parsing Error: Invalid JSON response (${e.message}) — Data Quarantined.',
      );
    } catch (e) {
      if (e is LineageException) rethrow;
      throw LineageException(
        'Unexpected Pipeline Failure: $e — Data Quarantined.',
      );
    }
  }

  /// Maps [DioException] to precise, production-grade exception descriptions.
  LineageException _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return const LineageException(
          'Connection Timeout: Server failed to respond within limits — Data Quarantined.',
        );
      case DioExceptionType.sendTimeout:
        return const LineageException(
          'Send Timeout: Unable to transmit payload — Data Quarantined.',
        );
      case DioExceptionType.receiveTimeout:
        return const LineageException(
          'Receive Timeout: Response stream timed out — Data Quarantined.',
        );
      case DioExceptionType.badCertificate:
        return const LineageException(
          'Security Gate Failure: Invalid SSL certificate — Request Terminated.',
        );
      case DioExceptionType.badResponse:
        return LineageException(
          'Data Quarantined — Compliance Failure.',
        );
      case DioExceptionType.cancel:
        return const LineageException(
          'Request Cancelled: Compliance pipeline aborted.',
        );
      case DioExceptionType.connectionError:
        return const LineageException(
          'Connection Error: Target gateway unreachable — Data Quarantined.',
        );
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return const LineageException(
            'Network Unreachable: Socket connection closed — Data Quarantined.',
          );
        }
        return LineageException(
          'System Gateway Error: ${error.message ?? "Unknown network error"} — Data Quarantined.',
        );
      case DioExceptionType.transformTimeout:
        return const LineageException(
          'Response Parsing Error: Response parsing timed out — Data Quarantined.',
        );
    }
  }
}
