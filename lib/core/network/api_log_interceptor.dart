import 'dart:developer' as dev;
import 'package:dio/dio.dart';

/// Dio interceptor that logs outbound requests (with headers) and inbound
/// responses in a structured, readable format to the debug console.
///
/// Output is routed through [dart:developer] `log()` so it appears in the
/// IDE's debug console with the correct severity level and name tag, and is
/// stripped from release builds automatically by the Flutter toolchain when
/// assertions are disabled.
///
/// Log sections emitted:
/// - ┌──────  REQUEST  ──────┐  — method, URL, headers, body
/// - ┌──────  RESPONSE ──────┐  — status, headers (response omitted), body
/// - ┌──────  ERROR    ──────┐  — DioException type, message, status if any
class ApiLogInterceptor extends Interceptor {
  static const String _tag = 'API';
  static final String _divider = '─' * 60;
  static const String _topCorner = '┌';
  static const String _bottomCorner = '└';
  static const String _side = '│';

  // ─────────────────────────── REQUEST ─────────────────────────────────────

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      final buffer = StringBuffer();

      buffer.writeln('$_topCorner$_divider');
      buffer.writeln('$_side  REQUEST');
      buffer.writeln('$_side  $_divider');
      buffer.writeln('$_side  ${options.method.toUpperCase()}  ${options.uri}');
      buffer.writeln('$_side');

      // ── Headers (request only, per spec) ────────────────────────────────
      buffer.writeln('$_side  HEADERS');
      options.headers.forEach((key, value) {
        buffer.writeln('$_side    $key: $value');
      });
      buffer.writeln('$_side');

      // ── Body ─────────────────────────────────────────────────────────────
      if (options.data != null) {
        buffer.writeln('$_side  BODY');
        _formatBody(options.data, buffer);
      }

      buffer.writeln('$_bottomCorner$_divider');

      dev.log(buffer.toString(), name: _tag, level: 500);
      return true;
    }());

    handler.next(options);
  }

  // ─────────────────────────── RESPONSE ────────────────────────────────────

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      final buffer = StringBuffer();

      buffer.writeln('$_topCorner$_divider');
      buffer.writeln('$_side  RESPONSE');
      buffer.writeln('$_side  $_divider');
      buffer.writeln(
        '$_side  ${response.statusCode} ${response.statusMessage ?? ""}',
      );
      buffer.writeln(
        '$_side  ${response.requestOptions.method.toUpperCase()}  ${response.requestOptions.uri}',
      );
      buffer.writeln('$_side');

      // ── Body ─────────────────────────────────────────────────────────────
      buffer.writeln('$_side  BODY');
      _formatBody(response.data, buffer);

      buffer.writeln('$_bottomCorner$_divider');

      dev.log(buffer.toString(), name: _tag, level: 500);
      return true;
    }());

    handler.next(response);
  }

  // ─────────────────────────── ERROR ───────────────────────────────────────

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      final buffer = StringBuffer();

      buffer.writeln('$_topCorner$_divider');
      buffer.writeln('$_side  ERROR');
      buffer.writeln('$_side  $_divider');
      buffer.writeln('$_side  Type   : ${err.type.name}');
      buffer.writeln('$_side  Message: ${err.message ?? "—"}');

      if (err.response != null) {
        buffer.writeln(
          '$_side  Status : ${err.response!.statusCode} ${err.response!.statusMessage ?? ""}',
        );
        buffer.writeln('$_side  URL    : ${err.requestOptions.uri}');

        if (err.response!.data != null) {
          buffer.writeln('$_side');
          buffer.writeln('$_side  RESPONSE BODY');
          _formatBody(err.response!.data, buffer);
        }
      } else {
        buffer.writeln('$_side  URL    : ${err.requestOptions.uri}');
      }

      buffer.writeln('$_bottomCorner$_divider');

      dev.log(buffer.toString(), name: _tag, level: 900);
      return true;
    }());

    handler.next(err);
  }

  // ─────────────────────────── HELPERS ─────────────────────────────────────

  void _formatBody(dynamic body, StringBuffer buffer) {
    if (body == null) {
      buffer.writeln('$_side    (empty)');
      return;
    }

    if (body is Map) {
      body.forEach((key, value) {
        buffer.writeln('$_side    $key: $value');
      });
      return;
    }

    if (body is List) {
      for (var i = 0; i < body.length; i++) {
        buffer.writeln('$_side    [$i]: ${body[i]}');
      }
      return;
    }

    // Fallback: stringify
    final raw = body.toString();
    // Chunk long strings to 120 chars per line for readability
    for (var offset = 0; offset < raw.length; offset += 120) {
      final end = (offset + 120).clamp(0, raw.length);
      buffer.writeln('$_side    ${raw.substring(offset, end)}');
    }
  }
}
