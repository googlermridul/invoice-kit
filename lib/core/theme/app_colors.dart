import 'package:flutter/material.dart';

/// Centralised colour tokens for the InvoiceKit design system.
///
/// Palette is intentionally restrained: navy primary with a cyan accent
/// and a violet highlight for premium surfaces. Light surfaces are
/// warm off-white; dark surfaces are deep navy/charcoal.
class AppColors {
  const AppColors._();

  // Brand — navy primary with cyan accent
  static const Color primary = Color(0xFF1E3A8A); // navy
  static const Color primaryDark = Color(
    0xFF172554,
  ); // darker navy for dark theme
  static const Color primaryAccent = Color(0xFF60A5FA); // sky
  static const Color tertiary = Color(0xFF0EA5B7); // cyan accent
  static const Color tertiaryDark = Color(0xFF22D3EE);

  // Premium
  static const Color premium = Color(0xFF6D5BFA); // violet
  static const Color premiumEnd = Color(0xFF8B5CF6);

  // Neutrals — light
  static const Color lightBackground = Color(0xFFFAFAF7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF4F4F1);
  static const Color lightBorder = Color(0xFFE7E5E0);
  static const Color lightText = Color(0xFF0B1220);
  static const Color lightTextMuted = Color(0xFF5B6470);

  // Neutrals — dark
  static const Color darkBackground = Color(0xFF0A0E1A);
  static const Color darkSurface = Color(0xFF121828);
  static const Color darkSurfaceAlt = Color(0xFF1A2236);
  static const Color darkBorder = Color(0xFF222B40);
  static const Color darkText = Color(0xFFF2F4F8);
  static const Color darkTextMuted = Color(0xFF9AA4B2);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color info = Color(0xFF3B82F6);

  // Status
  static const Color statusDraft = Color(0xFF71717A);
  static const Color statusSent = Color(0xFF3B82F6);
  static const Color statusPaid = Color(0xFF22C55E);
  static const Color statusOverdue = Color(0xFFEF4444);
  static const Color statusCancelled = Color(0xFFF59E0B);
  static const Color statusAccepted = Color(0xFF22C55E);
  static const Color statusDeclined = Color(0xFFEF4444);
  static const Color statusExpired = Color(0xFFD97706);

  // Premium gradient — navy → violet
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [primary, premium],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Hero gradient — navy → cyan
  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryDark, tertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Misc
  static const Color transparent = Colors.transparent;
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
}
