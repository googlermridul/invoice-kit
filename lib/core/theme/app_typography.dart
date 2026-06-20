import 'package:flutter/material.dart';

/// Typography scale for the InvoiceKit design system.
///
/// All numeric styles use tabular figures so currency columns align.
/// `color` is intentionally left to the active `ColorScheme` via
/// `apply()` rather than baked in.
class AppTypography {
  const AppTypography._();

  static const String bodyFont = 'DMSans';

  static const _tabular = [FontFeature.tabularFigures()];

  static const TextTheme textTheme = TextTheme(
    // Display — for hero numbers and splash titles
    displayLarge: TextStyle(
      fontSize: 56,
      height: 60 / 56,
      letterSpacing: -0.8,
      fontWeight: FontWeight.w700,
      fontFamily: bodyFont,
    ),
    displayMedium: TextStyle(
      fontSize: 44,
      height: 50 / 44,
      letterSpacing: -0.5,
      fontWeight: FontWeight.w700,
      fontFamily: bodyFont,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      height: 42 / 36,
      letterSpacing: -0.3,
      fontWeight: FontWeight.w600,
      fontFamily: bodyFont,
    ),

    // Headline — page titles
    headlineLarge: TextStyle(
      fontSize: 32,
      height: 38 / 32,
      letterSpacing: -0.4,
      fontWeight: FontWeight.w600,
      fontFamily: bodyFont,
      fontFeatures: _tabular,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      height: 32 / 26,
      letterSpacing: -0.3,
      fontWeight: FontWeight.w600,
      fontFamily: bodyFont,
      fontFeatures: _tabular,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      height: 28 / 22,
      letterSpacing: -0.2,
      fontWeight: FontWeight.w600,
      fontFamily: bodyFont,
    ),

    // Title — section / card titles
    titleLarge: TextStyle(
      fontSize: 20,
      height: 26 / 20,
      letterSpacing: -0.1,
      fontWeight: FontWeight.w600,
      fontFamily: bodyFont,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 22 / 16,
      letterSpacing: 0,
      fontWeight: FontWeight.w600,
      fontFamily: bodyFont,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0.1,
      fontWeight: FontWeight.w600,
      fontFamily: bodyFont,
    ),

    // Body
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      letterSpacing: 0.15,
      fontWeight: FontWeight.w400,
      fontFamily: bodyFont,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0.1,
      fontWeight: FontWeight.w400,
      fontFamily: bodyFont,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: 0.2,
      fontWeight: FontWeight.w400,
      fontFamily: bodyFont,
    ),

    // Label — buttons, chips, captions
    labelLarge: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0.1,
      fontWeight: FontWeight.w600,
      fontFamily: bodyFont,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: 0.3,
      fontWeight: FontWeight.w600,
      fontFamily: bodyFont,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 16 / 11,
      letterSpacing: 0.5,
      fontWeight: FontWeight.w600,
      fontFamily: bodyFont,
    ),
  );
}

/// Typography scale used across the app. Follows Material 3 type scale,
/// with a slight tightening for sports-tech feel.
// class AppTypography {
//   AppTypography._();

//   static const String bodyFont = 'DMSans'; // Default; can swap with Inter/Manrope.
//   static const String titleFont = 'SpaceGrotesk'; // Default; can swap with Inter/Manrope.

//   static const TextStyle displayLarge = TextStyle(
//     fontSize: 32,
//     fontFamily: titleFont,
//     fontWeight: FontWeight.w800,
//     letterSpacing: -0.5,
//     height: 1.1,
//   );

//   static const TextStyle headlineLarge = TextStyle(
//     fontSize: 26,
//     fontFamily: titleFont,
//     fontWeight: FontWeight.w700,
//     letterSpacing: -0.3,
//     height: 1.2,
//   );

//   static const TextStyle headlineMedium = TextStyle(
//     fontSize: 20,
//     fontFamily: titleFont,
//     fontWeight: FontWeight.w700,
//     height: 1.25,
//   );

//   static const TextStyle titleLarge = TextStyle(
//     fontSize: 18,
//     fontFamily: titleFont,
//     fontWeight: FontWeight.w600,
//     height: 1.3,
//   );

//   static const TextStyle titleMedium = TextStyle(
//     fontSize: 16,
//     fontFamily: titleFont,
//     fontWeight: FontWeight.w600,
//     height: 1.3,
//   );

//   static const TextStyle bodyLarge = TextStyle(
//     fontSize: 16,
//     fontFamily: bodyFont,
//     fontWeight: FontWeight.w400,
//     height: 1.45,
//   );

//   static const TextStyle bodyMedium = TextStyle(
//     fontSize: 14,
//     fontFamily: bodyFont,
//     fontWeight: FontWeight.w400,
//     height: 1.45,
//   );

//   static const TextStyle bodySmall = TextStyle(
//     fontSize: 12,
//     fontFamily: bodyFont,
//     fontWeight: FontWeight.w400,
//     height: 1.4,
//   );

//   static const TextStyle labelLarge = TextStyle(
//     fontSize: 14,
//     fontFamily: bodyFont,
//     fontWeight: FontWeight.w600,
//     letterSpacing: 0.1,
//   );

//   static const TextStyle labelMedium = TextStyle(
//     fontSize: 12,
//     fontFamily: bodyFont,
//     fontWeight: FontWeight.w600,
//     letterSpacing: 0.4,
//   );

//   static const TextStyle countdownBig = TextStyle(
//     fontSize: 28,
//     fontFamily: bodyFont,
//     fontWeight: FontWeight.w800,
//     fontFeatures: [FontFeature.tabularFigures()],
//     letterSpacing: -0.5,
//   );

//   static const TextStyle countdownSmall = TextStyle(
//     fontSize: 12,
//     fontFamily: bodyFont,
//     fontWeight: FontWeight.w600,
//     letterSpacing: 0.4,
//     fontFeatures: [FontFeature.tabularFigures()],
//   );
// }
