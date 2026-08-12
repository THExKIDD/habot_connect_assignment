import 'package:dio/dio.dart';
import 'api_log_interceptor.dart';
import 'metadata_interceptor.dart';
import 'mock_api_interceptor.dart';

/// Class wrapping Dio HTTP client setup and options.
///
/// Encapsulates Dio instance, header injection, logging, and mock API adapter.
class ApiClient {
  late final Dio _dio;

  ApiClient({Dio? dio}) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: 'https://api.habotconnect.com',
            contentType: 'application/json',
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
          ),
        );

    // 1. MetadataInterceptor: injects x-trace-id and x-logic-hash headers
    _dio.interceptors.add(MetadataInterceptor());

    // 2. MockApiInterceptor: simulates Case 1 (Valid), Case 2, Case 3 (Error/Null)
    _dio.interceptors.add(MockApiInterceptor());

    // 3. ApiLogInterceptor: logs the fully-enriched request and mock response
    _dio.interceptors.add(ApiLogInterceptor());
  }

  /// Returns underlying Dio instance.
  Dio get client => _dio;

  /// Executes HTTP POST with mandatory header extra parameters.
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
