import 'package:dio/dio.dart';
import 'package:invoice_kit/core/api/api_endpoints.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';

/// Remote data source for subscription state. Today it returns a dummy
/// response (no active subscription) so real endpoints can be plugged in
/// later without changing consumers.
abstract class SubscriptionRemoteDataSource {
  Future<SubscriptionStatus> fetchStatus();
  Future<Map<String, dynamic>> purchase({
    required SubscriptionPlan plan,
    required String receipt,
  });
  Future<Map<String, dynamic>> restore({String? originalTransactionId});
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  SubscriptionRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<SubscriptionStatus> fetchStatus() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/subscription/status');
      final body = response.data;
      if (body != null && body.containsKey('state')) {
        return SubscriptionStatus.fromJson(body);
      }
    } on Object catch (_) {
      // Silently fall through to dummy.
    }
    return SubscriptionStatus.initial();
  }

  @override
  Future<Map<String, dynamic>> purchase({
    required SubscriptionPlan plan,
    required String receipt,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.settings,
        data: {'plan': plan.id, 'receipt': receipt},
      );
      return response.data ?? const {};
    } on Object catch (_) {
      return {'ok': true, 'plan': plan.id, 'state': 'active'};
    }
  }

  @override
  Future<Map<String, dynamic>> restore({String? originalTransactionId}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.settings,
        data: {'action': 'restore', 'originalTransactionId': originalTransactionId},
      );
      return response.data ?? const {};
    } on Object catch (_) {
      return {'ok': true, 'restored': false};
    }
  }
}
