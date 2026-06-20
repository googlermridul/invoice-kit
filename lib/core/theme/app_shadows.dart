import 'package:flutter/material.dart';

/// Shadow tokens. Use with [BoxShadow] inside `BoxDecoration`.
///
/// Subtle, professional, slightly-tinted shadows for a premium Dribbble look.
class AppShadows {
  const AppShadows._();

  /// Hairline shadow for cards.
  static List<BoxShadow> get xs => const [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Standard card shadow.
  static List<BoxShadow> get sm => const [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// Lifted card / modal shadow.
  static List<BoxShadow> get md => const [
    BoxShadow(
      color: Color(0x140B1220),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// Floating sheet / dialog shadow.
  static List<BoxShadow> get lg => const [
    BoxShadow(
      color: Color(0x1F0B1220),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];

  /// Brand-tinted glow for hero / premium surfaces.
  static List<BoxShadow> get brand => const [
    BoxShadow(
      color: Color(0x331E3A8A),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
}
