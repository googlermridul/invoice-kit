import 'package:flutter/widgets.dart';
import 'package:flutter_boilerplate/core/storage/local_storage_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Reads `app_version`, `build_number`, etc. once at startup.
class AppInfoService {
  AppInfoService(this._localStorage);

  final LocalStorageService _localStorage;

  String _version = '1.0.0';
  String _buildNumber = '1';
  String _packageName = '';

  String get version => _version;
  String get buildNumber => _buildNumber;
  String get packageName => _packageName;
  String get fullVersion => '$_version+$_buildNumber';

  Future<void> load() async {
    final info = await PackageInfo.fromPlatform();
    _version = info.version;
    _buildNumber = info.buildNumber;
    _packageName = info.packageName;
  }

  /// Helper: the persisted app locale (or fallback).
  Locale? persistedLocale() {
    final code = _localStorage.getString('locale');
    if (code == null) return null;
    return Locale(code);
  }

  Future<void> persistLocale(Locale locale) async {
    await _localStorage.setString('locale', locale.languageCode);
  }
}
