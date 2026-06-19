import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/empty_state.dart';
import 'package:invoice_kit/features/backup/presentation/bloc/backup_cubit.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';
import 'package:share_plus/share_plus.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _pasteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<BackupCubit>().load();
  }

  @override
  void dispose() {
    _pasteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & restore')),
      body: BlocConsumer<BackupCubit, BackupState>(
        listenWhen: (a, b) => a.message != b.message || a.error != b.error,
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.primary.withValues(alpha: 0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Export backup', style: context.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Saves all your data (business profile, clients, invoices, quotes, recurring) to a JSON file.',
                      style: context.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: state.busy ? 'Exporting…' : 'Export to file',
                      icon: Icons.cloud_download_outlined,
                      loading: state.busy,
                      onPressed: state.busy
                          ? null
                          : () async {
                              final path = await context.read<BackupCubit>().export();
                              if (!mounted) return;
                              final bytes = await context.read<BackupCubit>().exportBytes();
                              await SharePlus.instance.share(
                                ShareParams(
                                  files: [
                                    XFile.fromData(bytes, name: path.split('/').last),
                                  ],
                                  text: 'InvoiceKit backup',
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Import backup', style: context.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Paste a previously exported InvoiceKit JSON below. Imports will overwrite existing data.',
                      style: context.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _pasteCtrl,
                      minLines: 4,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        hintText: '{ "schemaVersion": 1, … }',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: [
                        SecondaryButton(
                          label: 'Paste',
                          icon: Icons.paste,
                          onPressed: () async {
                            final data = await Clipboard.getData(Clipboard.kTextPlain);
                            _pasteCtrl.text = data?.text ?? '';
                          },
                        ),
                        PrimaryButton(
                          label: 'Import',
                          icon: Icons.cloud_upload_outlined,
                          loading: state.busy,
                          onPressed: state.busy
                              ? null
                              : () async {
                                  try {
                                    final summary = await context.read<BackupCubit>().importFromString(_pasteCtrl.text);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Imported ${summary.clients} clients, ${summary.invoices} invoices',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text('Recent exports', style: context.textTheme.titleMedium),
                  ),
                  if (state.history.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        await context.read<BackupCubit>().clearHistory();
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
              if (state.history.isEmpty)
                const EmptyState(icon: Icons.history, title: 'No exports yet')
              else
                ...state.history.map(
                  (e) => ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(e.path?.split('/').last ?? e.label ?? 'Backup'),
                    subtitle: Text(
                      '${Formatters.date(e.createdAt)} · ${(e.sizeBytes / 1024).toStringAsFixed(1)} kB',
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete all local data?'),
                      content: const Text(
                        'This removes every client, invoice, quote, recurring schedule and your business profile. This cannot be undone.',
                      ),
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
                    await context.read<BackupCubit>().wipeAll();
                  }
                },
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Wipe all local data'),
              ),
            ],
          );
        },
      ),
    );
  }
}
