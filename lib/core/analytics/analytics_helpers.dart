import 'analytics_service.dart';

/// Helper methods for logging common analytics events
class AnalyticsHelpers {
  static final AnalyticsService _analytics = AnalyticsService.instance;

  /// Log notification received
  static void logNotificationReceived({
    required String type,
    String? title,
    Map<String, dynamic>? data,
  }) {
    _analytics.logEvent(
      'notification_received',
      properties: {
        'type': type,
        'title': title,
        if (data != null) ...data,
      },
    );
  }

  /// Log notification tapped
  static void logNotificationTapped({
    required String type,
    String? action,
    Map<String, dynamic>? data,
  }) {
    _analytics.logEvent(
      'notification_tapped',
      properties: {
        'type': type,
        'action': action,
        if (data != null) ...data,
      },
    );
  }

  /// Log VOIP call event
  static void logVoipCall({
    required String action, // 'incoming', 'answer', 'decline', 'missed', 'hangup'
    String? callId,
    String? roomId,
    bool? isVideo,
  }) {
    _analytics.logEvent(
      'voip_call',
      properties: {
        'action': action,
        'call_id': callId,
        'room_id': roomId,
        'is_video': isVideo,
      },
    );
  }

  /// Log pull to refresh
  static void logPullToRefresh({required String screen}) {
    _analytics.logEvent(
      'pull_to_refresh',
      properties: {'screen': screen},
    );
  }

  /// Log button tap / CTA
  static void logButtonTap({
    required String buttonId,
    required String screen,
    Map<String, dynamic>? additionalData,
  }) {
    _analytics.logEvent(
      'button_tap',
      properties: {
        'button_id': buttonId,
        'screen': screen,
        if (additionalData != null) ...additionalData,
      },
      screen: screen,
    );
  }

  /// Log booking step
  static void logBookingStep({
    required String step,
    required String screen,
    Map<String, dynamic>? data,
  }) {
    _analytics.logEvent(
      'booking_step',
      properties: {
        'step': step,
        'screen': screen,
        if (data != null) ...data,
      },
      screen: screen,
    );
  }
}

