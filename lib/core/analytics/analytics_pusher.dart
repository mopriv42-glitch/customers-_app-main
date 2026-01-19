import 'package:flutter/foundation.dart';
import 'package:private_4t_app/app_config/pusher_controller.dart';
import 'package:private_4t_app/core/analytics/analytics_models.dart';

/// Analytics Pusher Service
/// Broadcasts analytics events in real-time to Laravel dashboard via Pusher
class AnalyticsPusher {
  static final AnalyticsPusher _instance = AnalyticsPusher._internal();
  factory AnalyticsPusher() => _instance;
  AnalyticsPusher._internal();

  static AnalyticsPusher get instance => _instance;

  bool _isInitialized = false;
  static const String _channelName = 'private-analytics';

  /// Initialize the analytics broadcaster
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Subscribe to the private-analytics channel
      await PusherController.subscribe(_channelName);
      
      // Wait a bit to ensure subscription is complete
      await Future.delayed(const Duration(milliseconds: 500));

      _isInitialized = true;
      debugPrint(
          '✅ AnalyticsPusher initialized and subscribed to $_channelName');
    } catch (e) {
      debugPrint('❌ Failed to initialize AnalyticsPusher: $e');
    }
  }

  /// Broadcast an analytics event to the admin dashboard
  Future<void> broadcastEvent(AnalyticsEvent event) async {
    if (!_isInitialized) {
      debugPrint('⚠️ AnalyticsPusher not initialized, skipping broadcast');
      return;
    }

    try {
      // Send to private-analytics channel with client- prefix for client events
      await PusherController.trigger(
        _channelName,
        'client-event.logged',
        {
          'type': 'event',
          'data': event.toJson(),
        },
      );

      debugPrint('📡 Broadcasted event: ${event.name}');
    } catch (e) {
      debugPrint('❌ Failed to broadcast event: $e');
    }
  }

  /// Broadcast a network log to the admin dashboard
  Future<void> broadcastNetworkLog(NetworkLog log) async {
    if (!_isInitialized) {
      debugPrint('⚠️ AnalyticsPusher not initialized, skipping broadcast');
      return;
    }

    try {
      // Send to private-analytics channel with client- prefix for client events
      await PusherController.trigger(
        _channelName,
        'client-network.logged',
        {
          'type': 'network_log',
          'data': log.toJson(),
        },
      );

      debugPrint('📡 Broadcasted network log: ${log.method} ${log.url}');
    } catch (e) {
      debugPrint('❌ Failed to broadcast network log: $e');
    }
  }

  /// Broadcast an error to the admin dashboard
  Future<void> broadcastError(Map<String, dynamic> errorData) async {
    if (!_isInitialized) {
      debugPrint('⚠️ AnalyticsPusher not initialized, skipping broadcast');
      return;
    }

    try {
      await PusherController.trigger(
        _channelName,
        'client-error.occurred',
        {
          'type': 'error',
          'data': errorData,
        },
      );

      debugPrint('📡 Broadcasted error: ${errorData['error_message']}');
    } catch (e) {
      debugPrint('❌ Failed to broadcast error: $e');
    }
  }

  /// Broadcast session info to the admin dashboard
  Future<void> broadcastSession(Map<String, dynamic> session) async {
    if (!_isInitialized) {
      debugPrint('⚠️ AnalyticsPusher not initialized, skipping broadcast');
      return;
    }

    try {
      await PusherController.trigger(
        _channelName,
        'client-session.started',
        {
          'type': 'session',
          'data': session,
        },
      );

      debugPrint('📡 Broadcasted session: ${session['session_id']}');
    } catch (e) {
      debugPrint('❌ Failed to broadcast session: $e');
    }
  }

  /// Broadcast a batch of events
  Future<void> broadcastBatch({
    List<AnalyticsEvent>? events,
    List<NetworkLog>? networkLogs,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ AnalyticsPusher not initialized, skipping broadcast');
      return;
    }

    try {
      final batch = {
        'events': events?.map((e) => e.toJson()).toList() ?? [],
        'network_logs': networkLogs?.map((l) => l.toJson()).toList() ?? [],
        'timestamp': DateTime.now().toIso8601String(),
      };

      await PusherController.trigger(
        _channelName,
        'client-batch.sent',
        {
          'type': 'batch',
          'data': batch,
        },
      );

      debugPrint(
          '📡 Broadcasted batch: ${events?.length ?? 0} events, ${networkLogs?.length ?? 0} logs');
    } catch (e) {
      debugPrint('❌ Failed to broadcast batch: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
  }
}
