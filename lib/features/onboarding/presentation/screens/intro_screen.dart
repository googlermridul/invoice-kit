import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/theme/app_tokens.dart';

/// First-touch onboarding.
///
/// Shows two intro pages and forwards the user to [RoutePaths.welcome]
/// when they tap Continue / Skip-to-last.
///
/// The intro phase does **not** start a trial and does **not** mark any
/// other onboarding flag. `StorageKeys.introOnboardingCompleted` is only
/// set from the Welcome screen, once the user has chosen a path.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pageController = PageController();
  int _index = 0;

  static const _pages = <_IntroPage>[
    _IntroPage(
      icon: Icons.receipt_long_rounded,
      title: 'Send invoices, quotes & recurring bills',
      body: 'Everything you need to bill clients and get paid — in one polished app.',
    ),
    _IntroPage(
      icon: Icons.bolt_rounded,
      title: 'Local-first, polished, fast',
      body: 'Your data stays on your device. No bloat, no friction. Start free, upgrade when you need to.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToWelcome() async {
    context.go(RoutePaths.onboardingWelcome);
  }

  Future<void> _next() async {
    if (_index < _pages.length - 1) {
      await _pageController.animateToPage(
        _index + 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      await _goToWelcome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _IntroPageView(page: _pages[i]),
              ),
            ),
            _IntroProgress(index: _index, total: _pages.length),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: isLast ? null : _goToWelcome,
                    child: const Text('Skip'),
                  ),
                  const Spacer(),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _next,
                        child: Text(isLast ? 'Get started' : 'Continue'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage {
  const _IntroPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _IntroPageView extends StatelessWidget {
  const _IntroPageView({required this.page});
  final _IntroPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.tokens.brandSubtle,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              page.icon,
              size: 44,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroProgress extends StatelessWidget {
  const _IntroProgress({required this.index, required this.total});
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final selected = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: selected ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: selected ? context.colors.primary : context.tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }
}
