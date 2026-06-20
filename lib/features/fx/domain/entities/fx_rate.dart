import 'package:equatable/equatable.dart';

/// A foreign exchange rate between two currencies.
class FxRate extends Equatable {
  const FxRate({
    required this.base,
    required this.quote,
    required this.rate,
    required this.updatedAt,
  });

  factory FxRate.fromJson(Map<String, dynamic> json) => FxRate(
    base: (json['base'] ?? '').toString(),
    quote: (json['quote'] ?? '').toString(),
    rate: (json['rate'] as num?)?.toDouble() ?? 1,
    updatedAt: json['updatedAt'] == null
        ? DateTime.now()
        : DateTime.parse(json['updatedAt'] as String),
  );

  final String base;
  final String quote;
  final double rate;
  final DateTime updatedAt;

  FxRate copyWith({double? rate, DateTime? updatedAt}) => FxRate(
    base: base,
    quote: quote,
    rate: rate ?? this.rate,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'base': base,
    'quote': quote,
    'rate': rate,
    'updatedAt': updatedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [base, quote, rate, updatedAt];
}
