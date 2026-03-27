import 'package:flutter/foundation.dart';

enum LogLevel { error, warning, info, debug }

class AppLogger {
  static bool _enableLogging = kDebugMode;
  static final List<String> _logHistory = [];
  static const int _maxHistory = 100;

  static void setEnableLogging(bool enable) {
    _enableLogging = enable;
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? category,
  }) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      category: category,
    );
  }

  static void warning(String message, {String? category}) {
    _log(LogLevel.warning, message, category: category);
  }

  static void info(String message, {String? category}) {
    _log(LogLevel.info, message, category: category);
  }

  static void debug(String message, {String? category}) {
    _log(LogLevel.debug, message, category: category);
  }

  static void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? category,
  }) {
    if (!_enableLogging) return;

    final timestamp = DateTime.now().toIso8601String();
    final categoryStr = category != null ? '[$category] ' : '';
    final levelStr = _levelToString(level);
    final errorStr = error != null ? '\nError: $error' : '';
    final stackStr = stackTrace != null ? '\nStackTrace:\n$stackTrace' : '';

    final logMessage =
        '$timestamp $levelStr $categoryStr$message$errorStr$stackStr';

    switch (level) {
      case LogLevel.error:
        debugPrint('❌ $logMessage');
        break;
      case LogLevel.warning:
        debugPrint('⚠️ $logMessage');
        break;
      case LogLevel.info:
        debugPrint('ℹ️ $logMessage');
        break;
      case LogLevel.debug:
        debugPrint('🔧 $logMessage');
        break;
    }

    _logHistory.add(logMessage);
    if (_logHistory.length > _maxHistory) {
      _logHistory.removeAt(0);
    }
  }

  static String _levelToString(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return '[ERROR]';
      case LogLevel.warning:
        return '[WARN]';
      case LogLevel.info:
        return '[INFO]';
      case LogLevel.debug:
        return '[DEBUG]';
    }
  }

  static List<String> getLogHistory() => List.unmodifiable(_logHistory);

  static void clearHistory() => _logHistory.clear();
}
