import 'package:equatable/equatable.dart';

/// Frequency at which a recurring invoice should be generated.
enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly;

  int get id => index;
  String get label => switch (this) {
    RecurringFrequency.daily => 'Daily',
    RecurringFrequency.weekly => 'Weekly',
    RecurringFrequency.monthly => 'Monthly',
    RecurringFrequency.quarterly => 'Quarterly',
    RecurringFrequency.yearly => 'Yearly',
  };

  static RecurringFrequency fromId(int id) =>
      RecurringFrequency.values.firstWhere((f) => f.id == id, orElse: () => RecurringFrequency.monthly);
}

/// A template for invoices that should be generated on a recurring schedule.
class RecurringInvoice extends Equatable {
  const RecurringInvoice({
    required this.id,
    required this.clientId,
    required this.frequency,
    required this.startDate,
    required this.nextRunDate,
    required this.currency,
    required this.items,
    this.endDate,
    this.notes,
    this.terms,
    this.taxRateOverride,
    this.active = true,
  });

  factory RecurringInvoice.fromJson(Map<String, dynamic> json) => RecurringInvoice(
    id: (json['id'] ?? '').toString(),
    clientId: (json['clientId'] ?? '').toString(),
    frequency: RecurringFrequency.fromId((json['frequency'] as num?)?.toInt() ?? 2),
    startDate: DateTime.parse(json['startDate'] as String),
    nextRunDate: DateTime.parse(json['nextRunDate'] as String),
    endDate: json['endDate'] == null ? null : DateTime.parse(json['endDate'] as String),
    currency: (json['currency'] ?? 'USD').toString(),
    items: (json['items'] as List<dynamic>? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    notes: json['notes'] as String?,
    terms: json['terms'] as String?,
    taxRateOverride: (json['taxRateOverride'] as num?)?.toDouble(),
    active: json['active'] as bool? ?? true,
  );

  final String id;
  final String clientId;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime nextRunDate;
  final DateTime? endDate;
  final String currency;
  final List<Map<String, dynamic>> items; // raw item json for simplicity
  final String? notes;
  final String? terms;
  final double? taxRateOverride;
  final bool active;

  RecurringInvoice copyWith({
    String? id,
    String? clientId,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? nextRunDate,
    DateTime? endDate,
    String? currency,
    List<Map<String, dynamic>>? items,
    String? notes,
    String? terms,
    double? taxRateOverride,
    bool? active,
  }) {
    return RecurringInvoice(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextRunDate: nextRunDate ?? this.nextRunDate,
      endDate: endDate ?? this.endDate,
      currency: currency ?? this.currency,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      taxRateOverride: taxRateOverride ?? this.taxRateOverride,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'frequency': frequency.id,
    'startDate': startDate.toIso8601String(),
    'nextRunDate': nextRunDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'currency': currency,
    'items': items,
    'notes': notes,
    'terms': terms,
    'taxRateOverride': taxRateOverride,
    'active': active,
  };

  @override
  List<Object?> get props => [
    id,
    clientId,
    frequency,
    startDate,
    nextRunDate,
    endDate,
    currency,
    items,
    notes,
    terms,
    taxRateOverride,
    active,
  ];
}
