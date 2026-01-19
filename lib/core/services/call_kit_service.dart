import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/services/matrix_call_service.dart';
import 'package:private_4t_app/core/services/navigation_queue.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:private_4t_app/main.dart';
import 'package:uuid/uuid.dart';

import 'notification_service.dart';

@pragma('vm:entry-point')
class CallKitService {
  static final CallKitService instance = CallKitService._();

  CallKitService._();

  final Uuid _uuid = const Uuid();

  /// إظهار إشعار مكالمة واردة
  @pragma('vm:entry-point')
  Future<void> showIncomingCall({
    required String callerName,
    required String callerId,
    String? avatarUrl,
    String? roomId,
    String? eventId,
    String? callId,
    bool supportsVideo = false,
    bool supportsDTMF = true,
  }) async {
    try {
      final String uniqueCallId = callId ?? _uuid.v4();

      final params = CallKitParams(
        id: uniqueCallId,
        nameCaller: callerName,
        appName: 'Private 4T',
        avatar: avatarUrl ??
            'https://cdn.private-4t.com/site/assets/website/images/logo.png',
        handle: callerId,
        type: supportsVideo ? 1 : 0,
        // 1 for video, 0 for audio
        duration: 30000,
        textAccept: "رد",
        textDecline: 'رفض',
        extra: {
          'room_id': roomId ?? '',
          'caller_id': callerId,
          'event_id': eventId,
          // Must match the Matrix call_id from the invite so answers/hangups map correctly
          'call_id': uniqueCallId,
        },
        headers: <String, dynamic>{
          'platform': 'flutter',
        },
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: true,
          logoUrl: 'assets/images/private-4t-logo.png',
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          actionColor: '#4CAF50',
          textColor: '#ffffff',
          incomingCallNotificationChannelName:
              NotificationService.callChannelName,
          missedCallNotificationChannelName:
              NotificationService.callChannelName,
          isShowCallID: false,
          isShowFullLockedScreen: true,
          isImportant: true,
        ),
        ios: IOSParams(
          iconName: 'AppIcon',
          handleType: 'generic',
          supportsVideo: supportsVideo,
          maximumCallGroups: 2,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'default',
          audioSessionActive: true,
          audioSessionPreferredSampleRate: 44100.0,
          audioSessionPreferredIOBufferDuration: 0.005,
          supportsDTMF: supportsDTMF,
          supportsHolding: true,
          supportsGrouping: false,
          supportsUngrouping: false,
          ringtonePath: 'system_ringtone_default',
        ),
      );
      if (await FlutterCallkitIncoming.canUseFullScreenIntent()) {
        await FlutterCallkitIncoming.showCallkitIncoming(params);
      }
    } catch (e) {
      debugPrint('Error showing incoming call: $e');
    }
  }

  /// قبول المكالمة
  @pragma('vm:entry-point')
  Future<void> acceptCall(String callId) async {
    try {
      // await FlutterCallkitIncoming.startCall(callId);
      // هنا يمكنك إضافة منطق قبول المكالمة الفعلي
    } catch (e) {
      debugPrint('Error accepting call: $e');
    }
  }

  /// رفض المكالمة
  @pragma('vm:entry-point')
  Future<void> declineCall(String callId) async {
    try {
      await FlutterCallkitIncoming.endCall(callId);
      // هنا يمكنك إضافة منطق رفض المكالمة الفعلي
    } catch (e) {
      debugPrint('Error declining call: $e');
    }
  }

  /// إنهاء المكالمة
  @pragma('vm:entry-point')
  Future<void> endCall(String callId) async {
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } catch (e) {
      debugPrint('Error ending call: $e');
    }
  }

  /// تحديث حالة المكالمة
  @pragma('vm:entry-point')
  Future<void> updateCall({
    required String callId,
    String? callerName,
    String? avatarUrl,
    bool? supportsVideo,
  }) async {
    try {
      final params = CallKitParams(
        id: callId,
        nameCaller: callerName,
        avatar: avatarUrl,
        // handleType and hasVideo are removed in newer versions
        // updateDisplay is also removed, use showCallkitIncoming with same ID to update
      );

      // In newer versions, to update display, you might need to show the call again with the same ID
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    } catch (e) {
      debugPrint('Error updating call: $e');
    }
  }

  /// التحقق من وجود مكالمة نشطة
  @pragma('vm:entry-point')
  Future<bool> hasActiveCall() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      return calls.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking active calls: $e');
      return false;
    }
  }

  /// الحصول على قائمة المكالمات النشطة
  @pragma('vm:entry-point')
  Future<List<dynamic>> getActiveCalls() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      return calls;
    } catch (e) {
      debugPrint('Error getting active calls: $e');
      return [];
    }
  }

  /// تهيئة CallKit
  @pragma('vm:entry-point')
  Future<void> initialize() async {
    try {
      debugPrint('Initializing CallKit...');
      await FlutterCallkitIncoming.requestNotificationPermission({
        "title": "Notification permission",
        "rationaleMessagePermission":
            "Notification permission is required, to show notification.",
        "postNotificationMessageRequired":
            "Notification permission is required, Please allow notification permission from setting."
      });

      await FlutterCallkitIncoming.requestFullIntentPermission();
      FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
        _handleCallKitEvent(event);
      });
      debugPrint('CallKit initialized successfully');
    } catch (e) {
      debugPrint('Error initializing CallKit: $e');
    }
  }

  /// معالج أحداث CallKit مع تكامل Matrix
  @pragma('vm:entry-point')
  void _handleCallKitEvent(CallEvent? event) {
    if (event == null) return;

    try {
      debugPrint(
          'CallKit Event: ${event.event} - Call BODY: ${event.body?.toString()}');

      switch (event.event) {
        case Event.actionCallIncoming:
          _handleIncomingCall(event);
          break;
        case Event.actionCallStart:
          _handleCallStart(event);
          break;
        case Event.actionCallAccept:
          _handleCallAccept(event);
          break;
        case Event.actionCallDecline:
          _handleCallDecline(event);
          break;
        case Event.actionCallEnded:
          _handleCallEnded(event);
          break;
        case Event.actionCallTimeout:
          _handleCallTimeout(event);
          break;
        case Event.actionCallCallback:
          _handleCallCallback(event);
          break;
        case Event.actionCallToggleHold:
          _handleCallToggleHold(event);
          break;
        case Event.actionCallToggleMute:
          _handleCallToggleMute(event);
          break;
        case Event.actionCallToggleDmtf:
          _handleCallToggleDmtf(event);
          break;
        case Event.actionCallToggleGroup:
          _handleCallToggleGroup(event);
          break;
        case Event.actionCallToggleAudioSession:
          _handleCallToggleAudioSession(event);
          break;
        case Event.actionDidUpdateDevicePushTokenVoip:
          _handleDevicePushTokenUpdate(event);
          break;
        case Event.actionCallCustom:
          _handleCallCustom(event);
          break;
        case Event.actionCallConnected:
          _handleCallConnected(event);
          break;
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: 'Error handling CallKit event: $e');
    }
  }

  /// معالجات الأحداث الفردية مع تكامل Matrix
  @pragma('vm:entry-point')
  void _handleIncomingCall(CallEvent data) async {
    debugPrint('Incoming call received: ${data.body?['nameCaller']}');
    // Matrix service will handle this through its own event system
  }

  @pragma('vm:entry-point')
  void _handleCallStart(CallEvent data) {
    debugPrint('Call started: ${data.body?['id']}');
    // Call has started - Matrix service should already be handling this
  }

  @pragma('vm:entry-point')
  void _handleCallAccept(CallEvent data) async {
    final kitCallId = data.body?['id'];
    try {
      final callId = data.body?['extra']?['call_id'] ?? data.body?['id'];
      final roomId = data.body?['extra']?['room_id'];
      final eventId = data.body?['extra']?['event_id'];
      debugPrint('Call accepted via CallKit: $callId in room: $roomId');

      if (callId != null &&
          callId.isNotEmpty &&
          roomId != null &&
          roomId.isNotEmpty) {
        // Try to get existing Matrix service first
        final calls = MatrixCallService.instance;

        if (calls != null) {
          // Matrix service is available (app was foreground/background)
          final room = calls.client.getRoomById(roomId);
          if (room != null) {
            debugPrint('Using existing Matrix service to accept call');
            await calls.acceptIncomingCall(roomId, callId);

            // Navigate to call screen
            NavigationQueue.setPendingCallNavigation(
              PendingNavigation(path: '/call/$roomId'),
            );
            return;
          }
        }

        // Matrix service not available (app was terminated or background)
        debugPrint(
            'Matrix service not available, storing call acceptance for quick startup');

        // Store call acceptance for when app initializes
        await _storeCallAcceptance(callId, roomId, eventId);

        // Set pending navigation for instant home→call transition
        NavigationQueue.setPendingCallNavigation(
            PendingNavigation(path: '/call/$roomId'));
      }
    } catch (e, s) {
      debugPrint('Error in call accept, ending CallKit call');
      CallKitService.instance.endCall(kitCallId);
      debugPrintStack(label: 'Error handling call accept: $e', stackTrace: s);
    }
  }

  @pragma('vm:entry-point')
  Future<void> _storeCallAcceptance(
      String callId, String roomId, String? eventId) async {
    initialDeepLinkRoute = "/call/$roomId";
    try {
      // Store call acceptance information
      final acceptanceData = {
        'call_id': callId,
        'room_id': roomId,
        'event_id': eventId,
        'accepted_at': DateTime.now().millisecondsSinceEpoch,
        'accepted_via_callkit': true,
      };

      // Store using a well-known key that the Matrix service can check
      await CommonComponents.saveData(
          key: 'accepted_call_$callId', value: jsonEncode(acceptanceData));

      // Also store the most recent acceptance for general checking
      await CommonComponents.saveData(
          key: 'last_accepted_call', value: jsonEncode(acceptanceData));

      debugPrint('Stored call acceptance data for call $callId');
    } catch (e) {
      debugPrint('Error storing call acceptance: $e');
    }
  }

  @pragma('vm:entry-point')
  void _handleCallDecline(CallEvent data) async {
    try {
      final callId = data.body?['extra']?['call_id'] ?? data.body?['id'];
      final roomId = data.body?['extra']?['room_id'];

      debugPrint('Call declined via CallKit: $callId');
      await NavigationQueue.setPendingCallNavigation(null);
      if (callId != null) {
        final calls = MatrixCallService.instance;
        final room = calls?.client.getRoomById(roomId);
        if (calls != null && room != null) {
          await calls.declineIncomingCall(callId);
        }
      }
    } catch (e) {
      debugPrint('Error handling call decline: $e');
    }
  }

  @pragma('vm:entry-point')
  void _handleCallEnded(CallEvent data) async {
    try {
      final callId = data.body?['extra']?['call_id'] ?? data.body?['id'];
      final roomId = data.body?['extra']?['room_id'];

      debugPrint('Call ended via CallKit: $callId in room: $roomId');
      await NavigationQueue.setPendingCallNavigation(null);
      if (roomId != null) {
        // Get Matrix call service instance
        final calls = MatrixCallService.instance;
        if (calls != null) {
          // End the call in Matrix
          final session = calls.getSession(roomId);
          if (session != null) {
            await session.hangup(reason: matrix.CallErrorCode.userHangup);
          }
        }
        // Clean up overlays
        NavigationService.cleanupAllOverlays();
      }
    } catch (e) {
      debugPrint('Error handling call end: $e');
    }
  }

  @pragma('vm:entry-point')
  void _handleCallTimeout(CallEvent data) {
    debugPrint('Call timeout: ${data.body?['id']}');
    // Call was missed - Matrix service should handle cleanup
    NavigationQueue.setPendingCallNavigation(null);
  }

  @pragma('vm:entry-point')
  void _handleCallCallback(CallEvent data) {
    debugPrint('Call callback requested: ${data.body?['id']}');
    // User wants to call back - implement if needed
  }

  @pragma('vm:entry-point')
  void _handleCallToggleHold(CallEvent data) {
    debugPrint('Call hold toggle: ${data.body?['id']}');
    // iOS specific - implement if needed
  }

  @pragma('vm:entry-point')
  void _handleCallToggleMute(CallEvent data) async {
    try {
      final roomId = data.body?['extra']?['room_id'];

      debugPrint('Call mute toggle via CallKit in room: $roomId');

      if (roomId != null) {
        // Get Matrix call service instance
        final matrixService = MatrixCallService.instance;
        if (matrixService != null) {
          // Toggle mute in Matrix
          final session = matrixService.getSession(roomId);
          if (session != null) {
            await session.setMicrophoneMuted(!session.isMicrophoneMuted);
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling mute toggle: $e');
    }
  }

  @pragma('vm:entry-point')
  void _handleCallToggleDmtf(CallEvent data) {
    debugPrint('Call DTMF toggle: ${data.body?['id']}');
    // iOS specific - implement if needed
  }

  @pragma('vm:entry-point')
  void _handleCallToggleGroup(CallEvent data) {
    debugPrint('Call group toggle: ${data.body?['id']}');
    // iOS specific - implement if needed
  }

  @pragma('vm:entry-point')
  void _handleCallToggleAudioSession(CallEvent data) {
    debugPrint('Call audio session toggle: ${data.body?['id']}');
    // iOS specific - implement if needed
  }

  @pragma('vm:entry-point')
  void _handleDevicePushTokenUpdate(CallEvent data) {
    debugPrint('Device push token updated: ${data.body?['id']}');
    // Handle VoIP push token updates if needed
  }

  @pragma('vm:entry-point')
  void _handleCallCustom(CallEvent data) {
    debugPrint('Call custom action: ${data.body?['id']}');
    // Handle custom actions if needed
  }

  @pragma('vm:entry-point')
  void _handleCallConnected(CallEvent data) {
    debugPrint('Call connected: ${data.body?['id']}');
    // Call is now connected - Matrix service should handle this
  }

  /// إزالة المستمع
  @pragma('vm:entry-point')
  Future<void> dispose() async {
    try {
      debugPrint('CallKit disposed');
    } catch (e) {
      debugPrint('Error disposing CallKit: $e');
    }
  }
}
