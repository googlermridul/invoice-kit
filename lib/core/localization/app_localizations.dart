/// Lightweight stub used by [AppLocalizationsDelegate] until flutter gen-l10n
/// runs. Once generated, replace this file with the actual import from
/// `package:flutter_gen/gen_l10n/app_localizations.dart`.
library;

import 'package:flutter/widgets.dart';
import 'package:invoice_kit/core/localization/app_locales.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  factory AppLocalizations.of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(AppLocales.fallback);
  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Trivial in-memory strings; replace once `flutter gen-l10n` runs.
  String _s(String key) => key;

  String get appName => _s('appName');
  String get commonOk => _s('common_ok');
  String get commonCancel => _s('common_cancel');
  String get commonYes => _s('common_yes');
  String get commonNo => _s('common_no');
  String get commonRetry => _s('common_retry');
  String get commonContinue => _s('common_continue');
  String get commonSkip => _s('common_skip');
  String get commonDone => _s('common_done');
  String get commonNext => _s('common_next');
  String get commonBack => _s('common_back');
  String get commonSubmit => _s('common_submit');
  String get commonSave => _s('common_save');
  String get commonLoading => _s('common_loading');
  String get commonNoData => _s('common_no_data');
  String get commonErrorGeneric => _s('common_error_generic');
  String get authLogin => _s('auth_login');
  String get authRegister => _s('auth_register');
  String get authLogout => _s('auth_logout');
  String get authEmail => _s('auth_email');
  String get authPassword => _s('auth_password');
  String get authForgotPassword => _s('auth_forgot_password');
  String get authDontHaveAccount => _s('auth_dont_have_account');
  String get authAlreadyHaveAccount => _s('auth_already_have_account');
  String get authSignUp => _s('auth_signup');
  String get authSignIn => _s('auth_signin');
  String get authWelcomeBack => _s('auth_welcome_back');
  String get authCreateAccount => _s('auth_create_account');
  String get homeGreeting => _s('home_greeting');
  String get settingsTitle => _s('settings_title');
  String get settingsTheme => _s('settings_theme');
  String get settingsLanguage => _s('settings_language');
  String get settingsDarkMode => _s('settings_dark_mode');
  String get settingsAbout => _s('settings_about');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocales.supported.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
