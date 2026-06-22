import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_kit/features/reports/domain/usecases/reports_calculator.dart';

void main() {
  group('ReportsCalculator', () {
    const calc = ReportsCalculator();
    final now = DateTime(2026, 6, 18);

    Invoice invoice({
      required String id,
      required InvoiceStatus status,
      required double total,
      String clientId = 'c1',
      DateTime? paidDate,
      DateTime? dueDate,
    }) {
      // The Invoice computes its own total from items, so the helper uses the
      // desired total as both quantity and unitPrice (single line, 1 × N).
      return Invoice(
        id: id,
        number: 'INV-1',
        clientId: clientId,
        issueDate: now.subtract(const Duration(days: 30)),
        dueDate: dueDate ?? now.subtract(const Duration(days: 14)),
        currency: 'USD',
        items: [
          DocumentItem(
            id: 'i1',
            description: 'Service',
            quantity: 1,
            unitPrice: total,
          ),
        ],
        status: status,
        paidDate: paidDate,
      );
    }

    test('empty list yields zero summary', () {
      final s = calc.summarize(const [], now);
      expect(s.totalRevenue, 0);
      expect(s.outstanding, 0);
      expect(s.paidCount, 0);
      expect(s.sentCount, 0);
      expect(s.overdueCount, 0);
      expect(s.draftCount, 0);
      expect(s.totalCount, 0);
    });

    test('paid invoices count toward revenue', () {
      final s = calc.summarize(
        [
          invoice(
            id: '1',
            status: InvoiceStatus.paid,
            total: 100,
            paidDate: now,
          ),
          invoice(
            id: '2',
            status: InvoiceStatus.paid,
            total: 250,
            paidDate: now,
          ),
        ],
        now,
      );
      expect(s.totalRevenue, 350);
      expect(s.paidCount, 2);
    });

    test('sent invoices count toward outstanding', () {
      final s = calc.summarize(
        [
          invoice(
            id: '1',
            status: InvoiceStatus.sent,
            total: 100,
            dueDate: now.add(const Duration(days: 7)),
          ),
        ],
        now,
      );
      expect(s.outstanding, 100);
      expect(s.sentCount, 1);
      expect(s.overdueCount, 0);
    });

    test('overdue invoices count toward outstanding and overdue', () {
      final s = calc.summarize(
        [
          invoice(
            id: '1',
            status: InvoiceStatus.overdue,
            total: 100,
            dueDate: now.subtract(const Duration(days: 3)),
          ),
        ],
        now,
      );
      expect(s.outstanding, 100);
      expect(s.overdueCount, 1);
    });

    test('sent invoice past due date is overdue', () {
      final s = calc.summarize(
        [
          invoice(
            id: '1',
            status: InvoiceStatus.sent,
            total: 50,
            dueDate: now.subtract(const Duration(days: 1)),
          ),
        ],
        now,
      );
      expect(s.sentCount, 0);
      expect(s.overdueCount, 1);
      expect(s.outstanding, 50);
    });

    test('drafts and cancelled do not affect totals', () {
      final s = calc.summarize(
        [
          invoice(id: '1', status: InvoiceStatus.draft, total: 999),
          invoice(id: '2', status: InvoiceStatus.cancelled, total: 999),
        ],
        now,
      );
      expect(s.totalRevenue, 0);
      expect(s.outstanding, 0);
      expect(s.draftCount, 1);
      expect(s.totalCount, 2);
    });

    test(
      'topClients ranks by total invoiced, excluding drafts and cancelled',
      () {
        final clients = {
          'a': Client(id: 'a', name: 'Alice', createdAt: now),
          'b': Client(id: 'b', name: 'Bob', createdAt: now),
          'c': Client(id: 'c', name: 'Carol', createdAt: now),
        };
        final invoices = [
          invoice(
            id: '1',
            status: InvoiceStatus.paid,
            total: 500,
            clientId: 'a',
          ),
          invoice(
            id: '2',
            status: InvoiceStatus.paid,
            total: 200,
            clientId: 'a',
          ),
          invoice(
            id: '3',
            status: InvoiceStatus.sent,
            total: 300,
            clientId: 'b',
          ),
          invoice(
            id: '4',
            status: InvoiceStatus.draft,
            total: 9999,
            clientId: 'c',
          ),
        ];
        final top = calc.topClients(
          invoices: invoices,
          clientsById: clients,
          limit: 5,
        );
        expect(top, hasLength(2));
        expect(top[0].client.id, 'a');
        expect(top[0].total, 700);
        expect(top[1].client.id, 'b');
        expect(top[1].total, 300);
      },
    );

    test('topClients filters out missing clients', () {
      final clients = {
        'a': Client(id: 'a', name: 'Alice', createdAt: now),
      };
      final invoices = [
        invoice(id: '1', status: InvoiceStatus.paid, total: 100, clientId: 'a'),
        invoice(
          id: '2',
          status: InvoiceStatus.paid,
          total: 50,
          clientId: 'unknown',
        ),
      ];
      final top = calc.topClients(invoices: invoices, clientsById: clients);
      expect(top, hasLength(1));
      expect(top.first.client.id, 'a');
    });
  });
}
