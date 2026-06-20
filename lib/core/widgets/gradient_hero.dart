import 'package:flutter/material.dart';
import 'package:invoice_kit/core/theme/app_colors.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';

/// A reusable hero surface with a gradient background.
///
/// Used by the splash screen, the FX result card, the subscription
/// header, and any place that needs a premium "hero" treatment.
class GradientHero extends StatelessWidget {
  const GradientHero({
    required this.child,
    super.key,
    this.gradient,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius = AppRadius.xl,
    this.alignment = Alignment.center,
    this.border,
  });

  /// Convenience: use [AppColors.premiumGradient].
  const GradientHero.premium({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius = AppRadius.xl,
    this.alignment = Alignment.center,
    this.border,
  }) : gradient = AppColors.premiumGradient;

  /// Convenience: use [AppColors.heroGradient].
  const GradientHero.brand({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius = AppRadius.xl,
    this.alignment = Alignment.center,
    this.border,
  }) : gradient = AppColors.heroGradient;

  final Widget child;
  final LinearGradient? gradient;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Alignment alignment;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.heroGradient,
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: AppColors.white),
        child: child,
      ),
    );
  }
}
