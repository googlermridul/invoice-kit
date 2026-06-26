import 'package:dio/dio.dart';
import 'package:invoice_kit/core/api/api_endpoints.dart';
import 'package:invoice_kit/core/api/api_response.dart';
import 'package:invoice_kit/features/authentication/data/models/auth_session_model.dart';

/// Legacy Dio-backed auth datasource.
///
/// **Do not call this from `AuthRepositoryImpl`.** Auth (sign-up, sign-in,
/// password reset, sign-out) must go through `SupabaseAuthDataSource`, which
/// hits `https://<project>.supabase.co/auth/v1/...` via the Supabase Flutter
/// client. The Dio instance is configured with `APP_BASE_URL` (a placeholder
/// legacy backend) and would silently 404 on auth requests.
///
/// This class is preserved in DI for compile compatibility with any
/// non-auth legacy callers. New code must not introduce a dependency on it.
abstract class AuthRemoteDataSource {
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  });

  Future<AuthSessionModel> register({
    required String email,
    required String password,
    String? name,
  });

  Future<void> logout();

  Future<String> forgotPassword({required String email});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final body = response.data ?? const {};
    final parsed = ApiResponse<Map<String, dynamic>>.fromJson(
      body,
      (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return AuthSessionModel.fromJson(parsed.data);
  }

  @override
  Future<AuthSessionModel> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {'email': email, 'password': password, 'name': ?name},
    );
    final body = response.data ?? const {};
    final parsed = ApiResponse<Map<String, dynamic>>.fromJson(
      body,
      (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return AuthSessionModel.fromJson(parsed.data);
  }

  @override
  Future<void> logout() async {
    await _dio.post<dynamic>(ApiEndpoints.logout);
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
    final body = response.data ?? const {};
    return body['message']?.toString() ?? 'Password reset email sent';
  }
}
