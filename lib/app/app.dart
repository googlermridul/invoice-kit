import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/localization/app_locales.dart';
import 'package:invoice_kit/core/localization/app_localizations.dart';
import 'package:invoice_kit/core/router/app_router.dart';
import 'package:invoice_kit/core/router/app_router_guard.dart';
import 'package:invoice_kit/core/theme/theme.dart';
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final SubscriptionBloc _subscriptionBloc;
  late final AppRouter _router;

  @override
  void initState() {
    super.initState();
    _subscriptionBloc = sl<SubscriptionBloc>()..add(const SubscriptionStarted());
    _router = AppRouter(guard: AppRouterGuard(subscriptionBloc: _subscriptionBloc));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp.router(
          title: 'InvoiceKit',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeState.mode,
          routerConfig: _router.router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocales.supported,
          localeResolutionCallback: (deviceLocale, supported) {
            if (deviceLocale == null) return AppLocales.fallback;
            return AppLocales.supported.firstWhere(
              (l) => l.languageCode == deviceLocale.languageCode,
              orElse: () => AppLocales.fallback,
            );
          },
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
