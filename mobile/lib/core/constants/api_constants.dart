import 'package:flutter/foundation.dart';

class ApiConstants {
  /// Set at build time for release APK:
  /// flutter build apk --dart-define=API_BASE=https://your-api.com/api
  static const String envBase = String.fromEnvironment('API_BASE');

  static String defaultBaseUrl() {
    if (envBase.isNotEmpty) return envBase;
    if (kIsWeb) return 'http://localhost:4000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000/api';
    }
    return 'http://localhost:4000/api';
  }

  /// Prefer emulator-safe URL on Android when a saved LAN/localhost URL won't work.
  static String resolveBaseUrl({String? saved}) {
    final fallback = defaultBaseUrl();
    if (saved == null || saved.trim().isEmpty) return fallback;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final lower = saved.toLowerCase();
      if (lower.contains('192.168.') ||
          lower.contains('localhost') ||
          lower.contains('127.0.0.1')) {
        return fallback;
      }
    }
    return saved;
  }

  static String socketUrlFrom(String apiBase) {
    var host = apiBase;
    if (host.endsWith('/')) host = host.substring(0, host.length - 1);
    if (host.endsWith('/api')) {
      host = host.substring(0, host.length - 4);
    }
    return host;
  }

  static String resolveMediaUrl(String? url, String apiBase) {
    if (url == null || url.trim().isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = socketUrlFrom(apiBase);
    if (url.startsWith('/')) return '$base$url';
    return '$base/$url';
  }

  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 12);
}
