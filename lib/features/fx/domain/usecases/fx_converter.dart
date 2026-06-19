import 'package:invoice_kit/features/fx/domain/entities/fx_rate.dart';

/// Converts between currencies using cached rates. The repository is
/// expected to provide both base→quote and quote→base; missing pairs fall back
/// to 1:1 conversion with a warning.
class FxConverter {
  const FxConverter();

  double convert({
    required double amount,
    required String from,
    required String to,
    required Iterable<FxRate> rates,
  }) {
    if (from == to) return amount;
    final match = _findRate(rates, from, to);
    if (match == null) return amount;
    return amount * match.rate;
  }

  FxRate? _findRate(Iterable<FxRate> rates, String from, String to) {
    for (final r in rates) {
      if (r.base == from && r.quote == to) return r;
      if (r.base == to && r.quote == from) {
        return FxRate(
          base: from,
          quote: to,
          rate: r.rate == 0 ? 1 : 1 / r.rate,
          updatedAt: r.updatedAt,
        );
      }
    }
    return null;
  }
}
