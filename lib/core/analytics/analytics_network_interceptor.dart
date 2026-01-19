import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'analytics_config.dart';
import 'analytics_models.dart';
import 'analytics_service.dart';

/// Dio interceptor for capturing network requests and responses
class AnalyticsNetworkInterceptor extends Interceptor {
  final AnalyticsService _analytics = AnalyticsService.instance;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Store request start time in options
    options.extra['analytics_start_time'] =
        DateTime.now().millisecondsSinceEpoch;

    // Add analytics headers
    options.headers['X-Session-Id'] = _analytics.sessionId;
    options.headers['X-Device-Id'] = _analytics.deviceId;

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logNetworkCall(
      options: response.requestOptions,
      response: response,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logNetworkCall(
      options: err.requestOptions,
      response: err.response,
      error: err.toString(),
    );
    handler.next(err);
  }

  /// Log the network call
  void _logNetworkCall({
    required RequestOptions options,
    Response? response,
    String? error,
  }) {
    try {
      // Calculate duration
      final startTime = options.extra['analytics_start_time'] as int?;
      final duration = startTime != null
          ? DateTime.now().millisecondsSinceEpoch - startTime
          : 0;

      // Filter and sanitize request headers (remove blocked)
      final requestHeaders = _filterHeaders(
        options.headers,
        AnalyticsConfig.blockedRequestHeaders,
      );

      // Filter and sanitize request body (remove blocked keys)
      final requestBody = _filterBody(
        options.data,
        AnalyticsConfig.blockedRequestBodyKeys,
      );

      // Filter and sanitize response headers (remove blocked)
      final responseHeaders = response != null
          ? _filterHeaders(
              response.headers.map,
              AnalyticsConfig.blockedResponseHeaders,
            )
          : null;

      // Filter and sanitize response body (remove blocked keys)
      final responseBody = response?.data != null
          ? _filterBody(
              response!.data,
              AnalyticsConfig.blockedResponseBodyKeys,
            )
          : null;

      // Create network log
      final log = NetworkLog(
        deviceId: _analytics.deviceId,
        sessionId: _analytics.sessionId,
        userId: _analytics.userId,
        method: options.method,
        url: options.uri.toString(),
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
      debugPrint('❌ Error logging network call: $e');
    }
  }

  /// Filter headers by removing blocked ones
  Map<String, dynamic> _filterHeaders(
    Map<String, dynamic> headers,
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
  dynamic _filterBody(dynamic body, List<String> blockedList) {
    if (body == null) return null;

    try {
      // If body is string, try to parse as JSON
      if (body is String) {
        try {
          body = jsonDecode(body);
        } catch (_) {
          // Not JSON, truncate if needed
          return AnalyticsConfig.truncateIfNeeded(body);
        }
      }

      // If body is map, filter by blocked keys
      if (body is Map) {
        final filtered = AnalyticsConfig.filterBlockedKeys(
          body.cast<String, dynamic>(),
          blockedList,
        );

        // Convert to JSON string and truncate if needed
        final jsonString = jsonEncode(filtered);
        return AnalyticsConfig.truncateIfNeeded(jsonString);
      }

      // If body is list, filter each item if it's a map
      if (body is List) {
        final filtered = body.map((item) {
          if (item is Map) {
            return AnalyticsConfig.filterBlockedKeys(
              item.cast<String, dynamic>(),
              blockedList,
            );
          }
          return item;
        }).toList();

        // Convert to JSON string and truncate if needed
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
