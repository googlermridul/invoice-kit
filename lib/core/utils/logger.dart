import 'package:flutter/foundation.dart';
import 'package:invoice_kit/core/constants/app_constants.dart';
import 'package:logger/logger.dart';

/// Environment-aware logger.
class AppLogger {
  AppLogger._(this._logger);

  factory AppLogger.create({required bool enabled}) => AppLogger._(
    Logger(
      filter: enabled ? ProductionFilter() : _SilentFilter(),
      printer: PrettyPrinter(
        methodCount: 1,
        errorMethodCount: 8,
        lineLength: 100,
        colors: !kReleaseMode,
        printEmojis: false,
        dateTimeFormat: DateTimeFormat.dateAndTime,
      ),
      output: ConsoleOutput(),
    ),
  );

  final Logger _logger;

  void d(dynamic message) => _logger.d(message);
  void i(dynamic message) => _logger.i(message);
  void w(dynamic message) => _logger.w(message);
  void e(dynamic message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
  void f(dynamic message, [Object? error, StackTrace? stackTrace]) =>
      _logger.f(message, error: error, stackTrace: stackTrace);

  AppLogger bootstrap() => AppLogger.create(
    enabled: !kReleaseMode && AppConstants.appName.isNotEmpty,
  );
}

class _SilentFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => false;
}
