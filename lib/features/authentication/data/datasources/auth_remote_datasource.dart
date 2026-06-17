import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/core/api/api_endpoints.dart';
import 'package:flutter_boilerplate/core/api/api_response.dart';
import 'package:flutter_boilerplate/features/authentication/data/models/auth_session_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthSessionModel> login({required String email, required String password});

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
  Future<AuthSessionModel> login({required String email, required String password}) async {
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
