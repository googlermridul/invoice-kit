import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_boilerplate/core/localization/app_localizations.dart';
import 'package:flutter_boilerplate/core/theme/app_spacing.dart';
import 'package:flutter_boilerplate/shared/widgets/widgets.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _OnboardData(
      icon: Icons.bolt_outlined,
      title: 'Production-ready',
      body: 'Clean Architecture, BLoC, GetIt and GoRouter pre-wired.',
    ),
    _OnboardData(
      icon: Icons.layers_outlined,
      title: 'Feature-first',
      body: 'Scale to dozens of features without losing velocity.',
    ),
    _OnboardData(
      icon: Icons.rocket_launch_outlined,
      title: 'Ship in minutes',
      body: 'Auth, networking, theme, l10n and CI are already set up.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _Page(data: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _index == i ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _index == i
                              ? context.colors.primary
                              : context.colors.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: _index == _pages.length - 1 ? l.commonContinue : l.commonNext,
                    onPressed: () async {
                      if (_index == _pages.length - 1) {
                        context.go('/login');
                      } else {
                        await _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(onPressed: () => context.go('/login'), child: Text(l.commonSkip)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardData {
  const _OnboardData({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

class _Page extends StatelessWidget {
  const _Page({required this.data});
  final _OnboardData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 96, color: context.colors.primary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(data.title, style: context.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(color: context.colors.outline),
          ),
        ],
      ),
    );
  }
}
