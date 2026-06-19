import 'package:invoice_kit/app/app_config.dart' show AppConfig;

/// Hooks for SSL pinning.
///
/// To enable pinning, set [AppConfig.enableSslPinning] = true and add the
/// SHA-256 fingerprints of your API certificate in [_pinningHashes].
abstract class SslPinning {
  static const bool _enabled = false;
  static const List<String> _pinningHashes = [
    // 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  ];

  static bool get isEnabled => _enabled;
  static List<String> get hashes => List.unmodifiable(_pinningHashes);
}
