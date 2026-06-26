/// InvoiceKit-wide constants. Keep magic numbers / strings out of features.
class InvoiceConstants {
  const InvoiceConstants._();

  // Trial & subscription
  static const Duration trialDuration = Duration(minutes: 2);

  // Recurring invoice generation safety
  static const int maxRecurringCatchup = 50;

  // Backup
  static const int backupSchemaVersion = 1;
  static const String backupMime = 'application/json';
  static const String backupFilePrefix = 'invoicekit_backup_';

  // Default currency
  static const String defaultCurrencyCode = 'USD';
  static const String defaultCurrencySymbol = r'$';

  // Default prefixes
  static const String defaultInvoicePrefix = 'INV-';
  static const String defaultQuotePrefix = 'QUO-';

  // PDF
  static const String pdfTemplateClassic = 'classic';
  static const String pdfTemplateMinimal = 'minimal';
  static const String pdfTemplateModern = 'modern';
  static const String pdfTemplateElegant = 'elegant';
  static const String pdfTemplateBold = 'bold';
  static const String pdfTemplateService = 'service';
}

/// Common ISO 4217 currency codes (offline-friendly subset).
class CurrencyCodes {
  const CurrencyCodes._();

  static const List<String> common = [
    'USD',
    'EUR',
    'GBP',
    'CAD',
    'AUD',
    'NZD',
    'JPY',
    'CNY',
    'INR',
    'PKR',
    'BDT',
    'AED',
    'SAR',
    'SGD',
    'MYR',
    'IDR',
    'ZAR',
    'BRL',
    'MXN',
    'CHF',
    'SEK',
    'NOK',
    'DKK',
    'TRY',
    'RUB',
    'NGN',
    'KES',
    'PHP',
    'THB',
    'VND',
  ];

  /// All supported currency codes (common subset).
  static List<String> get codes => List<String>.unmodifiable(common);

  /// Returns the symbol commonly used for a currency code (best-effort).
  static String symbolOf(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
      case 'CAD':
      case 'AUD':
      case 'NZD':
      case 'SGD':
      case 'HKD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
      case 'CNY':
        return '¥';
      case 'INR':
        return '₹';
      case 'PKR':
      case 'BDT':
        return '₨';
      case 'AED':
      case 'SAR':
        return '﷼';
      case 'CHF':
        return 'CHF';
      case 'RUB':
        return '₽';
      case 'TRY':
        return '₺';
      case 'BRL':
        return r'R$';
      case 'MXN':
        return r'MX$';
      case 'ZAR':
        return 'R';
      case 'NGN':
        return '₦';
      case 'KES':
        return 'KSh';
      case 'PHP':
        return '₱';
      case 'THB':
        return '฿';
      case 'VND':
        return '₫';
      case 'IDR':
        return 'Rp';
      case 'SEK':
        return 'kr';
      case 'NOK':
      case 'DKK':
        return 'kr';
      default:
        return code;
    }
  }
}
