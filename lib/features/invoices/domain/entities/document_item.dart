import 'package:equatable/equatable.dart';

/// A single line item appearing on an invoice or quote.
class DocumentItem extends Equatable {
  const DocumentItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.taxRate = 0,
    this.discount = 0,
  });

  factory DocumentItem.fromJson(Map<String, dynamic> json) => DocumentItem(
    id: (json['id'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0,
    discount: (json['discount'] as num?)?.toDouble() ?? 0,
  );

  factory DocumentItem.empty(String id) => DocumentItem(
    id: id,
    description: '',
    quantity: 1,
    unitPrice: 0,
  );

  final String id;
  final String description;
  final double quantity;
  final double unitPrice;

  /// Tax rate as a percentage (0-100). e.g. 20 means 20%.
  final double taxRate;

  /// Discount as a flat amount per line (currency).
  final double discount;

  /// Pre-tax line subtotal = quantity * unitPrice - discount.
  double get lineSubtotal => (quantity * unitPrice) - discount;

  /// Tax amount for this line.
  double get taxAmount => lineSubtotal * (taxRate / 100.0);

  /// Total for this line (subtotal + tax).
  double get lineTotal => lineSubtotal + taxAmount;

  DocumentItem copyWith({
    String? description,
    double? quantity,
    double? unitPrice,
    double? taxRate,
    double? discount,
  }) {
    return DocumentItem(
      id: id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      discount: discount ?? this.discount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'taxRate': taxRate,
    'discount': discount,
  };

  @override
  List<Object?> get props => [id, description, quantity, unitPrice, taxRate, discount];
}
