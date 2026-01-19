import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/providers/app_container.dart';
import 'analytics_config.dart';
import 'analytics_models.dart';
import 'analytics_service.dart';

/// Wrapper for http package to capture analytics
class AnalyticsHttpWrapper {
  static final AnalyticsService _analytics = AnalyticsService.instance;

  /// Wrap http.post with analytics
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;

    // Add analytics headers
    final modifiedHeaders = {
      ...?headers,
      'X-Session-Id': _analytics.sessionId,
      'X-Device-Id': _analytics.deviceId,
    };

    http.Response? response;
    String? error;

    try {
      response = await http.post(
        url,
        headers: modifiedHeaders,
        body: body,
        encoding: encoding,
      );
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      _logNetworkCall(
        method: 'POST',
        url: url.toString(),
        headers: modifiedHeaders,
        body: body,
        response: response,
        error: error,
        startTime: startTime,
      );
    }

    return response;
  }

  /// Wrap http.get with analytics
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;

    // Add analytics headers
    final modifiedHeaders = {
      ...?headers,
      'X-Session-Id': _analytics.sessionId,
      'X-Device-Id': _analytics.deviceId,
    };

    http.Response? response;
    String? error;

    try {
      response = await http.get(url, headers: modifiedHeaders);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      _logNetworkCall(
        method: 'GET',
        url: url.toString(),
        headers: modifiedHeaders,
        body: null,
        response: response,
        error: error,
        startTime: startTime,
      );
    }

    return response;
  }

  /// Wrap http.put with analytics
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;

    // Add analytics headers
    final modifiedHeaders = {
      ...?headers,
      'X-Session-Id': _analytics.sessionId,
      'X-Device-Id': _analytics.deviceId,
    };

    http.Response? response;
    String? error;

    try {
      response = await http.put(
        url,
        headers: modifiedHeaders,
        body: body,
        encoding: encoding,
      );
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      _logNetworkCall(
        method: 'PUT',
        url: url.toString(),
        headers: modifiedHeaders,
        body: body,
        response: response,
        error: error,
        startTime: startTime,
      );
    }

    return response;
  }

  /// Wrap http.delete with analytics
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;

    // Add analytics headers
    final modifiedHeaders = {
      ...?headers,
      'X-Session-Id': _analytics.sessionId,
      'X-Device-Id': _analytics.deviceId,
    };

    http.Response? response;
    String? error;

    try {
      response = await http.delete(
        url,
        headers: modifiedHeaders,
        body: body,
        encoding: encoding,
      );
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      _logNetworkCall(
        method: 'DELETE',
        url: url.toString(),
        headers: modifiedHeaders,
        body: body,
        response: response,
        error: error,
        startTime: startTime,
      );
    }

    return response;
  }

  /// Log the network call
  static void _logNetworkCall({
    required String method,
    required String url,
    required Map<String, String>? headers,
    required Object? body,
    required http.Response? response,
    required String? error,
    required int startTime,
  }) {
    try {
      final duration = DateTime.now().millisecondsSinceEpoch - startTime;

      // Filter request headers
      final requestHeaders = _filterHeaders(
        headers ?? {},
        AnalyticsConfig.blockedRequestHeaders,
      );

      // Filter request body
      final requestBody = _filterBody(
        body,
        AnalyticsConfig.blockedRequestBodyKeys,
      );

      // Filter response headers
      final responseHeaders = response != null
          ? _filterHeaders(
              response.headers,
              AnalyticsConfig.blockedResponseHeaders,
            )
          : null;

      // Filter response body
      final responseBody = response != null
          ? _filterBody(
              response.body,
              AnalyticsConfig.blockedResponseBodyKeys,
            )
          : null;

      // Create network log
      final log = NetworkLog(
        deviceId: _analytics.deviceId,
        sessionId: _analytics.sessionId,
        userId: providerAppContainer
            .read(ApiProviders.loginProvider)
            .loggedUser
            ?.id
            ?.toString(),
        method: method,
        url: url,
        statusCode: response?.statusCode,
        durationMs: duration,
        requestHeaders: requestHeaders,
        requestBody: requestBody,
        responseHeaders: responseHeaders,
        responseBody: responseBody,
        error: error,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      // Send to analytics service
      _analytics.logNetwork(log);
    } catch (e) {
      debugPrint('❌ Error logging HTTP call: $e');
    }
  }

  /// Filter headers by removing blocked ones
  static Map<String, dynamic> _filterHeaders(
    Map<String, String> headers,
    List<String> blockedList,
  ) {
    final filtered = <String, dynamic>{};

    for (final entry in headers.entries) {
      final key = entry.key.toLowerCase();
      if (!AnalyticsConfig.shouldBlockKey(key, blockedList)) {
        filtered[key] = entry.value;
      } else {
        filtered[key] = '[BLOCKED]';
      }
    }

    return filtered;
  }

  /// Filter body by removing blocked keys
  static dynamic _filterBody(dynamic body, List<String> blockedList) {
    if (body == null) return null;

    try {
      // If body is string, try to parse as JSON
      if (body is String) {
        try {
          final parsed = jsonDecode(body);
          if (parsed is Map) {
            final filtered = AnalyticsConfig.filterBlockedKeys(
              parsed.cast<String, dynamic>(),
              blockedList,
            );
            final jsonString = jsonEncode(filtered);
            return AnalyticsConfig.truncateIfNeeded(jsonString);
          }
        } catch (_) {
          // Not JSON, truncate if needed
          return AnalyticsConfig.truncateIfNeeded(body);
        }
      }

      // If body is map
      if (body is Map) {
        final filtered = AnalyticsConfig.filterBlockedKeys(
          body.cast<String, dynamic>(),
          blockedList,
        );
        final jsonString = jsonEncode(filtered);
        return AnalyticsConfig.truncateIfNeeded(jsonString);
      }

      // For other types, convert to string and truncate
      return AnalyticsConfig.truncateIfNeeded(body.toString());
    } catch (e) {
      debugPrint('⚠️ Error filtering body: $e');
      return '[Error filtering body]';
    }
  }
}
