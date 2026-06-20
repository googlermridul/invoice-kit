import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/app_scaffold.dart';
import 'package:invoice_kit/core/widgets/empty_state.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
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
    return AppScaffold(
      title: 'Invoices',
      leading: const SizedBox.shrink(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => GoRouter.of(context).push(RoutePaths.invoiceNew),
        icon: const Icon(Icons.add),
        label: const Text('New invoice'),
      ),
      padding: EdgeInsets.zero,
      refreshable: true,
      onRefresh: () => context.read<InvoicesCubit>().load(),
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
              onAction: () => GoRouter.of(context).push(RoutePaths.invoiceNew),
            );
          }
          return BlocBuilder<ClientsCubit, ClientsState>(
            builder: (context, cstate) {
              final byId = {for (final c in cstate.clients) c.id: c};
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                itemCount: state.invoices.length,
                itemBuilder: (_, i) {
                  final inv = state.invoices[i];
                  final client = byId[inv.clientId];
                  return DocumentRow(
                    title: inv.number,
                    subtitle: client?.name ?? 'Unknown client',
                    amount: inv.total,
                    currency: inv.currency,
                    statusChip: InvoiceStatusBadge(inv.status),
                    amountTrailing: Text(
                      'Due ${Formatters.date(inv.dueDate)}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    onTap: () => GoRouter.of(
                      context,
                    ).push(RoutePaths.invoiceDetailPath(inv.id)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
