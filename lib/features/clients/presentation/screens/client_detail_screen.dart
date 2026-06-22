import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/theme/app_tokens.dart';
import 'package:invoice_kit/core/widgets/app_card.dart';
import 'package:invoice_kit/core/widgets/app_scaffold.dart';
import 'package:invoice_kit/core/widgets/kv_row.dart';
import 'package:invoice_kit/core/widgets/section_header.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/shared/dialogs/app_dialog.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({required this.clientId, super.key});
  final String clientId;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ClientsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Client',
      actions: [
        IconButton(
          icon: const Icon(HugeIconsStroke.edit02, size: 18),
          tooltip: 'Edit',
          onPressed: () => GoRouter.of(context).push(
            RoutePaths.clientEditPath(widget.clientId),
          ),
        ),
        IconButton(
          icon: const Icon(HugeIconsStroke.delete01, size: 18),
          tooltip: 'Delete',
          onPressed: _confirmDelete,
        ),
      ],
      body: BlocBuilder<ClientsCubit, ClientsState>(
        builder: (context, state) {
          final client = state.clients.where((c) => c.id == widget.clientId).cast<Client?>().firstOrNull;
          if (client == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final c = client;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xs,
            ),
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.tokens.brandSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Text(
                    c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                    style: context.textTheme.displaySmall?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  c.name,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  children: [
                    KvRow(label: 'Email', value: c.email ?? '—'),
                    KvRow(label: 'Phone', value: c.phone ?? '—'),
                    KvRow(label: 'Company', value: c.company ?? '—'),
                    KvRow(label: 'Address', value: c.address ?? '—'),
                  ],
                ),
              ),
              if ((c.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Notes',
                        padding: EdgeInsets.zero,
                        uppercase: true,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(c.notes!),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'New invoice',
                      icon: Icons.receipt_long_outlined,
                      onPressed: () => GoRouter.of(
                        context,
                      ).push('/invoices/new?clientId=${widget.clientId}'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SecondaryButton(
                      label: 'New quote',
                      icon: Icons.description_outlined,
                      onPressed: () => GoRouter.of(
                        context,
                      ).push('/quotes/new?clientId=${widget.clientId}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _RelatedSummary(clientId: widget.clientId),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Delete client?',
      message:
          'Existing invoices and quotes will keep their reference. '
          'This cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    final cubit = context.read<ClientsCubit>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await cubit.remove(widget.clientId);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Client deleted')));
      router.pop();
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete client: $e')),
      );
    }
  }
}

class _RelatedSummary extends StatelessWidget {
  const _RelatedSummary({required this.clientId});
  final String clientId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientsCubit, ClientsState>(
      builder: (context, state) {
        final invoices = state.invoiceCountByClient[clientId] ?? 0;
        final quotes = state.quoteCountByClient[clientId] ?? 0;
        return Row(
          children: [
            Expanded(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVOICES',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$invoices',
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUOTES',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$quotes',
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
