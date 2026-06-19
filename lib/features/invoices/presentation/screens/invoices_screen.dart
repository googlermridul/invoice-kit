import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/empty_state.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_kit/features/invoices/presentation/bloc/invoices_cubit.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InvoicesCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/invoices/new'),
        icon: const Icon(Icons.add),
        label: const Text('New invoice'),
      ),
      body: BlocBuilder<InvoicesCubit, InvoicesState>(
        builder: (context, state) {
          if (state.loading && state.invoices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.invoices.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No invoices yet',
              subtitle: 'Create your first invoice to bill a client.',
              actionLabel: 'Create invoice',
              onAction: () => context.go('/invoices/new'),
            );
          }
          return BlocBuilder<ClientsCubit, ClientsState>(
            builder: (context, cstate) {
              final byId = {for (final c in cstate.clients) c.id: c};
              return RefreshIndicator(
                onRefresh: () => context.read<InvoicesCubit>().load(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  itemCount: state.invoices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 2),
                  itemBuilder: (_, i) {
                    final inv = state.invoices[i];
                    final client = byId[inv.clientId];
                    return _InvoiceCard(invoice: inv, clientName: client?.name);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, this.clientName});
  final Invoice invoice;
  final String? clientName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/invoices/${invoice.id}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        invoice.number,
                        style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    InvoiceStatusBadge(invoice.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  clientName ?? 'Unknown client',
                  style: context.textTheme.bodySmall?.copyWith(color: context.colors.outline),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Formatters.currency(invoice.total, code: invoice.currency),
                        style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      'Due ${Formatters.date(invoice.dueDate)}',
                      style: context.textTheme.bodySmall?.copyWith(color: context.colors.outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
