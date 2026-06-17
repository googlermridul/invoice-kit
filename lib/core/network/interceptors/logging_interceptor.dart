import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/core/utils/logger.dart';

/// Logs request/response bodies in development, no-ops in release.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({required this.logger, required this.enabled});

  final AppLogger logger;
  final bool enabled;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      logger.i('→ ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (enabled) {
      logger.i(
        '← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      logger.e(
        '× ${err.response?.statusCode ?? 'ERR'} ${err.requestOptions.method} ${err.requestOptions.uri} :: ${err.message}',
      );
    }
    handler.next(err);
  }
}
