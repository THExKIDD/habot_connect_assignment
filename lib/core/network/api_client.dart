import 'package:dio/dio.dart';
import 'metadata_interceptor.dart';

/// Singleton Dio instance pre-configured for the HabotConnect compliance API.
///
/// The [MetadataInterceptor] is attached here so that *every* request made
/// through this client automatically carries [x-trace-id] and [x-logic-hash]
/// — there is no per-call path that can bypass the headers.
Dio buildApiClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.habotconnect.com',
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  dio.interceptors.add(MetadataInterceptor());

  return dio;
}
