import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Dio interceptor that prints curl commands using [debugPrint] so they appear
/// in Flutter's debug console. Compatible with Postman curl import.
class CurlLoggerInterceptor extends Interceptor {
  final bool printOnSuccess;
  final bool convertFormData;

  CurlLoggerInterceptor({
    this.printOnSuccess = true,
    this.convertFormData = true,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _printCurl(err.requestOptions, response: err.response);
    handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (printOnSuccess) {
      _printCurl(response.requestOptions, response: response);
    }
    handler.next(response);
  }

  void _printCurl(RequestOptions options, {Response? response}) {
    try {
      final curl = _toCurl(options);
      final highlightedCurl = '\x1B[1m\x1B[33m$curl\x1B[0m';

      debugPrint('\n\n\n');
      debugPrint('🚀 ═══════════════════ cURL START ═══════════════════ 🚀');
      debugPrint('\n$highlightedCurl\n');
      developer.log(highlightedCurl, name: 'cURL');
      if (response != null) {
        debugPrint('Response (${response.statusCode}):');
        debugPrint(_formatResponse(response));
        debugPrint('\n');
      }
      debugPrint('🚀 ════════════════════ cURL END ════════════════════ 🚀');
      debugPrint('\n\n\n');
    } catch (e) {
      debugPrint('CurlLoggerInterceptor: unable to create curl - $e');
    }
  }

  String _formatResponse(Response response) {
    try {
      final data = response.data;
      if (data == null) return '<empty>';
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
      return data.toString();
    } catch (_) {
      return response.data?.toString() ?? '<unable to format>';
    }
  }

  String _toCurl(RequestOptions options) {
    final url = options.uri.toString().replaceAll("'", "'\\''");
    final parts = <String>["curl --location '$url'"];

    if (options.method.toUpperCase() != 'GET') {
      parts.add("--request ${options.method}");
    }

    options.headers.forEach((k, v) {
      if (k != 'Cookie' && k.toLowerCase() != 'content-length' && v != null) {
        final escaped = v.replaceAll("'", "'\\''");
        parts.add("--header '$k: $escaped'");
      }
    });

    if (options.data != null) {
      final data = options.data;
      if (data is FormData && convertFormData) {
        // FormData: use -F for each field (proper multipart format)
        for (final f in data.fields) {
          final escaped = f.value.replaceAll("'", "'\\''");
          parts.add("--form '${f.key}=$escaped'");
        }
        for (final f in data.files) {
          parts.add("--form '${f.key}=<file:${f.value.filename ?? "upload"}>'");
        }
      } else {
        // JSON or raw body: use --data-raw (Postman-style)
        final encoded =
            data is Map || data is List ? json.encode(data) : data.toString();
        final escaped = encoded.replaceAll("'", "'\\''");
        parts.add("--data-raw '$escaped'");
      }
    }

    return parts.join(' ');
  }
}
