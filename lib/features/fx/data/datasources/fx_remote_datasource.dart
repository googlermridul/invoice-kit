import 'package:dio/dio.dart';
import 'package:invoice_kit/features/fx/domain/entities/fx_rate.dart';

abstract class FxRemoteDataSource {
  Future<List<FxRate>> fetchRates({String base = 'USD'});
}

class FxRemoteDataSourceImpl implements FxRemoteDataSource {
  FxRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<FxRate>> fetchRates({String base = 'USD'}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/fx/rates',
        queryParameters: {'base': base},
      );
      final data = response.data ?? const {};
      final list = (data['rates'] as List<dynamic>? ?? const []).whereType<Map<dynamic, dynamic>>().map((e) {
        final m = Map<String, dynamic>.from(e);
        return FxRate.fromJson({
          'base': m['base'] ?? base,
          'quote': m['quote'] ?? '',
          'rate': m['rate'] ?? 1,
          'updatedAt': m['updatedAt'] ?? DateTime.now().toIso8601String(),
        });
      }).toList();
      if (list.isNotEmpty) return list;
    } on DioException {
      // fall through to dummy
    }
    return _dummyRates(base);
  }

  List<FxRate> _dummyRates(String base) {
    final now = DateTime.now();
    final rates = {
      'USD': 1.0,
      'EUR': 0.92,
      'GBP': 0.79,
      'CAD': 1.36,
      'AUD': 1.52,
      'JPY': 156.0,
      'CNY': 7.2,
      'INR': 83.5,
      'PKR': 278.0,
      'BDT': 117.0,
      'AED': 3.67,
      'SAR': 3.75,
      'SGD': 1.34,
      'MYR': 4.7,
      'IDR': 16100.0,
      'ZAR': 18.5,
      'BRL': 5.1,
      'MXN': 17.2,
      'CHF': 0.89,
      'SEK': 10.6,
      'NOK': 10.7,
      'DKK': 6.85,
      'TRY': 32.0,
      'RUB': 91.0,
      'NGN': 1500.0,
      'KES': 130.0,
      'PHP': 56.5,
      'THB': 36.0,
      'VND': 25500.0,
    };
    final baseRate = rates[base] ?? 1.0;
    return rates.entries
        .where((e) => e.key != base)
        .map(
          (e) => FxRate(
            base: base,
            quote: e.key,
            rate: e.value / baseRate,
            updatedAt: now,
          ),
        )
        .toList();
  }
}
