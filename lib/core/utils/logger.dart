import 'package:flutter/foundation.dart';

class Logger {
  static void logRequest(String name, String method, String endpoint, [dynamic data]) {
    if (kDebugMode) {
      debugPrint('🟢 [$name] Request: $method $endpoint');
      if (data != null) {
        debugPrint('🟢 Data: $data');
      }
    }
  }

  static void logResponse(String name, String endpoint, dynamic data) {
    if (kDebugMode) {
      debugPrint('🔵 [$name] Response from: $endpoint');
      debugPrint('🔵 Data: $data');
    }
  }

  static void logError(String name, String endpoint, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('🔴 [$name] Error in: $endpoint');
      debugPrint('🔴 Error: $error');
      if (stackTrace != null) {
        debugPrint('🔴 StackTrace: $stackTrace');
      }
    }
  }
}
