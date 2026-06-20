import 'package:flutter/material.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_colors.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/theme/app_tokens.dart';

/// Visual variant for [AppCard].
enum AppCardVariant { outlined, elevated, tinted, filled }

/// Standardised card surface used across the app.
///
/// Replaces the recurring `Container(borderRadius: 16, border: outlineVariant,
/// color: surface)` recipe. By default uses an outlined surface; pass
/// `elevation: true` to add a soft shadow for hero surfaces.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.variant = AppCardVariant.outlined,
    this.radius = AppRadius.lg,
    this.borderColor,
    this.backgroundColor,
    this.elevation = false,
    this.margin,
  });

  /// Card with no internal padding so the child controls it.
  const AppCard.bleed({
    required this.child,
    super.key,
    this.onTap,
    this.variant = AppCardVariant.outlined,
    this.radius = AppRadius.lg,
    this.borderColor,
    this.backgroundColor,
    this.elevation = false,
    this.margin,
  }) : padding = EdgeInsets.zero;

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final AppCardVariant variant;
  final double radius;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool elevation;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = context.colors;

    final Color bg;
    final Color border;

    switch (variant) {
      case AppCardVariant.outlined:
        bg = backgroundColor ?? scheme.surface;
        border = borderColor ?? tokens.border;
      case AppCardVariant.elevated:
        bg = backgroundColor ?? scheme.surface;
        border = borderColor ?? AppColors.transparent;
      case AppCardVariant.tinted:
        bg = backgroundColor ?? tokens.brandSubtle;
        border = borderColor ?? AppColors.transparent;
      case AppCardVariant.filled:
        bg = backgroundColor ?? tokens.surfaceMuted;
        border = borderColor ?? AppColors.transparent;
    }

    final shape = BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      border: border == AppColors.transparent ? null : Border.all(color: border, width: 1),
      boxShadow: elevation ? tokens.shadowSm : null,
    );

    if (onTap == null) {
      return Container(
        margin: margin,
        decoration: shape,
        padding: padding,
        child: child,
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            decoration: shape.copyWith(
              boxShadow: elevation ? tokens.shadowSm : null,
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
