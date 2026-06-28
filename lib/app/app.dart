import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/localization/app_locales.dart';
import 'package:invoice_kit/core/localization/app_localizations.dart';
import 'package:invoice_kit/core/router/app_router.dart';
import 'package:invoice_kit/core/router/app_router_guard.dart';
import 'package:invoice_kit/core/theme/theme.dart';
import 'package:invoice_kit/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:invoice_kit/features/premium/presentation/bloc/premium_cubit.dart';
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:invoice_kit/features/trial/presentation/cubit/trial_cubit.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final SubscriptionBloc _subscriptionBloc;
  late final PremiumCubit _premiumCubit;
  late final TrialCubit _trialCubit;
  late final AuthBloc _authBloc;
  late final AppRouter _router;

  @override
  void initState() {
    super.initState();
    _subscriptionBloc = sl<SubscriptionBloc>()
      ..add(const SubscriptionStarted());
    _premiumCubit = sl<PremiumCubit>()..refresh();
    _trialCubit = sl<TrialCubit>();
    _authBloc = sl<AuthBloc>()..add(const AuthStarted());
    _router = AppRouter(
      guard: AppRouterGuard(
        subscriptionBloc: _subscriptionBloc,
        authBloc: _authBloc,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_subscriptionBloc.close());
    unawaited(_premiumCubit.close());
    unawaited(_trialCubit.close());
    unawaited(_authBloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(create: (_) => sl<ThemeBloc>()),
        BlocProvider<SubscriptionBloc>.value(value: _subscriptionBloc),
        BlocProvider<PremiumCubit>.value(value: _premiumCubit),
        BlocProvider<TrialCubit>.value(value: _trialCubit),
        BlocProvider<AuthBloc>.value(value: _authBloc),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
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
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: media.textScaler.clamp(
                    minScaleFactor: 1,
                    maxScaleFactor: 1.25,
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
