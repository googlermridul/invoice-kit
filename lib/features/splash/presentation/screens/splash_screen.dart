import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/app_routes.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:invoice_kit/features/splash/presentation/bloc/splash_event.dart';
import 'package:invoice_kit/features/splash/presentation/bloc/splash_state.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is SplashNavigateToOnboarding) {
          context.go(AppRoutes.onboarding);
        } else if (state is SplashNavigateToSubscription) {
          context.go(AppRoutes.subscription);
        } else if (state is SplashNavigateToAuth) {
          context.go(RoutePaths.trialExpired);
        } else if (state is SplashNavigateToDevices) {
          context.go(RoutePaths.devices);
        } else if (state is SplashNavigateToHome) {
          context.go(AppRoutes.dashboard);
        } else if (state is SplashError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: BlocBuilder<SplashBloc, SplashState>(
        builder: (context, state) {
          final bloc = context.read<SplashBloc>();
          if (state is SplashInitial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              bloc.add(SplashStarted());
            });
          }

          return Scaffold(
            body: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0B1220),
                    Color(0xFF1E3A8A),
                    Color(0xFF0EA5B7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppRadius.xxl),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'InvoiceKit',
                        style: context.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Invoices, quotes & recurring billing',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
