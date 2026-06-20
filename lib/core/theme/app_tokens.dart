import 'package:flutter/material.dart';
import 'package:invoice_kit/core/theme/app_colors.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_shadows.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';

///
/// Holds the things that don't fit into a [ColorScheme] but should
/// still respond to light/dark switching — borders, subtle surfaces,
/// shadows, and motion.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.border,
    required this.borderStrong,
    required this.surfaceMuted,
    required this.surfaceInverse,
    required this.onSurfaceInverse,
    required this.brandSubtle,
    required this.tertiarySubtle,
    required this.successSubtle,
    required this.warningSubtle,
    required this.errorSubtle,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
    required this.shadowBrand,
    required this.motionFast,
    required this.motionMedium,
    required this.motionSlow,
  });

  factory AppTokens.light() => AppTokens(
    border: AppColors.lightBorder,
    borderStrong: const Color(0xFFD6D3CC),
    surfaceMuted: AppColors.lightSurfaceAlt,
    surfaceInverse: AppColors.lightText,
    onSurfaceInverse: AppColors.lightBackground,
    brandSubtle: const Color(0xFFEEF2FF),
    tertiarySubtle: const Color(0xFFECFEFF),
    successSubtle: const Color(0xFFECFDF5),
    warningSubtle: const Color(0xFFFFFBEB),
    errorSubtle: const Color(0xFFFEF2F2),
    shadowSm: AppShadows.sm,
    shadowMd: AppShadows.md,
    shadowLg: AppShadows.lg,
    shadowBrand: AppShadows.brand,
    motionFast: const Duration(milliseconds: 150),
    motionMedium: const Duration(milliseconds: 240),
    motionSlow: const Duration(milliseconds: 360),
  );

  factory AppTokens.dark() => AppTokens(
    border: AppColors.darkBorder,
    borderStrong: const Color(0xFF334155),
    surfaceMuted: AppColors.darkSurfaceAlt,
    surfaceInverse: AppColors.darkText,
    onSurfaceInverse: AppColors.darkBackground,
    brandSubtle: const Color(0xFF172554),
    tertiarySubtle: const Color(0xFF083344),
    successSubtle: const Color(0xFF052E1A),
    warningSubtle: const Color(0xFF422006),
    errorSubtle: const Color(0xFF3F0F0F),
    shadowSm: const [
      BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
    ],
    shadowMd: const [
      BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 6)),
    ],
    shadowLg: const [
      BoxShadow(
        color: Color(0x55000000),
        blurRadius: 28,
        offset: Offset(0, 12),
      ),
    ],
    shadowBrand: const [
      BoxShadow(
        color: Color(0x5527274A),
        blurRadius: 24,
        offset: Offset(0, 12),
      ),
    ],
    motionFast: const Duration(milliseconds: 150),
    motionMedium: const Duration(milliseconds: 240),
    motionSlow: const Duration(milliseconds: 360),
  );

  final Color border;
  final Color borderStrong;
  final Color surfaceMuted;
  final Color surfaceInverse;
  final Color onSurfaceInverse;
  final Color brandSubtle;
  final Color tertiarySubtle;
  final Color successSubtle;
  final Color warningSubtle;
  final Color errorSubtle;
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;
  final List<BoxShadow> shadowBrand;
  final Duration motionFast;
  final Duration motionMedium;
  final Duration motionSlow;

  @override
  AppTokens copyWith({
    Color? border,
    Color? borderStrong,
    Color? surfaceMuted,
    Color? surfaceInverse,
    Color? onSurfaceInverse,
    Color? brandSubtle,
    Color? tertiarySubtle,
    Color? successSubtle,
    Color? warningSubtle,
    Color? errorSubtle,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowLg,
    List<BoxShadow>? shadowBrand,
    Duration? motionFast,
    Duration? motionMedium,
    Duration? motionSlow,
  }) {
    return AppTokens(
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceInverse: surfaceInverse ?? this.surfaceInverse,
      onSurfaceInverse: onSurfaceInverse ?? this.onSurfaceInverse,
      brandSubtle: brandSubtle ?? this.brandSubtle,
      tertiarySubtle: tertiarySubtle ?? this.tertiarySubtle,
      successSubtle: successSubtle ?? this.successSubtle,
      warningSubtle: warningSubtle ?? this.warningSubtle,
      errorSubtle: errorSubtle ?? this.errorSubtle,
      shadowSm: shadowSm ?? this.shadowSm,
      shadowMd: shadowMd ?? this.shadowMd,
      shadowLg: shadowLg ?? this.shadowLg,
      shadowBrand: shadowBrand ?? this.shadowBrand,
      motionFast: motionFast ?? this.motionFast,
      motionMedium: motionMedium ?? this.motionMedium,
      motionSlow: motionSlow ?? this.motionSlow,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceInverse: Color.lerp(surfaceInverse, other.surfaceInverse, t)!,
      onSurfaceInverse: Color.lerp(
        onSurfaceInverse,
        other.onSurfaceInverse,
        t,
      )!,
      brandSubtle: Color.lerp(brandSubtle, other.brandSubtle, t)!,
      tertiarySubtle: Color.lerp(tertiarySubtle, other.tertiarySubtle, t)!,
      successSubtle: Color.lerp(successSubtle, other.successSubtle, t)!,
      warningSubtle: Color.lerp(warningSubtle, other.warningSubtle, t)!,
      errorSubtle: Color.lerp(errorSubtle, other.errorSubtle, t)!,
      shadowSm: BoxShadow.lerpList(shadowSm, other.shadowSm, t)!,
      shadowMd: BoxShadow.lerpList(shadowMd, other.shadowMd, t)!,
      shadowLg: BoxShadow.lerpList(shadowLg, other.shadowLg, t)!,
      shadowBrand: BoxShadow.lerpList(shadowBrand, other.shadowBrand, t)!,
      motionFast: motionFast,
      motionMedium: motionMedium,
      motionSlow: motionSlow,
    );
  }
}

/// Convenience getter for the active [AppTokens].
extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;

  // Common token shortcuts.
  double get spacingXs => AppSpacing.xs;
  double get spacingSm => AppSpacing.sm;
  double get spacingMd => AppSpacing.md;
  double get spacingLg => AppSpacing.lg;
  double get spacingXl => AppSpacing.xl;
  double get spacingXxl => AppSpacing.xxl;

  double get radiusSm => AppRadius.sm;
  double get radiusMd => AppRadius.md;
  double get radiusLg => AppRadius.lg;
  double get radiusXl => AppRadius.xl;
  double get radiusPill => AppRadius.pill;
}
