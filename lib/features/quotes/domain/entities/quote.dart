import 'package:invoice_kit/features/invoices/domain/entities/document.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';

class Quote extends Document {
  const Quote({
    required super.id,
    required super.number,
    required super.clientId,
    required super.issueDate,
    required super.dueDate,
    required super.currency,
    required super.items,
    required this.status,
    super.notes,
    super.terms,
    super.taxRateOverride,
    this.validUntil,
  });

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
    id: (json['id'] ?? '').toString(),
    number: (json['number'] ?? '').toString(),
    clientId: (json['clientId'] ?? '').toString(),
    issueDate: DateTime.parse(json['issueDate'] as String),
    dueDate: DateTime.parse(json['dueDate'] as String),
    currency: (json['currency'] ?? 'USD').toString(),
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((e) => DocumentItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    notes: json['notes'] as String?,
    terms: json['terms'] as String?,
    taxRateOverride: (json['taxRateOverride'] as num?)?.toDouble(),
    status: QuoteStatus.fromId((json['status'] as num?)?.toInt() ?? 0),
    validUntil: json['validUntil'] == null ? null : DateTime.parse(json['validUntil'] as String),
  );

  final QuoteStatus status;
  final DateTime? validUntil;

  Quote copyWith({
    String? id,
    String? number,
    String? clientId,
    DateTime? issueDate,
    DateTime? dueDate,
    String? currency,
    List<DocumentItem>? items,
    String? notes,
    String? terms,
    double? taxRateOverride,
    QuoteStatus? status,
    DateTime? validUntil,
  }) {
    return Quote(
      id: id ?? this.id,
      number: number ?? this.number,
      clientId: clientId ?? this.clientId,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      currency: currency ?? this.currency,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      taxRateOverride: taxRateOverride ?? this.taxRateOverride,
      status: status ?? this.status,
      validUntil: validUntil ?? this.validUntil,
    );
  }

  @override
  Quote copyWithDocument({
    String? number,
    String? clientId,
    DateTime? issueDate,
    DateTime? dueDate,
    String? currency,
    List<DocumentItem>? items,
    String? notes,
    String? terms,
    double? taxRateOverride,
  }) => copyWith(
    number: number,
    clientId: clientId,
    issueDate: issueDate,
    dueDate: dueDate,
    currency: currency,
    items: items,
    notes: notes,
    terms: terms,
    taxRateOverride: taxRateOverride,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'clientId': clientId,
    'issueDate': issueDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'currency': currency,
    'items': items.map((e) => e.toJson()).toList(),
    'notes': notes,
    'terms': terms,
    'taxRateOverride': taxRateOverride,
    'status': status.id,
    'validUntil': validUntil?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    number,
    clientId,
    issueDate,
    dueDate,
    currency,
    items,
    notes,
    terms,
    taxRateOverride,
    status,
    validUntil,
  ];
}
