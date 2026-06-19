import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/constants/invoice_constants.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/theme.dart';
import 'package:invoice_kit/features/invoices/domain/entities/pdf_template.dart';
import 'package:invoice_kit/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          _Section('Account'),
          BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, state) {
              return ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: const Text('Subscription'),
                subtitle: Text(
                  state.isTrialing
                      ? 'Trial · ${state.trialDaysRemaining} days left'
                      : state.isActive
                      ? 'Active · ${state.currentStatus.plan?.label ?? ''}'
                      : 'Inactive',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/subscription'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Business profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/business-profile'),
          ),
          const Divider(),
          _Section('Appearance'),
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('Match system'),
                    value: ThemeMode.system,
                    groupValue: state.mode,
                    onChanged: (m) {
                      if (m != null) context.read<ThemeBloc>().add(ThemeChanged(m));
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light'),
                    value: ThemeMode.light,
                    groupValue: state.mode,
                    onChanged: (m) {
                      if (m != null) context.read<ThemeBloc>().add(ThemeChanged(m));
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark'),
                    value: ThemeMode.dark,
                    groupValue: state.mode,
                    onChanged: (m) {
                      if (m != null) context.read<ThemeBloc>().add(ThemeChanged(m));
                    },
                  ),
                ],
              );
            },
          ),
          const Divider(),
          _Section('Defaults'),
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              final s = state.settings;
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.attach_money),
                    title: const Text('Default currency'),
                    subtitle: Text(s.currency),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pickCurrency(context, s.currency),
                  ),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf_outlined),
                    title: const Text('Default PDF template'),
                    subtitle: Text(PdfTemplateIds.displayName(s.selectedPdfTemplate)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pickTemplate(context, s.selectedPdfTemplate),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Send payment reminders'),
                    value: s.sendReminders,
                    onChanged: (v) => context.read<SettingsCubit>().setSendReminders(v),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.warning_amber_outlined),
                    title: const Text('Auto-mark overdue'),
                    value: s.markOverdueAuto,
                    onChanged: (v) => context.read<SettingsCubit>().setMarkOverdueAuto(v),
                  ),
                ],
              );
            },
          ),
          const Divider(),
          _Section('Data'),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: const Text('Backup & restore'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/backup'),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('FX rates'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/fx'),
          ),
          const Divider(),
          _Section('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('InvoiceKit'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCurrency(BuildContext context, String current) async {
    final cubit = context.read<SettingsCubit>();
    final code = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          for (final c in CurrencyCodes.common)
            ListTile(
              title: Text('${CurrencyCodes.symbolOf(c)}  $c'),
              trailing: c == current ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, c),
            ),
        ],
      ),
    );
    if (code != null) await cubit.setCurrency(code);
  }

  Future<void> _pickTemplate(BuildContext context, String current) async {
    final cubit = context.read<SettingsCubit>();
    final id = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          for (final t in PdfTemplateIds.all)
            ListTile(
              title: Text(PdfTemplateIds.displayName(t)),
              subtitle: Text(PdfTemplateIds.description(t)),
              trailing: t == current ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, t),
            ),
        ],
      ),
    );
    if (id != null) await cubit.setPdfTemplate(id);
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colors.outline,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
