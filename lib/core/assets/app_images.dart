/// Type-safe access to image assets.
///
/// Add your image to `assets/images/<filename>.<ext>` and reference it via:
/// ```dart
/// Image.asset(AppImages.logo)
/// ```
abstract class AppImages {
  const AppImages._();
  static const String logo = 'assets/images/logo.png';
  static const String placeholder = 'assets/images/placeholder.png';
  static const String errorPlaceholder = 'assets/images/error.png';
  static const String emptyState = 'assets/images/empty.png';
  static const String onboarding1 = 'assets/images/onboarding_1.png';
  static const String onboarding2 = 'assets/images/onboarding_2.png';
  static const String onboarding3 = 'assets/images/onboarding_3.png';
  static const String splashLogo = 'assets/images/splash_logo.png';
}
