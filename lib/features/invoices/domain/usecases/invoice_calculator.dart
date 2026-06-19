import 'package:invoice_kit/features/invoices/domain/entities/document.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';

/// Centralised totals calculation used by both the domain layer and tests.
/// All inputs are treated as raw doubles; rounding is applied per currency
/// at display time, not here.
class InvoiceCalculator {
  const InvoiceCalculator._();

  /// Pre-tax sum of all line subtotals.
  static double subtotal(Iterable<DocumentItem> items) => items.fold(0, (sum, item) => sum + item.lineSubtotal);

  /// Sum of line-level tax amounts.
  static double lineTaxTotal(Iterable<DocumentItem> items) => items.fold(0, (sum, item) => sum + item.taxAmount);

  /// Sum of all line discounts.
  static double discountTotal(Iterable<DocumentItem> items) => items.fold(0, (sum, item) => sum + item.discount);

  /// Document-level tax (e.g. an extra global surcharge). Applied to
  /// `subtotal + lineTaxTotal`.
  static double globalTax(Iterable<DocumentItem> items, double? rate) {
    if (rate == null || rate == 0) return 0;
    return (subtotal(items) + lineTaxTotal(items)) * (rate / 100.0);
  }

  /// Final total of a document.
  static double total(Iterable<DocumentItem> items, {double? globalTaxRate}) =>
      subtotal(items) + lineTaxTotal(items) + globalTax(items, globalTaxRate);

  /// Convenience for documents that implement [Document].
  static Totals forDocument(Document doc) {
    final sub = subtotal(doc.items);
    final lineTax = lineTaxTotal(doc.items);
    final disc = discountTotal(doc.items);
    final gTax = globalTax(doc.items, doc.taxRateOverride);
    final grand = sub + lineTax + gTax;
    return Totals(
      subtotal: sub,
      lineTax: lineTax,
      discount: disc,
      globalTax: gTax,
      total: grand,
    );
  }
}

class Totals {
  const Totals({
    required this.subtotal,
    required this.lineTax,
    required this.discount,
    required this.globalTax,
    required this.total,
  });

  final double subtotal;
  final double lineTax;
  final double discount;
  final double globalTax;
  final double total;
}
