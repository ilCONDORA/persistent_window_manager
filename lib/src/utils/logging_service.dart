// coverage:ignore-file
import 'package:logger/logger.dart';

class LoggingService {
  LoggingService._();
  static final LoggingService instance = LoggingService._();

  bool _enabled = false;

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  void enable() {
    _enabled = true;
  }

  void logInfo(String message) {
    if (_enabled) _logger.i(message);
  }

  void logWarning(String message) {
    if (_enabled) _logger.w(message);
  }

  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    if (_enabled) _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
