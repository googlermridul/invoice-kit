import 'package:dio/dio.dart';
import 'package:invoice_kit/core/api/api_endpoints.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';

/// Backend-agnostic remote data source. Two implementations:
///  - `SubscriptionSupabaseDataSource` (production): hits the
///    `subscriptions` table on Supabase.
///  - `SubscriptionRemoteDataSourceImpl` (existing): hits the dummy
///    backend that today returns the initial state.
///
/// The new one is what the DI wires up; the old one is preserved so the
/// existing tests keep working.
abstract class SubscriptionSupabaseDataSource {
  Future<SubscriptionStatus> fetchForUser(String userId);
  Future<void> upsertForUser({
    required String userId,
    required SubscriptionStatus status,
  });
}

class SubscriptionSupabaseDataSourceImpl
    implements SubscriptionSupabaseDataSource {
  SubscriptionSupabaseDataSourceImpl(this._client);

  final dynamic _client; // SupabaseClient — typed as dynamic to avoid
  // the build dependency being tightly coupled here.

  @override
  Future<SubscriptionStatus> fetchForUser(String userId) async {
    final rows = await _client
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(1);
    if (rows is! List || rows.isEmpty) {
      return SubscriptionStatus.initial();
    }
    final raw = Map<String, dynamic>.from(rows.first as Map);
    return SubscriptionStatus(
      state: _parseState(raw['status']?.toString()),
      plan: raw['plan_type'] == null
          ? null
          : SubscriptionPlan.values.firstWhere(
              (p) => p.name == raw['plan_type'].toString(),
              orElse: () => SubscriptionPlan.monthly,
            ),
      trialStart: _parseDate(raw['start_date']),
      trialEnd: _parseDate(raw['expiry_date']),
      currentPeriodEnd: _parseDate(raw['expiry_date']),
      originalTransactionId: raw['purchase_token']?.toString(),
      productId: raw['product_id']?.toString(),
    );
  }

  @override
  Future<void> upsertForUser({
    required String userId,
    required SubscriptionStatus status,
  }) async {
    await _client.from('subscriptions').upsert(
      {
        'user_id': userId,
        'plan_type': status.plan?.name,
        'status': status.state.name,
        'purchase_token': status.originalTransactionId,
        'product_id': status.productId,
        'start_date': status.trialStart?.toIso8601String(),
        'expiry_date':
            status.currentPeriodEnd?.toIso8601String() ??
            status.trialEnd?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }

  SubscriptionState _parseState(String? raw) {
    if (raw == null) return SubscriptionState.none;
    return SubscriptionState.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => SubscriptionState.none,
    );
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}

/// Bridges Dio calls to the existing remote datasource — kept so the
/// Dio-based stack still works for environments without Supabase.
class SubscriptionApiBridge {
  SubscriptionApiBridge(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> ping() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.settings);
    return response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
  }
}
