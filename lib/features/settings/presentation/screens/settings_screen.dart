import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_boilerplate/core/localization/app_locales.dart';
import 'package:flutter_boilerplate/core/localization/app_localizations.dart';
import 'package:flutter_boilerplate/core/theme/theme.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          _Section(l.settingsTheme),
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('System'),
                    value: ThemeMode.system,
                    groupValue: state.mode,
                    onChanged: (mode) {
                      if (mode != null) {
                        context.read<ThemeBloc>().add(ThemeChanged(mode));
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light'),
                    value: ThemeMode.light,
                    groupValue: state.mode,
                    onChanged: (mode) {
                      if (mode != null) {
                        context.read<ThemeBloc>().add(ThemeChanged(mode));
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark'),
                    value: ThemeMode.dark,
                    groupValue: state.mode,
                    onChanged: (mode) {
                      if (mode != null) {
                        context.read<ThemeBloc>().add(ThemeChanged(mode));
                      }
                    },
                  ),
                ],
              );
            },
          ),
          //           RadioGroup<String>(
          //   groupValue: themeMode,
          //   onChanged: (value) {
          //     if (value == null) return;
          //     ref.read(themeModeProvider.notifier).set(value);
          //   },
          //   child: Column(
          //     children: const [
          //       RadioListTile<String>(value: 'system', title: Text('Match system')),
          //       RadioListTile<String>(value: 'light', title: Text('Light')),
          //       RadioListTile<String>(value: 'dark', title: Text('Dark')),
          //     ],
          //   ),
          // ),
          const Divider(),
          _Section(l.settingsLanguage),
          for (final locale in AppLocales.supported)
            ListTile(
              title: Text(locale.languageCode.toUpperCase()),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Set "supportedLocales" and persist in AppInfoService.'),
                  ),
                );
              },
            ),
          const Divider(),
          _Section(l.settingsAbout),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0+1'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Built with'),
            subtitle: const Text('Flutter • BLoC • GetIt • GoRouter'),
            onTap: () => context.go('/home'),
          ),
        ],
      ),
    );
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
