import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_kit/features/invoices/domain/usecases/invoice_calculator.dart';

void main() {
  group('InvoiceCalculator', () {
    final now = DateTime(2026, 1, 1);

    DocumentItem item({
      String id = 'i',
      String description = 'Service',
      double quantity = 1,
      double unitPrice = 100,
      double taxRate = 0,
      double discount = 0,
    }) =>
        DocumentItem(
          id: id,
          description: description,
          quantity: quantity,
          unitPrice: unitPrice,
          taxRate: taxRate,
          discount: discount,
        );

    Invoice makeInvoice(List<DocumentItem> items, {double? globalTax}) => Invoice(
          id: 'inv1',
          number: 'INV-00001',
          clientId: 'c1',
          issueDate: now,
          dueDate: now.add(const Duration(days: 14)),
          currency: 'USD',
          items: items,
          taxRateOverride: globalTax,
          status: InvoiceStatus.draft,
        );

    test('empty items yields all zeros', () {
      final t = InvoiceCalculator.forDocument(makeInvoice(const []));
      expect(t.subtotal, 0);
      expect(t.lineTax, 0);
      expect(t.discount, 0);
      expect(t.globalTax, 0);
      expect(t.total, 0);
    });

    test('quantity × unit price minus discount = line subtotal', () {
      final items = [item(quantity: 3, unitPrice: 50, discount: 20)];
      final t = InvoiceCalculator.forDocument(makeInvoice(items));
      expect(t.subtotal, 130); // 150 - 20
      expect(t.discount, 20);
    });

    test('per-item tax is applied to (qty*price - discount)', () {
      final items = [item(quantity: 2, unitPrice: 100, taxRate: 10, discount: 0)];
      final t = InvoiceCalculator.forDocument(makeInvoice(items));
      expect(t.subtotal, 200);
      expect(t.lineTax, 20); // 200 * 0.10
      expect(t.total, 220);
    });

    test('global tax stacks on top of line taxes', () {
      final items = [item(quantity: 1, unitPrice: 100, taxRate: 20)];
      // subtotal=100, lineTax=20; globalTax on (100+20) @ 5% = 6; total=126
      final t = InvoiceCalculator.forDocument(makeInvoice(items, globalTax: 5));
      expect(t.globalTax, 6);
      expect(t.total, 126);
    });

    test('zero global tax rate is a no-op', () {
      final items = [item(quantity: 1, unitPrice: 100)];
      final t = InvoiceCalculator.forDocument(makeInvoice(items, globalTax: 0));
      expect(t.globalTax, 0);
      expect(t.total, 100);
    });

    test('multi-item totals are summed correctly', () {
      final items = [
        item(id: 'a', quantity: 2, unitPrice: 25, taxRate: 10), // 50 + 5
        item(id: 'b', quantity: 1, unitPrice: 75, taxRate: 20, discount: 5), // 70 + 14
      ];
      final t = InvoiceCalculator.forDocument(makeInvoice(items));
      expect(t.subtotal, 120); // 50 + 70
      expect(t.lineTax, 19); // 5 + 14
      expect(t.discount, 5);
      expect(t.total, 139);
    });

    test('discount and tax interact', () {
      // qty=1, price=200, discount=50, tax=10%
      // subtotal = 200 - 50 = 150
      // line tax = 150 * 0.10 = 15
      // total = 165
      final items = [item(quantity: 1, unitPrice: 200, discount: 50, taxRate: 10)];
      final t = InvoiceCalculator.forDocument(makeInvoice(items));
      expect(t.subtotal, 150);
      expect(t.lineTax, 15);
      expect(t.total, 165);
    });
  });
}
