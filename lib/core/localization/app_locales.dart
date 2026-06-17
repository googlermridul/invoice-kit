import 'package:flutter/widgets.dart';

/// Centralised supported locales. To add a new locale:
/// 1. Add the [Locale] below.
/// 2. Add a new app_<code>.arb to assets/translations/.
/// 3. Register it in l10n.yaml.
class AppLocales {
  const AppLocales._();

  static const Locale english = Locale('en');
  static const Locale bangla = Locale('bn');
  static const Locale arabic = Locale('ar');

  static const List<Locale> supported = [english, bangla, arabic];

  static const Locale fallback = english;

  /// RTL languages (add to this set when introducing more).
  static const Set<String> rtl = {'ar', 'he', 'fa', 'ur'};

  static bool isRtl(Locale locale) => rtl.contains(locale.languageCode);
}
