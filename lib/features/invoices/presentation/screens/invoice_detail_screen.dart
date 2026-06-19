import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_colors.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/features/business_profile/data/repositories/business_profile_repository.dart';
import 'package:invoice_kit/features/business_profile/domain/entities/business_profile.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart' show InvoiceStatus;
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_kit/features/invoices/domain/services/pdf_generator.dart';
import 'package:invoice_kit/features/invoices/domain/usecases/invoice_calculator.dart';
import 'package:invoice_kit/features/invoices/presentation/bloc/invoices_cubit.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';
import 'package:printing/printing.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({required this.invoiceId, super.key});
  final String invoiceId;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InvoicesCubit>().load();
    context.read<ClientsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.go('/invoices/${widget.invoiceId}/edit'),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              final cubit = context.read<InvoicesCubit>();
              final inv = _invoice(context);
              if (inv == null) return;
              switch (v) {
                case 'duplicate':
                  final copy = await cubit.duplicate(inv);
                  await cubit.saveDuplicate(copy);
                  if (mounted) context.go('/invoices/${copy.id}');
                case 'paid':
                  await cubit.setStatus(inv, InvoiceStatus.paid);
                case 'sent':
                  await cubit.setStatus(inv, InvoiceStatus.sent);
                case 'cancel':
                  await cubit.setStatus(inv, InvoiceStatus.cancelled);
                case 'delete':
                  await cubit.remove(inv.id);
                  if (mounted) context.go('/invoices');
                case 'pdf':
                  await _openPdf(context, inv);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pdf', child: Text('Preview / share PDF')),
              PopupMenuItem(value: 'sent', child: Text('Mark as sent')),
              PopupMenuItem(value: 'paid', child: Text('Mark as paid')),
              PopupMenuItem(value: 'cancel', child: Text('Mark as cancelled')),
              PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<InvoicesCubit, InvoicesState>(
        builder: (context, state) {
          final inv = state.invoices.where((i) => i.id == widget.invoiceId).cast<Invoice?>().firstOrNull;
          if (inv == null) return const Center(child: CircularProgressIndicator());
          return BlocBuilder<ClientsCubit, ClientsState>(
            builder: (context, cstate) {
              final client = cstate.clients.where((c) => c.id == inv.clientId).cast<Client?>().firstOrNull;
              return _InvoiceBody(invoice: inv, client: client);
            },
          );
        },
      ),
    );
  }

  Invoice? _invoice(BuildContext context) {
    final s = context.read<InvoicesCubit>().state;
    return s.invoices.where((i) => i.id == widget.invoiceId).cast<Invoice?>().firstOrNull;
  }

  Future<void> _openPdf(BuildContext context, Invoice invoice) async {
    final generator = sl<PdfGenerator>();
    final profile = await sl<BusinessProfileRepository>().load() ?? _emptyProfile();
    final client = context
        .read<ClientsCubit>()
        .state
        .clients
        .where((c) => c.id == invoice.clientId)
        .cast<Client?>()
        .firstOrNull;
    final bytes = await generator.invoicePdf(
      invoice: invoice,
      business: profile,
      client: client ?? _emptyClient(invoice.clientId),
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Client _emptyClient(String id) => Client(
    id: id,
    name: 'Unknown client',
    createdAt: DateTime.now(),
  );

  BusinessProfile _emptyProfile() => const BusinessProfile(businessName: '');
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _InvoiceBody extends StatelessWidget {
  const _InvoiceBody({required this.invoice, this.client});
  final Invoice invoice;
  final Client? client;

  @override
  Widget build(BuildContext context) {
    final totals = InvoiceCalculator.forDocument(invoice);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                invoice.number,
                style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            InvoiceStatusBadge(invoice.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Billed to ${client?.name ?? "Unknown client"}',
          style: context.textTheme.bodyMedium?.copyWith(color: context.colors.outline),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _MetaTile(context, 'Issued', Formatters.date(invoice.issueDate)),
            const SizedBox(width: AppSpacing.md),
            _MetaTile(context, 'Due', Formatters.date(invoice.dueDate)),
            if (invoice.paidDate != null) ...[
              const SizedBox(width: AppSpacing.md),
              _MetaTile(context, 'Paid', Formatters.date(invoice.paidDate!)),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Column(
            children: [
              ...invoice.items.map((it) => _itemRow(context, it)),
              const Divider(height: 1),
              _kv(context, 'Subtotal', totals.subtotal, invoice.currency),
              if (totals.lineTax > 0) _kv(context, 'Line tax', totals.lineTax, invoice.currency),
              if (totals.globalTax > 0) _kv(context, 'Global tax', totals.globalTax, invoice.currency),
              _kv(context, 'Total', totals.total, invoice.currency, bold: true),
            ],
          ),
        ),
        if ((invoice.notes ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Notes', style: context.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(invoice.notes!),
        ],
        if ((invoice.terms ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Terms', style: context.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(invoice.terms!),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _itemRow(BuildContext context, DocumentItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description.isEmpty ? '—' : item.description),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.number(item.quantity)} × ${Formatters.currency(item.unitPrice)}'
                  '${item.taxRate > 0 ? '  · ${item.taxRate.toStringAsFixed(0)}% tax' : ''}',
                  style: TextStyle(color: context.colors.outline, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(Formatters.currency(item.lineTotal)),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String label, double value, String currency, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: bold ? context.textTheme.titleMedium : context.textTheme.bodyMedium),
          ),
          Text(
            Formatters.currency(value, code: currency),
            style: bold
                ? context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)
                : context.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _MetaTile(BuildContext context, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.textTheme.labelSmall?.copyWith(color: context.colors.outline)),
            const SizedBox(height: 4),
            Text(value, style: context.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
