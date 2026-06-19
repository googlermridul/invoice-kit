import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ClientsCubit>().load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/clients/new'),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('New client'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, email, company',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<ClientsCubit>().load();
                          setState(() {});
                        },
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) {
                context.read<ClientsCubit>().search(v);
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<ClientsCubit, ClientsState>(
              builder: (context, state) {
                if (state.loading && state.clients.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.clients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: context.colors.outline),
                        const SizedBox(height: AppSpacing.md),
                        Text(state.query.isEmpty ? 'No clients yet' : 'No clients match "${state.query}"'),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: () => context.go('/clients/new'),
                          child: const Text('Add your first client'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: state.clients.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) => _ClientRow(
                    client: state.clients[i],
                    invoiceCount: state.invoiceCountByClient[state.clients[i].id] ?? 0,
                    quoteCount: state.quoteCountByClient[state.clients[i].id] ?? 0,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({
    required this.client,
    required this.invoiceCount,
    required this.quoteCount,
  });

  final Client client;
  final int invoiceCount;
  final int quoteCount;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      leading: CircleAvatar(
        backgroundColor: context.colors.primary.withValues(alpha: 0.12),
        child: Text(
          client.name.isEmpty ? '?' : client.name[0].toUpperCase(),
          style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(client.name),
      subtitle: Text(
        [
          if ((client.company ?? '').isNotEmpty) client.company!,
          if ((client.email ?? '').isNotEmpty) client.email!,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          if (invoiceCount > 0) _countChip(context, Icons.receipt_long_outlined, invoiceCount),
          if (quoteCount > 0) _countChip(context, Icons.description_outlined, quoteCount),
        ],
      ),
      onTap: () => context.go('/clients/${client.id}'),
    );
  }

  Widget _countChip(BuildContext context, IconData icon, int n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.colors.primary),
          const SizedBox(width: 4),
          Text('$n', style: context.textTheme.labelSmall?.copyWith(color: context.colors.primary)),
        ],
      ),
    );
  }
}
