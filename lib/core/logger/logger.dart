import 'package:flutter_boilerplate/core/utils/logger.dart';

class CoreLogger {
  factory CoreLogger({bool enabled = true}) => CoreLogger._(AppLogger.create(enabled: enabled));
  CoreLogger._(this._logger);

  final AppLogger _logger;
  AppLogger get raw => _logger;
}
