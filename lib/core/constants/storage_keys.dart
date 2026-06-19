/// Stable keys used for persistent storage.
class StorageKeys {
  const StorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String rememberMe = 'remember_me';
  static const String cachedProfile = 'cached_profile';

  // ── InvoiceKit ────────────────────────────────────────────────────────
  static const String appSettings = 'app_settings_v1';
  static const String businessProfile = 'business_profile_v1';
  static const String subscriptionStatus = 'subscription_status_v1';
  static const String trialStart = 'trial_start_v1';
  static const String clientNextNumber = 'client_next_number_v1';
  static const String invoiceNextNumber = 'invoice_next_number_v1';
  static const String quoteNextNumber = 'quote_next_number_v1';
  static const String fxBaseCurrency = 'fx_base_currency_v1';
  static const String fxLastUpdated = 'fx_last_updated_v1';
  static const String selectedPdfTemplate = 'selected_pdf_template_v1';
}

/// Hive box names. Centralised so tests and bootstrap stay in sync.
class HiveBoxes {
  const HiveBoxes._();

  static const String businessProfile = 'business_profile_box';
  static const String clients = 'clients_box';
  static const String invoices = 'invoices_box';
  static const String quotes = 'quotes_box';
  static const String recurring = 'recurring_box';
  static const String exports = 'exports_box';
  static const String fxRates = 'fx_rates_box';
  static const String settings = 'settings_box';
}
