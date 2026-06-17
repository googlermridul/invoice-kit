import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_boilerplate/app/app_config.dart';
import 'package:flutter_boilerplate/core/api/api_constants.dart';
import 'package:flutter_boilerplate/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_boilerplate/core/network/interceptors/logging_interceptor.dart';
import 'package:flutter_boilerplate/core/network/interceptors/refresh_token_interceptor.dart';

/// Configures and produces a single [Dio] instance for the app.
class DioClient {
  DioClient._(this.dio);

  factory DioClient.create({
    required AppConfig config,
    required AuthInterceptor authInterceptor,
    required RefreshTokenInterceptor refreshTokenInterceptor,
    required LoggingInterceptor loggingInterceptor,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: Duration(seconds: config.apiTimeoutSeconds),
        receiveTimeout: Duration(seconds: config.apiTimeoutSeconds),
        sendTimeout: Duration(seconds: config.apiTimeoutSeconds),
        headers: {
          ApiConstants.contentType: ApiConstants.applicationJson,
          ApiConstants.accept: ApiConstants.applicationJson,
          ApiConstants.xClientType: 'mobile',
        },
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // SSL pinning (no-op by default — see security/ssl_pinning.dart).
    if (config.enableSslPinning) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient()..badCertificateCallback = (_, _, _) => false;
        return client;
      };
    }

    // Order matters: logging first, then auth (so we can read the token),
    // then refresh (which itself may inject a new token).
    dio.interceptors
      ..add(loggingInterceptor)
      ..add(authInterceptor)
      ..add(refreshTokenInterceptor);

    return DioClient._(dio);
  }

  final Dio dio;
}
