import 'package:dio/dio.dart';
import 'package:invoice_kit/app/app_config.dart';
import 'package:invoice_kit/core/api/api_constants.dart';

/// Adds `Authorization: Bearer <token>` to every outgoing request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.config, required this.tokenProvider});

  final AppConfig config;
  final TokenProvider tokenProvider;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenProvider.accessToken();
    if (token != null && token.isNotEmpty) {
      options.headers[ApiConstants.authorization] = '${ApiConstants.bearer} $token';
    }
    options.headers[ApiConstants.xAppVersion] = config.appVersion;
    options.headers[ApiConstants.xPlatform] = config.platform;
    handler.next(options);
  }
}

/// Abstracts how the interceptor fetches the current access token.
abstract class TokenProvider {
  Future<String?> accessToken();
  Future<String?> refreshToken();
  Future<void> saveTokens({required String accessToken, required String refreshToken});
  Future<void> clearTokens();
}
