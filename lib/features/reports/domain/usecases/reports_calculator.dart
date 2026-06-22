import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';

class RevenueSummary {
  const RevenueSummary({
    required this.totalRevenue,
    required this.outstanding,
    required this.paidCount,
    required this.overdueCount,
    required this.sentCount,
    required this.draftCount,
    required this.totalCount,
  });

  final double totalRevenue;
  final double outstanding;
  final int paidCount;
  final int overdueCount;
  final int sentCount;
  final int draftCount;
  final int totalCount;
}

class RevenueTrendPoint {
  const RevenueTrendPoint({required this.period, required this.amount});
  final DateTime period;
  final double amount;
}

class ClientRevenue {
  const ClientRevenue({required this.client, required this.total});
  final Client client;
  final double total;
}

class ReportsCalculator {
  const ReportsCalculator();

  RevenueSummary summarize(List<Invoice> invoices, DateTime now) {
    var revenue = 0.0;
    var outstanding = 0.0;
    var paid = 0;
    var overdue = 0;
    var sent = 0;
    var draft = 0;

    for (final inv in invoices) {
      switch (inv.status) {
        case InvoiceStatus.paid:
          revenue += inv.total;
          paid++;
        case InvoiceStatus.sent:
        case InvoiceStatus.overdue:
          outstanding += inv.total;
          if (inv.isOverdueOn(now)) {
            overdue++;
          } else {
            sent++;
          }
        case InvoiceStatus.draft:
          draft++;
        case InvoiceStatus.cancelled:
          break;
      }
    }

    return RevenueSummary(
      totalRevenue: revenue,
      outstanding: outstanding,
      paidCount: paid,
      overdueCount: overdue,
      sentCount: sent,
      draftCount: draft,
      totalCount: invoices.length,
    );
  }

  /// Returns monthly totals for the last [months] months, oldest first.
  List<RevenueTrendPoint> monthlyTrend(
    List<Invoice> invoices, {
    int months = 6,
  }) {
    final now = DateTime.now();
    final result = <RevenueTrendPoint>[];

    for (var i = months - 1; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
      double total = 0;
      for (final inv in invoices) {
        if (inv.status != InvoiceStatus.paid) continue;
        if (inv.paidDate == null) continue;
        if (inv.paidDate!.isBefore(monthStart) ||
            !inv.paidDate!.isBefore(monthEnd)) {
          continue;
        }
        total += inv.total;
      }
      result.add(RevenueTrendPoint(period: monthStart, amount: total));
    }

    return result;
  }

  /// Top clients by total invoiced (paid or outstanding).
  List<ClientRevenue> topClients({
    required List<Invoice> invoices,
    required Map<String, Client> clientsById,
    int limit = 5,
  }) {
    final totals = <String, double>{};
    for (final inv in invoices) {
      if (inv.status == InvoiceStatus.cancelled ||
          inv.status == InvoiceStatus.draft) {
        continue;
      }
      totals.update(
        inv.clientId,
        (v) => v + inv.total,
        ifAbsent: () => inv.total,
      );
    }
    final sorted =
        totals.entries
            .where((e) => clientsById[e.key] != null)
            .map(
              (e) => ClientRevenue(client: clientsById[e.key]!, total: e.value),
            )
            .toList()
          ..sort((a, b) => b.total.compareTo(a.total));
    return sorted.take(limit).toList();
  }

  /// Tax summary across the given invoices.
  double totalTaxCollected(List<Invoice> invoices) {
    var total = 0.0;
    for (final inv in invoices) {
      if (inv.status == InvoiceStatus.cancelled ||
          inv.status == InvoiceStatus.draft) {
        continue;
      }
      total += inv.itemTaxTotal + inv.globalTax;
    }
    return total;
  }

  /// Status breakdown as percentages.
  Map<InvoiceStatus, double> statusBreakdown(List<Invoice> invoices) {
    final counts = <InvoiceStatus, int>{};
    for (final inv in invoices) {
      counts.update(inv.status, (v) => v + 1, ifAbsent: () => 1);
    }
    final total = invoices.length;
    if (total == 0) return const {};
    return counts.map((k, v) => MapEntry(k, v / total));
  }
}
