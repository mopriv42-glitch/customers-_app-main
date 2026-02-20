/// Configuration for analytics with BLOCKED KEYS approach
class AnalyticsConfig {
  /// Maximum body size in bytes before truncation
  static const int maxBodyBytes = 100 * 1024; // 100KB

  /// Batch size before auto-flush
  static const int batchSize = 20;

  /// Auto-flush interval in seconds
  static const int flushIntervalSeconds = 25;

  /// Maximum retry attempts
  static const int maxRetryAttempts = 3;

  /// Base retry delay in seconds
  static const int baseRetryDelaySeconds = 2;

  /// Ingestion endpoints
  static const String eventsEndpoint = '/analytics/events';
  static const String networkLogsEndpoint = '/analytics/network';

  /// BLOCKED request headers (these will be REMOVED from logs)
  static const List<String> blockedRequestHeaders = [
    'authorization',
    'x-api-key',
    'x-auth-token',
    'cookie',
    'set-cookie',
  ];

  /// BLOCKED response headers (these will be REMOVED from logs)
  static const List<String> blockedResponseHeaders = [
    'set-cookie',
    'authorization',
    'x-api-key',
  ];

  /// BLOCKED request body keys (supports dot notation like 'user.password')
  /// Add your sensitive keys here
  static List<String> blockedRequestBodyKeys = [
    'password',
    'password_confirmation',
    'old_password',
    'new_password',
    'pin',
    'cvv',
    'card_number',
    'card_cvv',
    'ssn',
    'social_security',
    'credit_card',
    'api_key',
    'secret',
    'private_key',
    'access_token',
    'refresh_token',
    // Add more blocked keys as needed
  ];

  /// BLOCKED response body keys (supports dot notation)
  static List<String> blockedResponseBodyKeys = [
    'password',
    'token',
    'access_token',
    'refresh_token',
    'api_key',
    'secret',
    'private_key',
    'user.password',
    'data.password',
    'data.token',
    // Add more blocked keys as needed
  ];

  /// Helper to check if a key should be blocked
  static bool shouldBlockKey(String key, List<String> blockedList) {
    final lowerKey = key.toLowerCase();

    for (final blocked in blockedList) {
      final lowerBlocked = blocked.toLowerCase();

      // Exact match
      if (lowerKey == lowerBlocked) return true;

      // Check if key contains blocked word
      if (lowerKey.contains(lowerBlocked)) return true;

      // Dot notation support (e.g., user.password blocks data.user.password)
      if (lowerBlocked.contains('.')) {
        if (lowerKey.endsWith(lowerBlocked) ||
            lowerKey.contains('.$lowerBlocked') ||
            lowerKey.contains('$lowerBlocked.')) {
          return true;
        }
      }
    }

    return false;
  }

  /// Filter map by removing blocked keys
  static Map<String, dynamic> filterBlockedKeys(
    Map<String, dynamic>? data,
    List<String> blockedList,
  ) {
    if (data == null) return {};

    final filtered = <String, dynamic>{};

    for (final entry in data.entries) {
      if (!shouldBlockKey(entry.key, blockedList)) {
        // If value is a map, recursively filter it
        if (entry.value is Map) {
          filtered[entry.key] = filterBlockedKeys(
            (entry.value as Map).cast<String, dynamic>(),
            blockedList,
          );
        }
        // If value is a list, filter each map item
        else if (entry.value is List) {
          filtered[entry.key] = (entry.value as List).map((item) {
            if (item is Map) {
              return filterBlockedKeys(
                item.cast<String, dynamic>(),
                blockedList,
              );
            }
            return item;
          }).toList();
        } else {
          filtered[entry.key] = entry.value;
        }
      } else {
        // Replace blocked value with placeholder
        filtered[entry.key] = '[BLOCKED]';
      }
    }

    return filtered;
  }

  /// Truncate string if exceeds max bytes
  static String truncateIfNeeded(String data) {
    final bytes = data.length;
    if (bytes > maxBodyBytes) {
      final truncated = data.substring(0, maxBodyBytes);
      return '$truncated... [TRUNCATED]';
    }
    return data;
  }
}
