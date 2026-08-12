import 'package:dio/dio.dart';
import 'api_log_interceptor.dart';
import 'metadata_interceptor.dart';

/// Class wrapping Dio HTTP client setup and options.
///
/// Ensures no global instances or functions exist without class encapsulation.
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

    // MetadataInterceptor first — injects headers before they are logged.
    _dio.interceptors.add(MetadataInterceptor());

    // ApiLogInterceptor second — logs the fully-enriched request + response.
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
