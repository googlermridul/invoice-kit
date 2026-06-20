import 'dart:typed_data';

import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/features/business_profile/domain/entities/business_profile.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_kit/features/invoices/domain/entities/pdf_template.dart';
import 'package:invoice_kit/features/invoices/domain/usecases/invoice_calculator.dart';
import 'package:invoice_kit/features/quotes/domain/entities/quote.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generates a PDF document for an invoice or quote using one of the built-in
/// templates. Returns raw bytes so callers can preview, save, or share.
class PdfGenerator {
  const PdfGenerator();

  Future<Uint8List> invoicePdf({
    required Invoice invoice,
    required BusinessProfile business,
    required Client client,
    String? templateId,
  }) {
    final totals = InvoiceCalculator.forDocument(invoice);
    final args = _LayoutArgs(
      title: 'INVOICE',
      number: invoice.number,
      issueDate: invoice.issueDate,
      dueDate: invoice.dueDate,
      currency: invoice.currency,
      items: invoice.items,
      notes: invoice.notes ?? business.defaultNotes,
      terms: invoice.terms ?? business.defaultPaymentTerms,
      paymentInstructions: business.paymentInstructions,
      bankDetails: business.bankDetails,
      taxId: business.taxId,
      business: business,
      client: client,
      totals: totals,
      taxRateOverride: invoice.taxRateOverride,
    );
    return _build(args, templateId ?? business.selectedPdfTemplate);
  }

  Future<Uint8List> quotePdf({
    required Quote quote,
    required BusinessProfile business,
    required Client client,
    String? templateId,
  }) {
    final totals = InvoiceCalculator.forDocument(quote);
    final args = _LayoutArgs(
      title: 'QUOTE',
      number: quote.number,
      issueDate: quote.issueDate,
      dueDate: quote.dueDate,
      currency: quote.currency,
      items: quote.items,
      notes: quote.notes ?? business.defaultNotes,
      terms:
          quote.terms ?? 'This quote is valid for 30 days from the issue date.',
      paymentInstructions: null,
      bankDetails: null,
      taxId: business.taxId,
      business: business,
      client: client,
      totals: totals,
      taxRateOverride: quote.taxRateOverride,
    );
    return _build(args, templateId ?? business.selectedPdfTemplate);
  }

  Future<Uint8List> _build(_LayoutArgs a, String templateId) async {
    final doc = pw.Document(
      title: '${a.title} ${a.number}',
      author: a.business.businessName,
      creator: 'InvoiceKit',
    );

    final body = switch (templateId) {
      PdfTemplateIds.minimal => _minimalLayout(a),
      PdfTemplateIds.modern => _modernLayout(a),
      PdfTemplateIds.elegant => _elegantLayout(a),
      PdfTemplateIds.bold => _boldLayout(a),
      PdfTemplateIds.service => _serviceLayout(a),
      _ => _classicLayout(a),
    };

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [body],
      ),
    );

    return doc.save();
  }

  // ── Template layouts ──────────────────────────────────────────────────────

  pw.Widget _classicLayout(_LayoutArgs a) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _headerClassic(a),
        pw.SizedBox(height: 24),
        _billBlock(a),
        pw.SizedBox(height: 28),
        _itemsTable(a, classicTable()),
        pw.SizedBox(height: 16),
        _totals(a),
        if ((a.notes ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 24),
          _section('Notes', a.notes!),
        ],
        if ((a.terms ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _section('Terms', a.terms!),
        ],
        if ((a.paymentInstructions ?? '').isNotEmpty ||
            (a.bankDetails ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _section('Payment', _paymentText(a)),
        ],
        if ((a.taxId ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _section('Tax ID', a.taxId!),
        ],
        pw.SizedBox(height: 32),
        _footer(),
      ],
    );
  }

  pw.Widget _minimalLayout(_LayoutArgs a) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _headerMinimal(a),
        pw.SizedBox(height: 40),
        _billBlock(a, accent: PdfColors.grey700),
        pw.SizedBox(height: 32),
        _itemsTable(a, minimalTable()),
        pw.SizedBox(height: 18),
        _totals(a, accent: PdfColors.grey700),
        if ((a.notes ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 32),
          _section('Notes', a.notes!, accent: PdfColors.grey700),
        ],
        pw.SizedBox(height: 32),
        _footer(),
      ],
    );
  }

  pw.Widget _modernLayout(_LayoutArgs a) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _headerModern(a),
        pw.SizedBox(height: 28),
        _billBlock(a),
        pw.SizedBox(height: 28),
        _itemsTable(a, modernTable()),
        pw.SizedBox(height: 18),
        _totals(a),
        if ((a.notes ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 24),
          _section('Notes', a.notes!),
        ],
        if ((a.terms ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _section('Terms', a.terms!),
        ],
        pw.SizedBox(height: 32),
        _footer(),
      ],
    );
  }

  pw.Widget _elegantLayout(_LayoutArgs a) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _headerElegant(a),
        pw.SizedBox(height: 36),
        _billBlock(a, accent: PdfColors.brown700),
        pw.SizedBox(height: 32),
        _itemsTable(a, elegantTable()),
        pw.SizedBox(height: 18),
        _totals(a, accent: PdfColors.brown700),
        if ((a.notes ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 28),
          _section('Notes', a.notes!, accent: PdfColors.brown700),
        ],
        pw.SizedBox(height: 32),
        _footer(),
      ],
    );
  }

  pw.Widget _boldLayout(_LayoutArgs a) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _headerBold(a),
        pw.SizedBox(height: 28),
        _billBlock(a),
        pw.SizedBox(height: 28),
        _itemsTable(a, boldTable()),
        pw.SizedBox(height: 18),
        _totals(a),
        if ((a.notes ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 24),
          _section('Notes', a.notes!),
        ],
        if ((a.paymentInstructions ?? '').isNotEmpty ||
            (a.bankDetails ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _section('Payment', _paymentText(a)),
        ],
        pw.SizedBox(height: 32),
        _footer(),
      ],
    );
  }

  pw.Widget _serviceLayout(_LayoutArgs a) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _headerService(a),
        pw.SizedBox(height: 28),
        _billBlock(a),
        pw.SizedBox(height: 28),
        _itemsTable(a, serviceTable()),
        pw.SizedBox(height: 18),
        _totals(a),
        if ((a.notes ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 24),
          _section('Notes', a.notes!),
        ],
        if ((a.terms ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _section('Terms', a.terms!),
        ],
        pw.SizedBox(height: 32),
        _footer(),
      ],
    );
  }

  // ── Header components ─────────────────────────────────────────────────────

  pw.Widget _headerClassic(_LayoutArgs a) {
    final business = a.business;
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              business.businessName,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            if (business.ownerName != null)
              pw.Text(
                business.ownerName!,
                style: const pw.TextStyle(fontSize: 11),
              ),
            if (business.address != null)
              pw.Text(
                business.address!,
                style: const pw.TextStyle(fontSize: 10),
              ),
            if (business.email != null)
              pw.Text(business.email!, style: const pw.TextStyle(fontSize: 10)),
            if (business.phone != null)
              pw.Text(business.phone!, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              a.title,
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Number: ${a.number}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _headerMinimal(_LayoutArgs a) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          a.business.businessName,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              a.title,
              style: const pw.TextStyle(fontSize: 11, letterSpacing: 4),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              a.number,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _headerModern(_LayoutArgs a) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                a.business.businessName,
                style: pw.TextStyle(
                  fontSize: 18,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              if (a.business.email != null)
                pw.Text(
                  a.business.email!,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey300,
                  ),
                ),
              if (a.business.phone != null)
                pw.Text(
                  a.business.phone!,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey300,
                  ),
                ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                a.title,
                style: pw.TextStyle(
                  fontSize: 22,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                a.number,
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _headerElegant(_LayoutArgs a) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          a.business.businessName.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 1, color: PdfColors.brown700, width: 80),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (a.business.ownerName != null)
                  pw.Text(
                    a.business.ownerName!,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                if (a.business.address != null)
                  pw.Text(
                    a.business.address!,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                if (a.business.email != null)
                  pw.Text(
                    a.business.email!,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  a.title,
                  style: const pw.TextStyle(fontSize: 14, letterSpacing: 4),
                ),
                pw.Text(
                  a.number,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _headerBold(_LayoutArgs a) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(color: PdfColors.black),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                a.business.businessName,
                style: pw.TextStyle(
                  fontSize: 18,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (a.business.email != null)
                pw.Text(
                  a.business.email!,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey300,
                  ),
                ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                a.title,
                style: pw.TextStyle(
                  fontSize: 22,
                  color: PdfColors.amber,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                a.number,
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _headerService(_LayoutArgs a) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              a.business.businessName,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            if (a.business.ownerName != null)
              pw.Text(
                a.business.ownerName!,
                style: const pw.TextStyle(fontSize: 11),
              ),
            if (a.business.phone != null)
              pw.Text(
                a.business.phone!,
                style: const pw.TextStyle(fontSize: 10),
              ),
            if (a.business.email != null)
              pw.Text(
                a.business.email!,
                style: const pw.TextStyle(fontSize: 10),
              ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.teal700,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                a.title,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                a.number,
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bill to / dates ──────────────────────────────────────────────────────

  pw.Widget _billBlock(_LayoutArgs a, {PdfColor? accent}) {
    final dateColor = accent ?? PdfColors.blueGrey700;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Bill To',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: dateColor,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                a.client.name,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (a.client.company != null)
                pw.Text(
                  a.client.company!,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              if (a.client.address != null)
                pw.Text(
                  a.client.address!,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              if (a.client.email != null)
                pw.Text(
                  a.client.email!,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              if (a.client.phone != null)
                pw.Text(
                  a.client.phone!,
                  style: const pw.TextStyle(fontSize: 10),
                ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _dateRow('Issue date', Formatters.date(a.issueDate), dateColor),
            pw.SizedBox(height: 4),
            _dateRow('Due date', Formatters.date(a.dueDate), dateColor),
          ],
        ),
      ],
    );
  }

  pw.Widget _dateRow(String label, String value, PdfColor accent) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: accent, letterSpacing: 1.5),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  // ── Items table ──────────────────────────────────────────────────────────

  pw.TableBorder classicTable() => const pw.TableBorder(
    horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    bottom: pw.BorderSide(color: PdfColors.blueGrey900, width: 1),
  );

  pw.TableBorder minimalTable() => const pw.TableBorder(
    bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
  );

  pw.TableBorder modernTable() => const pw.TableBorder(
    horizontalInside: pw.BorderSide(color: PdfColors.white, width: 1),
    bottom: pw.BorderSide(color: PdfColors.blue900, width: 1),
  );

  pw.TableBorder elegantTable() => const pw.TableBorder(
    horizontalInside: pw.BorderSide(color: PdfColors.brown200, width: 0.5),
    bottom: pw.BorderSide(color: PdfColors.brown700, width: 1),
  );

  pw.TableBorder boldTable() =>
      pw.TableBorder.all(color: PdfColors.black, width: 0.5);

  pw.TableBorder serviceTable() => const pw.TableBorder(
    horizontalInside: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
    bottom: pw.BorderSide(color: PdfColors.teal700, width: 1),
  );

  pw.Widget _itemsTable(_LayoutArgs a, pw.TableBorder border) {
    pw.TextStyle headStyle({double size = 9, PdfColor? color}) => pw.TextStyle(
      fontSize: size,
      fontWeight: pw.FontWeight.bold,
      color: color ?? PdfColors.blueGrey900,
      letterSpacing: 1,
    );

    return pw.Table(
      border: border,
      columnWidths: const {
        0: pw.FlexColumnWidth(5),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2.5),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('DESCRIPTION', style: headStyle()),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'QTY',
                style: headStyle(),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'UNIT PRICE',
                style: headStyle(),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'AMOUNT',
                style: headStyle(),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        ...a.items.map(
          (item) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.description,
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    if (item.taxRate > 0)
                      pw.Text(
                        'Tax ${item.taxRate.toStringAsFixed(0)}%',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  _qty(item.quantity),
                  style: const pw.TextStyle(fontSize: 11),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  Formatters.currency(item.unitPrice, code: a.currency),
                  style: const pw.TextStyle(fontSize: 11),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  Formatters.currency(item.lineTotal, code: a.currency),
                  style: const pw.TextStyle(fontSize: 11),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _qty(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  // ── Totals ───────────────────────────────────────────────────────────────

  pw.Widget _totals(_LayoutArgs a, {PdfColor? accent}) {
    final totals = a.totals;
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 240,
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(
                color: accent ?? PdfColors.blueGrey900,
                width: 1,
              ),
            ),
          ),
          child: pw.Column(
            children: [
              _row(
                'Subtotal',
                Formatters.currency(totals.subtotal, code: a.currency),
              ),
              if (totals.discount > 0)
                _row(
                  'Discount',
                  '- ${Formatters.currency(totals.discount, code: a.currency)}',
                ),
              if (totals.lineTax > 0)
                _row(
                  'Tax',
                  Formatters.currency(totals.lineTax, code: a.currency),
                ),
              if (totals.globalTax > 0)
                _row(
                  'Tax (${a.taxRateOverride!.toStringAsFixed(0)}%)',
                  Formatters.currency(totals.globalTax, code: a.currency),
                ),
              pw.SizedBox(height: 6),
              pw.Container(height: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 6),
              _row(
                'Total',
                Formatters.currency(totals.total, code: a.currency),
                isBold: true,
                color: accent ?? PdfColors.blueGrey900,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _row(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isBold ? 12 : 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isBold ? 13 : 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sections / footer ────────────────────────────────────────────────────

  pw.Widget _section(String title, String body, {PdfColor? accent}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 9,
            color: accent ?? PdfColors.blueGrey700,
            letterSpacing: 1.5,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(body, style: const pw.TextStyle(fontSize: 10, lineSpacing: 2)),
      ],
    );
  }

  String _paymentText(_LayoutArgs a) {
    final parts = <String>[];
    if ((a.paymentInstructions ?? '').isNotEmpty) {
      parts.add(a.paymentInstructions!);
    }
    if ((a.bankDetails ?? '').isNotEmpty) parts.add(a.bankDetails!);
    return parts.join('\n');
  }

  pw.Widget _footer() {
    return pw.Center(
      child: pw.Text(
        'Generated with InvoiceKit',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
      ),
    );
  }
}

/// Internal bag passed to template-specific builders.
class _LayoutArgs {
  _LayoutArgs({
    required this.title,
    required this.number,
    required this.issueDate,
    required this.dueDate,
    required this.currency,
    required this.items,
    required this.notes,
    required this.terms,
    required this.paymentInstructions,
    required this.bankDetails,
    required this.taxId,
    required this.business,
    required this.client,
    required this.totals,
    required this.taxRateOverride,
  });

  final String title;
  final String number;
  final DateTime issueDate;
  final DateTime dueDate;
  final String currency;
  final List<DocumentItem> items;
  final String? notes;
  final String? terms;
  final String? paymentInstructions;
  final String? bankDetails;
  final String? taxId;
  final BusinessProfile business;
  final Client client;
  final Totals totals;
  final double? taxRateOverride;
}
