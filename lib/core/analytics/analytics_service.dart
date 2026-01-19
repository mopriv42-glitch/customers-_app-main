import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/providers/app_container.dart';
import 'package:private_4t_app/core/providers/authentication_providers/login_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'analytics_config.dart';
import 'analytics_models.dart';
import 'analytics_pusher.dart';

/// Central analytics service for tracking events and network logs
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  static AnalyticsService get instance => _instance;

  AnalyticsService._internal();

  // State
  String? _deviceId;
  String? _sessionId;
  String? _userId;
  String? _appVersion;
  String? _platform;
  String? _currentScreen;

  // Queues
  final List<AnalyticsEvent> _eventQueue = [];
  final List<NetworkLog> _networkLogQueue = [];

  // Failed queues (for retry when connection returns)
  final List<AnalyticsEvent> _failedEventQueue = [];
  final List<NetworkLog> _failedNetworkLogQueue = [];

  // Flush timer
  Timer? _flushTimer;

  // Retry state
  int _retryAttempts = 0;

  // Dio instance for sending logs
  Dio? _dio;

  // Initialized flag
  bool _initialized = false;

  // Connectivity subscription
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Get current device ID
  String get deviceId => _deviceId ?? 'unknown';

  /// Get current session ID
  String get sessionId => _sessionId ?? 'unknown';

  /// Get current user ID
  String? get userId => _userId;

  /// Set current user ID
  set userId(String? id) {
    _userId = id;
    debugPrint('📊 Analytics User ID updated: ${id ?? "null"}');

    // Broadcast session update when user logs in
    if (_initialized && id != null) {
      _broadcastSessionStarted();
    }
  }

  /// Get current screen
  String? get currentScreen => _currentScreen;

  /// Set current screen
  set currentScreen(String? screen) => _currentScreen = screen;

  /// Initialize the analytics service
  Future<void> initialize({required String baseUrl}) async {
    if (_initialized) return;

    try {
      // Get or generate device ID
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString('analytics_device_id');
      if (_deviceId == null) {
        _deviceId = const Uuid().v4();
        await prefs.setString('analytics_device_id', _deviceId!);
      }

      // Generate new session ID
      _sessionId = const Uuid().v4();

      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      // Get platform
      _platform = getPlatformName();

      // Try to get userId from saved data
      try {
        final savedUserId = await CommonComponents.getSavedData(ApiKeys.userID);
        if (savedUserId != null && savedUserId.isNotEmpty) {
          _userId = savedUserId;
          debugPrint('   User ID loaded from storage: $_userId');
        }
      } catch (e) {
        debugPrint('   No saved user ID found');
      }

      // Initialize Dio for analytics
      _dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      // Initialize Pusher for real-time broadcasting
      await AnalyticsPusher.instance.initialize();

      // Broadcast session started event
      await _broadcastSessionStarted();

      // Start connectivity monitoring
      _startConnectivityMonitoring();

      // Start flush timer
      _startFlushTimer();

      _initialized = true;

      debugPrint('✅ AnalyticsService initialized');
      debugPrint('   Device ID: $_deviceId');
      debugPrint('   Session ID: $_sessionId');
      debugPrint('   User ID: ${_userId ?? "Not logged in"}');
      debugPrint('   App Version: $_appVersion');
      debugPrint('   Platform: $_platform');
    } catch (e) {
      debugPrint('❌ AnalyticsService initialization failed: $e');
    }
  }

  /// Log an event
  void logEvent(
    String name, {
    Map<String, dynamic>? properties,
    String? screen,
  }) {
    if (!_initialized) {
      debugPrint('⚠️ AnalyticsService not initialized, skipping event: $name');
      return;
    }

    final userId = providerAppContainer
        .read(ApiProviders.loginProvider)
        .loggedUser
        ?.id
        ?.toString();

    debugPrint('🔍 Logging event: $name');
    debugPrint('🔍 Properties: ${properties ?? {}}');
    debugPrint('🔍 Screen: ${screen ?? _currentScreen}');
    debugPrint('🔍 User ID: $_userId');
    debugPrint('🔍 Device ID: $_deviceId');
    debugPrint('🔍 Session ID: $_sessionId');
    debugPrint('🔍 Platform: $_platform');
    debugPrint('🔍 App Version: $_appVersion');

    final event = AnalyticsEvent(
      deviceId: _deviceId!,
      sessionId: _sessionId!,
      userId: _userId,
      platform: _platform!,
      appVersion: _appVersion!,
      screen: screen ?? _currentScreen,
      name: name,
      properties: properties ?? {},
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    // Broadcast event in real-time via Pusher (instant delivery)
    AnalyticsPusher.instance.broadcastEvent(event);

    // Send event immediately to API (no queuing)
    _sendEventImmediately(event);
  }

  /// Log a network request/response
  void logNetwork(NetworkLog log) {
    if (!_initialized) {
      debugPrint('⚠️ AnalyticsService not initialized, skipping network log');
      return;
    }

    final userId = providerAppContainer
        .read(ApiProviders.loginProvider)
        .loggedUser
        ?.id
        ?.toString();

    debugPrint('🔍 Logging network log: ${log.toJson()}');
    debugPrint('🔍 User ID: $userId');
    debugPrint('🔍 Device ID: $_deviceId');
    debugPrint('🔍 Session ID: $_sessionId');
    debugPrint('🔍 Platform: $_platform');
    debugPrint('🔍 App Version: $_appVersion');

    // Broadcast network log in real-time via Pusher (instant delivery)
    AnalyticsPusher.instance.broadcastNetworkLog(log);

    // Send network log immediately to API (no queuing)
    _sendNetworkLogImmediately(log);
  }

  /// Send event immediately (with fallback to queue if failed)
  Future<void> _sendEventImmediately(AnalyticsEvent event) async {
    try {
      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        debugPrint('⚠️ No connectivity, adding event to failed queue');
        _failedEventQueue.add(event);
        return;
      }

      final response = await _dio!.post(
        AnalyticsConfig.eventsEndpoint,
        data: {'event': event.toJson()},
        options: Options(
          headers: {
            'X-Session-Id': _sessionId,
            'X-Device-Id': _deviceId,
            'X-User-Id': _userId,
            'Authorization':
                'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Event sent immediately: ${event.name}');
      } else {
        debugPrint(
            '⚠️ Event send failed: ${response.statusCode}, adding to failed queue');
        _failedEventQueue.add(event);
      }
    } catch (e) {
      debugPrint('❌ Event send error: $e, adding to failed queue');
      _failedEventQueue.add(event);
    }
  }

  /// Send network log immediately (with fallback to queue if failed)
  Future<void> _sendNetworkLogImmediately(NetworkLog log) async {
    try {
      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        debugPrint('⚠️ No connectivity, adding network log to failed queue');
        _failedNetworkLogQueue.add(log);
        return;
      }

      final response = await _dio!.post(
        AnalyticsConfig.networkLogsEndpoint,
        data: {'network_log': log.toJson()},
        options: Options(
          headers: {
            'X-Session-Id': _sessionId,
            'X-Device-Id': _deviceId,
            'X-User-Id': _userId,
            'Authorization':
                'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Network log sent immediately: ${log.method} ${log.url}');
      } else {
        debugPrint(
            '⚠️ Network log send failed: ${response.statusCode}, adding to failed queue');
        _failedNetworkLogQueue.add(log);
      }
    } catch (e) {
      debugPrint('❌ Network log send error: $e, adding to failed queue');
      _failedNetworkLogQueue.add(log);
    }
  }

  /// Start the auto-flush timer (kept for backward compatibility)
  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(
      const Duration(seconds: AnalyticsConfig.flushIntervalSeconds),
      (_) {
        _flushAll();
      },
    );
  }

  /// Flush all queues
  Future<void> _flushAll() async {
    await Future.wait([
      _flushEvents(),
      _flushNetworkLogs(),
    ]);
  }

  /// Flush events queue
  Future<void> _flushEvents() async {
    if (_eventQueue.isEmpty) return;

    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      debugPrint('⚠️ No connectivity, skipping event flush');
      return;
    }

    final batch = List<AnalyticsEvent>.from(_eventQueue);
    _eventQueue.clear();

    try {
      final response = await _dio!.post(
        AnalyticsConfig.eventsEndpoint,
        data: {'events': batch.map((e) => e.toJson()).toList()},
        options: Options(
          headers: {
            'X-Session-Id': _sessionId,
            'X-Device-Id': _deviceId,
            'X-User-Id': _userId,
            'Authorization':
                'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Flushed ${batch.length} events');
        _retryAttempts = 0;
      } else {
        debugPrint('⚠️ Event flush failed: ${response.statusCode}');
        _retryFlush(batch, isEvent: true);
      }
    } catch (e) {
      debugPrint('❌ Event flush error: $e');
      _retryFlush(batch, isEvent: true);
    }
  }

  /// Flush network logs queue
  Future<void> _flushNetworkLogs() async {
    if (_networkLogQueue.isEmpty) return;

    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      debugPrint('⚠️ No connectivity, skipping network log flush');
      return;
    }

    final batch = List<NetworkLog>.from(_networkLogQueue);
    _networkLogQueue.clear();

    try {
      final response = await _dio!.post(
        AnalyticsConfig.networkLogsEndpoint,
        data: {'logs': batch.map((e) => e.toJson()).toList()},
        options: Options(
          headers: {
            'X-Session-Id': _sessionId,
            'X-Device-Id': _deviceId,
            'X-User-Id': _userId,
            'Authorization':
                'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Flushed ${batch.length} network logs');
        _retryAttempts = 0;
      } else {
        debugPrint('⚠️ Network log flush failed: ${response.statusCode}');
        _retryFlush(batch, isEvent: false);
      }
    } catch (e) {
      debugPrint('❌ Network log flush error: $e');
      _retryFlush(batch, isEvent: false);
    }
  }

  /// Start connectivity monitoring
  void _startConnectivityMonitoring() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      final hasConnection = !result.contains(ConnectivityResult.none);

      if (hasConnection) {
        debugPrint('🌐 Connection restored, retrying failed analytics...');
        _retryFailedAnalytics();
      } else {
        debugPrint('📡 Connection lost');
      }
    });
  }

  /// Retry all failed analytics when connection is restored
  Future<void> _retryFailedAnalytics() async {
    if (_failedEventQueue.isEmpty && _failedNetworkLogQueue.isEmpty) {
      debugPrint('✅ No failed analytics to retry');
      return;
    }

    debugPrint(
        '🔄 Retrying ${_failedEventQueue.length} failed events and ${_failedNetworkLogQueue.length} failed network logs');

    // Retry failed events
    final failedEvents = List<AnalyticsEvent>.from(_failedEventQueue);
    _failedEventQueue.clear();

    for (final event in failedEvents) {
      await _sendEventImmediately(event);
    }

    // Retry failed network logs
    final failedLogs = List<NetworkLog>.from(_failedNetworkLogQueue);
    _failedNetworkLogQueue.clear();

    for (final log in failedLogs) {
      await _sendNetworkLogImmediately(log);
    }

    debugPrint('✅ Retry completed');
  }

  /// Broadcast session started event
  Future<void> _broadcastSessionStarted() async {
    try {
      final sessionData = {
        'session_id': _sessionId,
        'device_id': _deviceId,
        'user_id': _userId,
        'platform': _platform,
        'app_version': _appVersion,
        'started_at': DateTime.now().toIso8601String(),
      };

      await AnalyticsPusher.instance.broadcastSession(sessionData);
      debugPrint('📡 Session started broadcasted via Pusher');
    } catch (e) {
      debugPrint('❌ Failed to broadcast session started: $e');
    }
  }

  /// Retry flush with exponential backoff
  void _retryFlush(List<dynamic> batch, {required bool isEvent}) {
    if (_retryAttempts >= AnalyticsConfig.maxRetryAttempts) {
      debugPrint('❌ Max retry attempts reached, dropping batch');
      _retryAttempts = 0;
      return;
    }

    _retryAttempts++;
    final delay = AnalyticsConfig.baseRetryDelaySeconds * _retryAttempts;

    debugPrint('🔄 Retrying flush in $delay seconds (attempt $_retryAttempts)');

    Timer(Duration(seconds: delay), () {
      if (isEvent) {
        _eventQueue.addAll(batch.cast<AnalyticsEvent>());
        _flushEvents();
      } else {
        _networkLogQueue.addAll(batch.cast<NetworkLog>());
        _flushNetworkLogs();
      }
    });
  }

  /// Dispose the service
  void dispose() {
    _flushTimer?.cancel();
    _connectivitySubscription?.cancel();
    _flushAll();
  }
}
