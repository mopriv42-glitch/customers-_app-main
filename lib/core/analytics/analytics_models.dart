import 'dart:io';

/// Model for a single analytics event
class AnalyticsEvent {
  final String deviceId;
  final String sessionId;
  final String? userId;
  final String platform;
  final String appVersion;
  final String? screen;
  final String name;
  final Map<String, dynamic> properties;
  final int timestamp;

  AnalyticsEvent({
    required this.deviceId,
    required this.sessionId,
    this.userId,
    required this.platform,
    required this.appVersion,
    this.screen,
    required this.name,
    required this.properties,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'sessionId': sessionId,
        'userId': userId,
        'platform': platform,
        'appVersion': appVersion,
        'screen': screen,
        'name': name,
        'properties': properties,
        'ts': timestamp,
      };
}

/// Model for network logs
class NetworkLog {
  final String deviceId;
  final String sessionId;
  final String? userId;
  final String method;
  final String url;
  final int? statusCode;
  final int durationMs;
  final Map<String, dynamic>? requestHeaders;
  final dynamic requestBody;
  final Map<String, dynamic>? responseHeaders;
  final dynamic responseBody;
  final String? error;
  final int timestamp;

  NetworkLog({
    required this.deviceId,
    required this.sessionId,
    this.userId,
    required this.method,
    required this.url,
    this.statusCode,
    required this.durationMs,
    this.requestHeaders,
    this.requestBody,
    this.responseHeaders,
    this.responseBody,
    this.error,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'sessionId': sessionId,
        'userId': userId,
        'method': method,
        'url': url,
        'statusCode': statusCode,
        'durationMs': durationMs,
        'requestHeaders': requestHeaders,
        'requestBody': requestBody,
        'responseHeaders': responseHeaders,
        'responseBody': responseBody,
        'error': error,
        'ts': timestamp,
      };
}

/// Get platform name
String getPlatformName() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  return 'unknown';
}
