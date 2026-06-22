import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/constants/invoice_constants.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/app_routes.dart';
import 'package:invoice_kit/core/theme/theme.dart';
import 'package:invoice_kit/core/widgets/widgets.dart';
import 'package:invoice_kit/features/invoices/domain/entities/pdf_template.dart';
import 'package:invoice_kit/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xxxl,
        ),
        children: [
          const SectionHeader(
            title: 'Account',
            uppercase: true,
            tone: SectionHeaderTone.neutral,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  BlocBuilder<SubscriptionBloc, SubscriptionState>(
                    builder: (context, state) {
                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: context.tokens.brandSubtle,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.workspace_premium_outlined,
                            color: context.colors.primary,
                          ),
                        ),
                        title: const Text('Subscription'),
                        subtitle: Text(
                          state.isTrialing
                              ? 'Trial · ${state.trialDaysRemaining} days left'
                              : state.isActive
                              ? 'Active · ${state.currentStatus.plan?.label ?? ''}'
                              : 'Inactive',
                          style: TextStyle(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            GoRouter.of(context).push(AppRoutes.subscription),
                      );
                    },
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                  ),
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.tokens.brandSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.storefront_outlined,
                        color: context.colors.primary,
                      ),
                    ),
                    title: const Text('Business profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        GoRouter.of(context).push(AppRoutes.businessProfile),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
            title: 'Appearance',
            uppercase: true,
            tone: SectionHeaderTone.neutral,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      _ThemeOption(
                        label: 'Match system',
                        value: ThemeMode.system,
                        groupValue: state.mode,
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                      ),
                      _ThemeOption(
                        label: 'Light',
                        value: ThemeMode.light,
                        groupValue: state.mode,
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                      ),
                      _ThemeOption(
                        label: 'Dark',
                        value: ThemeMode.dark,
                        groupValue: state.mode,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
            title: 'Defaults',
            uppercase: true,
            tone: SectionHeaderTone.neutral,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              final s = state.settings;
              return AppCard(
                padding: EdgeInsets.zero,
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.attach_money,
                          color: context.colors.onSurfaceVariant,
                        ),
                        title: const Text('Default currency'),
                        subtitle: Text(
                          s.currency,
                          style: TextStyle(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _pickCurrency(context, s.currency),
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.picture_as_pdf_outlined,
                          color: context.colors.onSurfaceVariant,
                        ),
                        title: const Text('Default PDF template'),
                        subtitle: Text(
                          PdfTemplateIds.displayName(s.selectedPdfTemplate),
                          style: TextStyle(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _pickTemplate(context, s.selectedPdfTemplate),
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                      ),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.notifications_outlined,
                          color: context.colors.onSurfaceVariant,
                        ),
                        title: const Text('Send payment reminders'),
                        value: s.sendReminders,
                        onChanged: (v) =>
                            context.read<SettingsCubit>().setSendReminders(v),
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                      ),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.warning_amber_outlined,
                          color: context.colors.onSurfaceVariant,
                        ),
                        title: const Text('Auto-mark overdue'),
                        value: s.markOverdueAuto,
                        onChanged: (v) =>
                            context.read<SettingsCubit>().setMarkOverdueAuto(v),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
            title: 'Data',
            uppercase: true,
            tone: SectionHeaderTone.neutral,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.cloud_sync_outlined,
                      color: context.colors.onSurfaceVariant,
                    ),
                    title: const Text('Backup & restore'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => GoRouter.of(context).push(AppRoutes.backup),
                  ),
                  const Divider(
                    height: 1,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.swap_horiz,
                      color: context.colors.onSurfaceVariant,
                    ),
                    title: const Text('FX rates'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => GoRouter.of(context).push(AppRoutes.fx),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
            title: 'About',
            uppercase: true,
            tone: SectionHeaderTone.neutral,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppCard(
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline),
                title: Text('InvoiceKit'),
                subtitle: Text('1.0.0'),
              ),
            ),
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

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.value,
    required this.groupValue,
  });

  final String label;
  final ThemeMode value;
  final ThemeMode groupValue;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      title: Text(label),
      value: value,
      // ignore: deprecated_member_use
      groupValue: groupValue,
      onChanged: (m) {
        if (m != null) context.read<ThemeBloc>().add(ThemeChanged(m));
      },
    );
  }
}
