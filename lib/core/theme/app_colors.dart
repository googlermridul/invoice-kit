import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Brand
  static const Color primary = Color(0xFF1E3A8A); // navy/trust
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF172554);
  static const Color primaryAccent = Color(0xFF60A5FA);

  // Neutrals (light)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Neutrals (dark)
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceAlt = Color(0xFF1F2937);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Semantic
  static const Color success = Color(0xFF15803D);
  static const Color successLight = Color(0xFF22C55E);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);

  // Document statuses
  static const Color statusDraft = Color(0xFF64748B);
  static const Color statusSent = Color(0xFF0284C7);
  static const Color statusPaid = Color(0xFF15803D);
  static const Color statusOverdue = Color(0xFFDC2626);
  static const Color statusCancelled = Color(0xFF6B7280);
  static const Color statusAccepted = Color(0xFF15803D);
  static const Color statusDeclined = Color(0xFFDC2626);
  static const Color statusExpired = Color(0xFFB45309);

  // Premium / subscription
  static const Color premiumGradientStart = Color(0xFF1E3A8A);
  static const Color premiumGradientEnd = Color(0xFF7C3AED);

  // Misc
  static const Color transparent = Colors.transparent;
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Premium gradient
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [premiumGradientStart, premiumGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
