import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/empty_state.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/features/recurring/presentation/bloc/recurring_cubit.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  @override
  Future<void> initState() async {
    super.initState();
    await context.read<RecurringCubit>().load();
    await context.read<ClientsCubit>().load();
  }

  Future<void> _runDue() async {
    final cubit = context.read<RecurringCubit>();
    final count = await cubit.runDue();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generated $count invoice${count == 1 ? '' : 's'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: 'Run due now',
            onPressed: _runDue,
          ),
        ],
      ),
      body: BlocBuilder<RecurringCubit, RecurringState>(
        builder: (context, state) {
          if (state.loading) return const Center(child: CircularProgressIndicator());
          if (state.schedules.isEmpty) {
            return EmptyState(
              icon: Icons.repeat_rounded,
              title: 'No recurring schedules',
              subtitle: 'Set a schedule to auto-generate invoices on a daily, weekly, monthly, or yearly cadence.',
            );
          }
          return BlocBuilder<ClientsCubit, ClientsState>(
            builder: (context, cstate) {
              final byId = {for (final c in cstate.clients) c.id: c};
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: state.schedules.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final s = state.schedules[i];
                  final client = byId[s.clientId];
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                client?.name ?? 'Unknown client',
                                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Switch(
                              value: s.active,
                              onChanged: (v) async {
                                await context.read<RecurringCubit>().upsert(s.copyWith(active: v));
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${s.frequency.label} · ${s.currency}'),
                        const SizedBox(height: 4),
                        Text(
                          'Next run ${Formatters.date(s.nextRunDate)}',
                          style: TextStyle(color: context.colors.outline),
                        ),
                        if ((s.endDate) != null) ...[
                          const SizedBox(height: 4),
                          Text('Ends ${Formatters.date(s.endDate!)}', style: TextStyle(color: context.colors.outline)),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete schedule?'),
                                    content: const Text('Existing invoices generated by this schedule will remain.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton.tonal(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await context.read<RecurringCubit>().remove(s.id);
                                }
                              },
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
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
