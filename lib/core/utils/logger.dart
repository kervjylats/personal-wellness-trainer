// lib/core/utils/logger.dart
//
// Centralised logging for App Engine.
// NEVER use print() anywhere in the codebase.
// Always use AppLogger.info(), .warning(), .error(), or .debug().
//
// Uses dart:developer log() so output appears in the Flutter DevTools
// log stream and is filterable by name/level.
//
// Log levels (following standard syslog convention):
//   debug   → 500  (debug builds only — stripped in release via assert)
//   info    → 800  (normal operational messages)
//   warning → 900  (unexpected but handled situations)
//   error   → 1000 (errors that need attention)

import 'dart:developer' as developer;

abstract final class AppLogger {
  static const String _defaultTag = 'AppEngine';

  /// Logs an informational message.
  /// Use for normal operational events: config loaded, user signed in, etc.
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _defaultTag,
      level: 800,
    );
  }

  /// Logs a warning. Use for unexpected but recoverable situations.
  static void warning(String message, {String? tag, Object? error}) {
    developer.log(
      message,
      name: tag ?? _defaultTag,
      level: 900,
      error: error,
    );
  }

  /// Logs an error. Use for failures that require attention.
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag ?? _defaultTag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs a debug message. Only active in debug builds.
  /// This call is a no-op in release builds (stripped by assert).
  static void debug(String message, {String? tag}) {
    assert(() {
      developer.log(
        message,
        name: tag ?? _defaultTag,
        level: 500,
      );
      return true;
    }());
  }
}
