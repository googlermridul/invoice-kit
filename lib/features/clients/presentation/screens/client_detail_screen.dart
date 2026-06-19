import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.go('/clients/${widget.clientId}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: BlocBuilder<ClientsCubit, ClientsState>(
        builder: (context, state) {
          final client = state.clients.where((c) => c.id == widget.clientId).cast<Client?>().firstOrNull;
          if (client == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final c = client;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: context.colors.primary.withValues(alpha: 0.12),
                  child: Text(
                    c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                    style: TextStyle(
                      color: context.colors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(c.name, style: context.textTheme.headlineSmall),
              ),
              const SizedBox(height: AppSpacing.lg),
              _kv('Email', c.email),
              _kv('Phone', c.phone),
              _kv('Company', c.company),
              _kv('Address', c.address),
              if ((c.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Notes', style: context.textTheme.labelMedium?.copyWith(color: context.colors.outline)),
                const SizedBox(height: AppSpacing.xs),
                Text(c.notes!),
              ],
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Text('Invoices', style: context.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _ClientInvoices(clientId: widget.clientId),
              const SizedBox(height: AppSpacing.lg),
              Text('Quotes', style: context.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _ClientQuotes(clientId: widget.clientId),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'New invoice',
                      icon: Icons.receipt_long_outlined,
                      onPressed: () => context.go('/invoices/new?clientId=${widget.clientId}'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SecondaryButton(
                      label: 'New quote',
                      icon: Icons.description_outlined,
                      onPressed: () => context.go('/quotes/new?clientId=${widget.clientId}'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kv(String k, String? v) {
    if (v == null || v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(k, style: TextStyle(color: context.colors.outline)),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final cubit = context.read<ClientsCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete client?'),
        content: const Text('Existing invoices and quotes will keep their reference.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await cubit.remove(widget.clientId);
      if (mounted) context.go('/clients');
    }
  }
}

class _ClientInvoices extends StatelessWidget {
  const _ClientInvoices({required this.clientId});
  final String clientId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientsCubit, ClientsState>(
      builder: (context, state) {
        final all = state.invoiceCountByClient[clientId] ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text('$all invoice${all == 1 ? '' : 's'} on file'),
        );
      },
    );
  }
}

class _ClientQuotes extends StatelessWidget {
  const _ClientQuotes({required this.clientId});
  final String clientId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientsCubit, ClientsState>(
      builder: (context, state) {
        final all = state.quoteCountByClient[clientId] ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text('$all quote${all == 1 ? '' : 's'} on file'),
        );
      },
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
