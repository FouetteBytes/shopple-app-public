import 'package:flutter/foundation.dart';

/// Centralized lightweight logger to avoid stray debug prints in release
/// and provide a single place for future enhancements (masking, telemetry, etc.).
class AppLogger {
  AppLogger._();

  static void d(String message) {
    if (kDebugMode) debugPrint(message);
  }

  static void w(String message) {
    if (kDebugMode) debugPrint('⚠️  $message');
  }

  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('❌ $message${error != null ? ' :: $error' : ''}');
      if (stackTrace != null) debugPrint(stackTrace.toString());
    } else {
      // In release we could forward to a crash/telemetry service if desired.
    }
  }

  /// Remove sensitive parts from URLs (e.g., Firebase Storage tokens, query params)
  static String sanitizeUrl(String? url) {
    if (url == null) return '';
    try {
      final uri = Uri.parse(url);
      // Drop all query parameters to avoid leaking tokens
      final clean = uri.replace(queryParameters: const {}).toString();
      return clean;
    } catch (_) {
      return url;
    }
  }
}
