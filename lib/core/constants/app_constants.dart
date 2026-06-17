/// Global constants used across the application.
class AppConstants {
  const AppConstants._();

  static const String appName = 'Flutter Boilerplate';

  // Networking
  static const int apiTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;
  static const int sendTimeoutSeconds = 30;
  static const int retryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Storage
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'locale';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String hiveBoxApp = 'app_box';

  // Pagination
  static const int defaultPageSize = 20;
  static const int initialPage = 1;

  // Animation
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Supported locales
  static const String englishCode = 'en';
  static const String banglaCode = 'bn';
  static const String arabicCode = 'ar';
}
