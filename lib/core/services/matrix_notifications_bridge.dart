import 'dart:async';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/services/matrix_call_service.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';

@pragma('vm:entry-point')
class MatrixNotificationsBridge {
  static const String channelKey = 'matrix_messages';
  static const String ongoingChannelKey = 'matrix_calls';
  static const String actionKeyOpenRoom = 'OPEN_ROOM';
  static const String actionKeyAcceptCall = 'ACCEPT_CALL';
  static const String actionKeyDeclineCall = 'DECLINE_CALL';
  static const String actionKeyMarkRead = 'MARK_READ';
  static const String actionKeyReply = 'REPLY';
  static const String actionKeyMute = 'MUTE_CALL';
  static const String actionKeySpeaker = 'SPEAKER_TOGGLE';
  static const String actionKeyHangup = 'HANGUP_CALL';

  // Rooms currently visible in UI; suppress notifications for these
  static final Set<String> _activeRoomIds = <String>{};

  // Recently shown call invites (callId -> epoch ms) to suppress duplicates
  static final Map<String, int> _recentCallInvites = <String, int>{};
  static const int _callInviteDedupMs = 45 * 1000; // 45 seconds
  // Per-room last notified timestamp (ms). Prevents notifications for backfilled history
  static final Map<String, int> _lastNotifiedTsByRoom = <String, int>{};

  static void setRoomActive(String roomId, bool isActive) {
    if (isActive) {
      _activeRoomIds.add(roomId);
    } else {
      _activeRoomIds.remove(roomId);
    }
  }

  final Client client;
  StreamSubscription<SyncUpdate>? _sub;

  MatrixNotificationsBridge(this.client);

  static Future<void> ensureInitialized() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: ongoingChannelKey,
          channelName: 'مكالمات جارية',
          channelDescription: 'إشعار مستمر للمكالمات والإجراءات',
          defaultColor: const Color(0xFF0052CC),
          ledColor: const Color(0xFF0052CC),
          importance: NotificationImportance.Max,
          playSound: false,
          enableVibration: false,
          channelShowBadge: false,
          locked: true,
        ),
      ],
      debug: kDebugMode,
    );
  }

  static Future<void> showOngoingCall({
    required String roomId,
    required String callId,
    required bool muted,
    required bool speakerOn,
    required String title,
    String? largeIconUrl,
  }) async {
    if (Platform.isAndroid) {
      await ensureInitialized();
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: roomId.hashCode,
          channelKey: ongoingChannelKey,
          title: title,
          body: muted ? 'صامت' : 'نشط',
          payload: {'roomId': roomId, 'callId': callId},
          category: NotificationCategory.Call,
          notificationLayout: NotificationLayout.Default,
          largeIcon: largeIconUrl,
          autoDismissible: false,
          locked: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: actionKeyMute,
            label: muted ? 'إلغاء الكتم' : 'كتم',
            actionType: ActionType.SilentAction,
          ),
          NotificationActionButton(
            key: actionKeySpeaker,
            label: speakerOn ? 'الهاتف' : 'المكبر',
            actionType: ActionType.SilentAction,
          ),
          NotificationActionButton(
            key: actionKeyHangup,
            label: 'إنهاء',
            actionType: ActionType.SilentAction,
          ),
        ],
      );
    }
  }

  @pragma('vm:entry-point')
  static Future<void> dismissOngoingCall(String roomId) async {
    try {
      await AwesomeNotifications().dismiss(roomId.hashCode);
    } catch (_) {}
  }

  Future<void> start() async {
    await ensureInitialized();
    _sub?.cancel();
    _sub = client.onSync.stream.listen(_onSync);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onSync(SyncUpdate sync) async {
    final joined = sync.rooms?.join ?? {};
    for (final entry in joined.entries) {
      final roomId = entry.key;
      final joinedRoom = entry.value;
      final timeline = joinedRoom.timeline?.events ?? [];
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final roomThreshold = _lastNotifiedTsByRoom[roomId] ??
          nowMs; // initialize to now on first sight
      int maxSeenTs = roomThreshold;
      for (final me in timeline) {
        // Convert to Event for evaluation
        try {
          final room = client.getRoomById(roomId);
          if (room == null) continue;
          final event = Event.fromMatrixEvent(me, room);
          if (room.membership != Membership.join) continue;
          // Suppress notifications when the room is open/active in UI
          if (_activeRoomIds.contains(roomId)) continue;
          // Skip backfilled history (older than last seen)
          final ts = event.originServerTs.millisecondsSinceEpoch;
          if (ts <= roomThreshold) continue;
          if (ts > maxSeenTs) maxSeenTs = ts;
          // Handle incoming call notifications
          if (event.type == EventTypes.CallInvite) {
            final callId = event.content['call_id'] as String?;
            if (callId == null) continue;
            // deduplicate rapid duplicate call notifications
            final now = DateTime.now().millisecondsSinceEpoch;
            final last = _recentCallInvites[callId];
            if (last != null && (now - last) < _callInviteDedupMs) {
              continue;
            }
            _recentCallInvites[callId] = now;
            // Play alert sound for incoming call (soft)
            try {
              // SystemSound.play(SystemSoundType.alert);
            } catch (e) {
              debugPrint("Play sound error: $e");
            }
            // Try include room avatar as large icon
            String? largeIcon;
            try {
              final avatar = room.avatar;
              if (avatar != null) {
                largeIcon = avatar
                    .getThumbnailUri(room.client, width: 96, height: 96)
                    .toString();
              }
            } catch (_) {}
            /*AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
                channelKey: channelKey,
                title: 'مكالمة واردة',
                body: room.getLocalizedDisplayname(),
                payload: {'roomId': room.id, 'callId': callId},
                category: NotificationCategory.Call,
                largeIcon: largeIcon,
              ),
              actionButtons: [
                NotificationActionButton(
                  key: actionKeyAcceptCall,
                  label: 'رد',
                  actionType: ActionType.Default,
                ),
                NotificationActionButton(
                  key: actionKeyDeclineCall,
                  label: 'رفض',
                  actionType: ActionType.SilentAction,
                ),
              ],
            );*/
            // await CallKitService.instance.showIncomingCall(
            //   callerName: event.senderId,
            //   callerId: event.senderId,
            //   roomId: roomId,
            //   callId: callId,
            // );
            continue;
          }

          if (event.type != EventTypes.Message) continue;
          if (event.senderId == client.userID) continue;

          final actions = client.pushruleEvaluator.match(event);
          if (!actions.notify) continue;

          final roomName = room.getLocalizedDisplayname();
          final timeline = await room.getTimeline();
          final body = event.getDisplayEvent(timeline).body;

          /*AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: room.id.hashCode,
              channelKey: NotificationService.messageChannelId,
              title: roomName,
              body: body,
              payload: {
                'type': 'message',
                'event_id': event.eventId,
                'room_id': room.id,
                'roomId': room.id,
                'eventId': event.eventId,
              },
              notificationLayout: NotificationLayout.MessagingGroup,
            ),
            actionButtons: [
              NotificationActionButton(
                key: NotificationService.actionKeyOpenRoom,
                label: 'فتح',
              ),
              NotificationActionButton(
                key: NotificationService.actionKeyMarkRead,
                label: 'تمميز كمقروء',
              ),
              NotificationActionButton(
                key: NotificationService.actionKeyReply,
                label: 'رد',
                requireInputText: true,
                actionType: ActionType.SilentBackgroundAction,
              ),
            ],
          );*/
        } catch (_) {
          // ignore parsing errors
        }
      }
      // Update last-notified watermark for this room
      _lastNotifiedTsByRoom[roomId] = maxSeenTs;
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _onAction(ReceivedAction action) async {
    final roomId = action.payload?['roomId'];
    final ctx = NavigationService.rootNavigatorKey.currentContext;

    if (roomId == null) return;

    if (action.buttonKeyPressed == actionKeyAcceptCall) {
      final callId = action.payload?['callId'];
      final calls = MatrixCallService.instance;
      if (callId != null && calls != null) {
        await calls.acceptIncomingCall(roomId, callId);
      }
      if (ctx != null) {
        NavigationService.navigateToCall(ctx, roomId);
      }
      return;
    }

    if (action.buttonKeyPressed == actionKeyDeclineCall) {
      final callId = action.payload?['callId'];
      final calls = MatrixCallService.instance;
      if (callId != null && calls != null) {
        await calls.declineIncomingCall(callId);
      }
      return;
    }
    if (action.buttonKeyPressed == actionKeyMute) {
      final calls = MatrixCallService.instance;
      if (calls == null) return;
      final s = calls.getSession(roomId);
      if (s != null) {
        await s.setMicrophoneMuted(!s.isMicrophoneMuted);
        String? largeIcon;
        try {
          final avatar = s.room.avatar;
          if (avatar != null) {
            largeIcon = avatar
                .getThumbnailUri(s.room.client, width: 96, height: 96)
                .toString();
          }
        } catch (_) {}
        await showOngoingCall(
          roomId: roomId,
          callId: s.callId,
          muted: s.isMicrophoneMuted,
          speakerOn: calls.speakerOn,
          title: s.room.getLocalizedDisplayname(),
          largeIconUrl: largeIcon,
        );
      }
      return;
    }
    if (action.buttonKeyPressed == actionKeySpeaker) {
      final calls = MatrixCallService.instance;
      if (calls == null) return;
      final s = calls.getSession(roomId);
      if (s != null) {
        await calls.setSpeaker(!calls.speakerOn);
        String? largeIcon;
        try {
          final avatar = s.room.avatar;
          if (avatar != null) {
            largeIcon = avatar
                .getThumbnailUri(s.room.client, width: 96, height: 96)
                .toString();
          }
        } catch (_) {}
        await showOngoingCall(
          roomId: roomId,
          callId: s.callId,
          muted: s.isMicrophoneMuted,
          speakerOn: calls.speakerOn,
          title: s.room.getLocalizedDisplayname(),
          largeIconUrl: largeIcon,
        );
      }
      return;
    }
    if (action.buttonKeyPressed == actionKeyHangup) {
      final calls = MatrixCallService.instance;
      final s = calls?.getSession(roomId);
      if (s != null) {
        await s.hangup(reason: CallErrorCode.userHangup);
        await dismissOngoingCall(roomId);
      }
      return;
    }
    if (action.buttonKeyPressed == actionKeyMarkRead) {
      final eventId = action.payload?['eventId'];
      if (eventId != null && ctx != null) {
        try {
          final matrix = ProviderScope.containerOf(ctx, listen: false)
              .read(ApiProviders.matrixChatProvider);
          final room = matrix.clientNullable?.getRoomById(roomId);
          if (room != null) {
            // Use setReadMarker instead of deprecated postReceipt
            await room.setReadMarker(eventId, mRead: eventId);
          }
        } catch (_) {}
      }
      return;
    }
    if (action.buttonKeyPressed == actionKeyReply) {
      final text = action.buttonKeyInput;
      if (text.trim().isNotEmpty && ctx != null) {
        try {
          final matrix = ProviderScope.containerOf(ctx, listen: false)
              .read(ApiProviders.matrixChatProvider);
          final room = matrix.clientNullable?.getRoomById(roomId);
          if (room != null) {
            await room.sendTextEvent(text.trim());
          }
        } catch (_) {}
      }
      return;
    }

    if (action.actionType == ActionType.Default && ctx != null) {
      NavigationService.navigateToCall(ctx, roomId);
    }

    if (ctx != null) {
      NavigationService.navigateToRoomTimeline(ctx, roomId);
    }
  }

  static Future<void> showIncomingCall(IncomingCall inc) async {
    try {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
          channelKey: channelKey,
          title: 'مكالمة واردة',
          body: inc.room.getLocalizedDisplayname(),
          payload: {'roomId': inc.room.id, 'callId': inc.callId},
          category: NotificationCategory.Call,
          fullScreenIntent: true,
          largeIcon: inc.room.avatar.toString(),
          showWhen: true,
          wakeUpScreen: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: actionKeyAcceptCall,
            label: 'رد',
            color: Colors.green,
            actionType: ActionType.SilentBackgroundAction,
          ),
          NotificationActionButton(
            key: actionKeyDeclineCall,
            label: 'رفض',
            color: Colors.redAccent,
            actionType: ActionType.SilentBackgroundAction,
          ),
        ],
      );
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: "showIncomingCall error: $e");
    }
  }
}

// no extension needed; use .notify directly
