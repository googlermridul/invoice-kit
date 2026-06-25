import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/services/document_share_service.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/features/business_profile/data/repositories/business_profile_repository.dart';
import 'package:invoice_kit/features/business_profile/domain/entities/business_profile.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart' show InvoiceStatus;
import 'package:invoice_kit/features/reports/domain/usecases/reports_calculator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generates a PDF report for a date range and offers share/save.
class ReportPdfService {
  const ReportPdfService();

  static final _dateFormat = DateFormat('MMM d, y');

  /// Renders a PDF of the supplied [summary] + [invoices] + [top clients]
  /// and returns the raw bytes.
  Future<Uint8List> build({
    required RevenueSummary summary,
    required List<ClientRevenue> topClients,
    required double totalTax,
    required DateTime start,
    required DateTime end,
    required List<({InvoiceStatus status, int count})> breakdown,
  }) async {
    final doc = pw.Document();
    final profile = await sl<BusinessProfileRepository>().load() ?? _emptyProfile();
    final logoBytes = await _loadLogoBytes(profile);
    final currency = 'USD';
    final generatedAt = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 36),
        build: (ctx) => [
          _header(profile, logoBytes, start, end, generatedAt),
          pw.SizedBox(height: 20),
          _summaryGrid(summary, currency),
          pw.SizedBox(height: 20),
          _statusBreakdown(breakdown),
          pw.SizedBox(height: 20),
          _topClientsTable(topClients, currency),
          pw.SizedBox(height: 20),
          _taxSummary(totalTax, currency),
          pw.SizedBox(height: 20),
          _footer(profile),
        ],
      ),
    );

    return doc.save();
  }

  /// Writes the PDF to a temp file and invokes the system share sheet.
  Future<void> share(Uint8List bytes, {String? subject}) async {
    await sl<DocumentShareService>().share(
      bytes,
      filename: DocumentShareService.reportFilename(),
      subject: subject ?? 'InvoiceKit Report',
    );
  }

  pw.Widget _header(
    BusinessProfile profile,
    Uint8List? logoBytes,
    DateTime start,
    DateTime end,
    DateTime generatedAt,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoBytes != null)
            pw.Container(
              width: 56,
              height: 56,
              margin: const pw.EdgeInsets.only(right: 12),
              child: pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  profile.businessName.isEmpty ? 'InvoiceKit Report' : profile.businessName,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Range: ${_dateFormat.format(start)} — ${_dateFormat.format(end)}',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Generated ${_dateFormat.format(generatedAt)}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: pw.BoxDecoration(
              color: PdfColors.indigo700,
              borderRadius: pw.BorderRadius.circular(999),
            ),
            child: pw.Text(
              'REPORT',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryGrid(RevenueSummary s, String currency) {
    pw.Widget tile(String label, String value) => pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    return pw.Row(
      children: [
        tile('Revenue', Formatters.currency(s.totalRevenue, code: currency)),
        tile('Outstanding', Formatters.currency(s.outstanding, code: currency)),
        tile('Paid', '${s.paidCount}'),
        tile('Overdue', '${s.overdueCount}'),
      ],
    );
  }

  pw.Widget _statusBreakdown(
    List<({InvoiceStatus status, int count})> breakdown,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Status Breakdown',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: breakdown
              .map(
                (e) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: _statusColor(e.status),
                    borderRadius: pw.BorderRadius.circular(999),
                  ),
                  child: pw.Text(
                    '${e.status.label} · ${e.count}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  PdfColor _statusColor(InvoiceStatus s) {
    switch (s) {
      case InvoiceStatus.paid:
        return PdfColors.green600;
      case InvoiceStatus.sent:
        return PdfColors.blue600;
      case InvoiceStatus.overdue:
        return PdfColors.red600;
      case InvoiceStatus.draft:
        return PdfColors.grey600;
      case InvoiceStatus.cancelled:
        return PdfColors.orange600;
    }
  }

  pw.Widget _topClientsTable(
    List<ClientRevenue> topClients,
    String currency,
  ) {
    if (topClients.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'No client revenue in this period.',
          style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 11),
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Top Clients',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          headerStyle: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: const pw.TextStyle(fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          cellAlignments: const {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
          },
          headers: const ['Client', 'Revenue'],
          data: [
            for (final c in topClients)
              [
                c.client.name,
                Formatters.currency(c.total, code: currency),
              ],
          ],
        ),
      ],
    );
  }

  pw.Widget _taxSummary(double totalTax, String currency) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.indigo50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Tax Collected',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.indigo700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  Formatters.currency(totalTax, code: currency),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _footer(BusinessProfile profile) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.Text(
        'Generated by InvoiceKit · ${profile.businessName.isEmpty ? 'My business' : profile.businessName}',
        style: const pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey600,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  Future<Uint8List?> _loadLogoBytes(BusinessProfile profile) async {
    final path = profile.logoPath;
    if (path == null || !File(path).existsSync()) return null;
    return File(path).readAsBytes();
  }

  BusinessProfile _emptyProfile() => const BusinessProfile(businessName: '');
}

ReportPdfService get reportPdfService => sl<ReportPdfService>();
