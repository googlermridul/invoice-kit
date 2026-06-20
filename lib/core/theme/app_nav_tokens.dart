import 'package:flutter/material.dart';
import 'package:invoice_kit/core/theme/app_colors.dart';

/// Theme extension that holds bottom-navigation-specific tokens.
///
/// These are kept out of [ColorScheme] because the nav bar has its own
/// "frosted, slightly elevated" look — background, hairline border, and
/// the pill behind the active tab.
@immutable
class AppNavTokens extends ThemeExtension<AppNavTokens> {
  const AppNavTokens({
    required this.background,
    required this.border,
    required this.activeColor,
    required this.inactiveColor,
    required this.activePill,
    required this.label,
    required this.shadow,
  });

  factory AppNavTokens.light() => const AppNavTokens(
    background: AppColors.lightSurface,
    border: AppColors.lightBorder,
    activeColor: AppColors.primary,
    inactiveColor: AppColors.lightTextMuted,
    activePill: Color(0xFFEEF2FF),
    label: AppColors.primary,
    shadow: [
      BoxShadow(
        color: Color(0x0A0B1220),
        blurRadius: 24,
        offset: Offset(0, -4),
      ),
    ],
  );

  factory AppNavTokens.dark() => const AppNavTokens(
    background: Color(0xFF0E1424),
    border: AppColors.darkBorder,
    activeColor: AppColors.primaryAccent,
    inactiveColor: AppColors.darkTextMuted,
    activePill: Color(0xFF172554),
    label: AppColors.primaryAccent,
    shadow: [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 24,
        offset: Offset(0, -4),
      ),
    ],
  );

  final Color background;
  final Color border;
  final Color activeColor;
  final Color inactiveColor;
  final Color activePill;
  final Color label;
  final List<BoxShadow> shadow;

  @override
  AppNavTokens copyWith({
    Color? background,
    Color? border,
    Color? activeColor,
    Color? inactiveColor,
    Color? activePill,
    Color? label,
    List<BoxShadow>? shadow,
  }) {
    return AppNavTokens(
      background: background ?? this.background,
      border: border ?? this.border,
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      activePill: activePill ?? this.activePill,
      label: label ?? this.label,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppNavTokens lerp(ThemeExtension<AppNavTokens>? other, double t) {
    if (other is! AppNavTokens) return this;
    return AppNavTokens(
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      activeColor: Color.lerp(activeColor, other.activeColor, t)!,
      inactiveColor: Color.lerp(inactiveColor, other.inactiveColor, t)!,
      activePill: Color.lerp(activePill, other.activePill, t)!,
      label: Color.lerp(label, other.label, t)!,
      shadow: BoxShadow.lerpList(shadow, other.shadow, t)!,
    );
  }
}

/// Convenience getter for the active [AppNavTokens].
extension AppNavTokensX on BuildContext {
  AppNavTokens get navTokens => Theme.of(this).extension<AppNavTokens>()!;
}
