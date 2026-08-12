import 'dart:io';
import 'package:dio/dio.dart';
import 'package:habot_connect_assignment/core/exceptions/lineage_exception.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/metadata_interceptor.dart';
import '../models/verification_request.dart';

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
  Future<void> verifyCompliance({
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

      _validateResponseData(response);
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

  /// Production validation of response body format and required fields.
  void _validateResponseData(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      throw const LineageException(
        'API returned null response body — Fail-closed quarantine triggered.',
      );
    }

    final status = data['status'];
    if (status == null) {
      throw const LineageException(
        'API returned null status field — Data Quarantined — Compliance Failure.',
      );
    }

    if (status is String && status.toLowerCase() == 'quarantined') {
      final message = data['message'] as String? ?? 'Compliance check failed at gateway.';
      throw LineageException('Gate Quarantine: $message');
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
        final statusCode = error.response?.statusCode;
        final statusMessage = error.response?.statusMessage;
        return LineageException(
          'HTTP $statusCode Error ($statusMessage) — Data Quarantined — Compliance Failure.',
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
