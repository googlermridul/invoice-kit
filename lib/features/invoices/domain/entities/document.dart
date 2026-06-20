import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart'
    show Invoice;
import 'package:invoice_kit/features/quotes/domain/entities/quote.dart'
    show Quote;

/// Lifecycle of an invoice. Persisted as an int.
enum InvoiceStatus {
  draft,
  sent,
  paid,
  overdue,
  cancelled;

  int get id => index;
  String get label => switch (this) {
    InvoiceStatus.draft => 'Draft',
    InvoiceStatus.sent => 'Sent',
    InvoiceStatus.paid => 'Paid',
    InvoiceStatus.overdue => 'Overdue',
    InvoiceStatus.cancelled => 'Cancelled',
  };

  static InvoiceStatus fromId(int id) => InvoiceStatus.values.firstWhere(
    (s) => s.id == id,
    orElse: () => InvoiceStatus.draft,
  );
}

/// Lifecycle of a quote. Persisted as an int.
enum QuoteStatus {
  draft,
  sent,
  accepted,
  declined,
  expired;

  int get id => index;
  String get label => switch (this) {
    QuoteStatus.draft => 'Draft',
    QuoteStatus.sent => 'Sent',
    QuoteStatus.accepted => 'Accepted',
    QuoteStatus.declined => 'Declined',
    QuoteStatus.expired => 'Expired',
  };

  static QuoteStatus fromId(int id) => QuoteStatus.values.firstWhere(
    (s) => s.id == id,
    orElse: () => QuoteStatus.draft,
  );
}

/// A document that can be invoiced or quoted. Concrete types are
/// [Invoice] and [Quote].
abstract class Document extends Equatable {
  const Document({
    required this.id,
    required this.number,
    required this.clientId,
    required this.issueDate,
    required this.dueDate,
    required this.currency,
    required this.items,
    this.notes,
    this.terms,
    this.taxRateOverride,
  });

  final String id;
  final String number;
  final String clientId;
  final DateTime issueDate;
  final DateTime dueDate;
  final String currency;
  final List<DocumentItem> items;
  final String? notes;
  final String? terms;

  /// Optional global tax rate applied to the subtotal after discounts.
  final double? taxRateOverride;

  /// Pre-tax sum of all line subtotals.
  double get subtotal => items.fold(0, (sum, item) => sum + item.lineSubtotal);

  /// Sum of all line tax amounts.
  double get itemTaxTotal => items.fold(0, (sum, item) => sum + item.taxAmount);

  /// Sum of all line discounts.
  double get discountTotal => items.fold(0, (sum, item) => sum + item.discount);

  /// Global tax applied at document level, after line taxes.
  double get globalTax => taxRateOverride == null
      ? 0
      : (subtotal + itemTaxTotal) * (taxRateOverride! / 100.0);

  /// Total amount due / quoted.
  double get total => subtotal + itemTaxTotal + globalTax;

  Document copyWithDocument({
    String? number,
    String? clientId,
    DateTime? issueDate,
    DateTime? dueDate,
    String? currency,
    List<DocumentItem>? items,
    String? notes,
    String? terms,
    double? taxRateOverride,
  });
}
