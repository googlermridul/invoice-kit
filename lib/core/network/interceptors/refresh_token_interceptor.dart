import 'dart:async';

import 'package:dio/dio.dart';
import 'package:invoice_kit/core/api/api_endpoints.dart';
import 'package:invoice_kit/core/api/api_response.dart';
import 'package:invoice_kit/core/network/interceptors/auth_interceptor.dart';
import 'package:invoice_kit/core/storage/secure_storage_service.dart';

/// Intercepts 401s, refreshes the access token once, then retries the request.
class RefreshTokenInterceptor extends Interceptor {
  RefreshTokenInterceptor({required this.secureStorage, required this.dio});

  final SecureStorageService secureStorage;
  final Dio dio;
  bool _refreshing = false;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || _refreshing) {
      return handler.next(err);
    }

    final refreshToken = await secureStorage.read('refresh_token');
    if (refreshToken == null) {
      await secureStorage.deleteAll();
      return handler.next(err);
    }

    _refreshing = true;
    try {
      final response = await dio.post<dynamic>(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'_skipRefresh': 'true'}),
      );
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        data,
        (raw) => Map<String, dynamic>.from(raw as Map),
      );
      final newAccess = api.data['accessToken'] as String?;
      final newRefresh = api.data['refreshToken'] as String? ?? refreshToken;
      if (newAccess == null) {
        await secureStorage.deleteAll();
        return handler.next(err);
      }
      await secureStorage.write('access_token', newAccess);
      await secureStorage.write('refresh_token', newRefresh);

      // Retry the original request.
      final retryResponse = await dio.fetch<dynamic>(err.requestOptions);
      return handler.resolve(retryResponse);
    } catch (_) {
      await secureStorage.deleteAll();
      return handler.next(err);
    } finally {
      _refreshing = false;
    }
  }
}

/// Concrete [TokenProvider] backed by [SecureStorageService].
class SecureStorageTokenProvider implements TokenProvider {
  SecureStorageTokenProvider(this._storage);
  final SecureStorageService _storage;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  @override
  Future<String?> accessToken() => _storage.read(_kAccess);
  @override
  Future<String?> refreshToken() => _storage.read(_kRefresh);

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(_kAccess, accessToken);
    await _storage.write(_kRefresh, refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(_kAccess);
    await _storage.delete(_kRefresh);
  }
}
