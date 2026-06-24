import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime configuration loaded from environment variables.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.apiTimeoutSeconds,
    required this.enableLogging,
    required this.enableSslPinning,
    required this.locale,
  });

  /// Constructs [AppConfig] from the loaded `.env` file.
  factory AppConfig.fromEnv() {
    return AppConfig(
      environment: dotenv.maybeGet('APP_ENV') ?? 'development',
      appName: dotenv.maybeGet('APP_NAME') ?? 'Flutter Boilerplate',
      apiBaseUrl: dotenv.maybeGet('APP_BASE_URL') ?? 'https://dummyjson.com',
      supabaseUrl: dotenv.maybeGet('SUPABASE_URL') ?? '',
      supabasePublishableKey: dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY') ?? '',
      apiTimeoutSeconds: int.tryParse(dotenv.maybeGet('API_TIMEOUT_SECONDS') ?? '') ?? 30,
      enableLogging: (dotenv.maybeGet('ENABLE_LOGGING') ?? 'true') == 'true',
      enableSslPinning: (dotenv.maybeGet('ENABLE_SSL_PINNING') ?? 'false') == 'true',
      locale: dotenv.maybeGet('LOCALE') ?? 'en',
    );
  }

  final String environment;
  final String appName;
  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final int apiTimeoutSeconds;
  final bool enableLogging;
  final bool enableSslPinning;
  final String locale;

  bool get isProduction => environment == 'production';
  bool get isStaging => environment == 'staging';
  bool get isDevelopment => environment == 'development';
  String get platform => defaultPlatform;

  // The real platform string is patched in [bootstrap].
  String get defaultPlatform => 'mobile';

  /// Stub. Replaced in [bootstrap] before the first build.
  String get appVersion => '1.0.0+1';

  AppConfig copyWith({
    String? environment,
    String? appName,
    String? apiBaseUrl,
    String? supabaseUrl,
    String? supabasePublishableKey,
    int? apiTimeoutSeconds,
    bool? enableLogging,
    bool? enableSslPinning,
    String? locale,
  }) => AppConfig(
    environment: environment ?? this.environment,
    appName: appName ?? this.appName,
    apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
    supabaseUrl: supabaseUrl ?? this.supabaseUrl,
    supabasePublishableKey: supabasePublishableKey ?? this.supabasePublishableKey,
    apiTimeoutSeconds: apiTimeoutSeconds ?? this.apiTimeoutSeconds,
    enableLogging: enableLogging ?? this.enableLogging,
    enableSslPinning: enableSslPinning ?? this.enableSslPinning,
    locale: locale ?? this.locale,
  );
}
