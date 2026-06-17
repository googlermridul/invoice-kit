import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/typography/font_weights.dart';

/// Pre-baked text styles. Use these for one-off widgets; otherwise prefer
/// `Theme.of(context).textTheme`.
class AppTextStyles {
  const AppTextStyles._();

  static const TextStyle h1 = TextStyle(fontSize: 32, fontWeight: AppFontWeights.bold, height: 1.2);
  static const TextStyle h2 = TextStyle(fontSize: 28, fontWeight: AppFontWeights.bold, height: 1.2);
  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: AppFontWeights.semibold,
    height: 1.25,
  );
  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: AppFontWeights.semibold,
    height: 1.3,
  );
  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: AppFontWeights.semibold,
    height: 1.3,
  );
  static const TextStyle h6 = TextStyle(
    fontSize: 16,
    fontWeight: AppFontWeights.semibold,
    height: 1.3,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: AppFontWeights.regular,
    height: 1.5,
  );
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: AppFontWeights.regular,
    height: 1.5,
  );
  static const TextStyle bodySm = TextStyle(
    fontSize: 12,
    fontWeight: AppFontWeights.regular,
    height: 1.5,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: AppFontWeights.regular,
    height: 1.4,
  );
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: AppFontWeights.semibold,
    height: 1,
    letterSpacing: 0.4,
  );
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: AppFontWeights.semibold,
    height: 1,
    letterSpacing: 1.2,
  );
}
