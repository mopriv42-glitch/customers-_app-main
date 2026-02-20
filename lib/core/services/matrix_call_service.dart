import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/voip/models/call_options.dart';
import 'package:matrix/src/voip/models/voip_id.dart';
import 'package:private_4t_app/core/services/matrix_notifications_bridge.dart';

@pragma('vm:entry-point')
class MatrixCallService extends ChangeNotifier {
  static MatrixCallService? instance;
  final Client client;
  final VoIP voIP;
  bool _speakerOn = false;

  bool get speakerOn => _speakerOn;
  final Map<String, CallSession> _activeByRoom = {};
  final Map<String, IncomingCall> _incomingById = {};
  final StreamController<IncomingCall> _incomingCtrl =
      StreamController<IncomingCall>.broadcast();
  StreamSubscription? _sub;
  final Map<String, Timer> _ringByRoom = {};

  MatrixCallService(this.client, this.voIP) {
    instance = this;
  }

  @pragma('vm:entry-point')
  CallSession? getSession(String roomId) {
    return _activeByRoom[roomId];
  }

  @pragma('vm:entry-point')
  Future<void> setSpeaker(bool on) async {
    try {
      _speakerOn = on;
      await Helper.setSpeakerphoneOn(on);
    } catch (e) {
      debugPrint('Error setting speakerphone: $e');
    }
    notifyListeners();
  }

  String? get anyActiveRoomId =>
      _activeByRoom.isEmpty ? null : _activeByRoom.keys.first;

  bool get hasActiveCall => _activeByRoom.isNotEmpty;

  Future<void> endAllCalls() async {
    final activeRooms = List<String>.from(_activeByRoom.keys);
    for (final roomId in activeRooms) {
      final session = _activeByRoom[roomId];
      if (session != null) {
        await session.hangup(reason: CallErrorCode.userHangup);
      }
    }
    _activeByRoom.clear();
    _incomingById.clear();
    notifyListeners();
  }

  @pragma('vm:entry-point')
  Future<void> endCall(String roomId) async {
    _activeByRoom.remove(roomId);
    notifyListeners();
  }

  Stream<IncomingCall> get incomingCalls => _incomingCtrl.stream;

  @pragma('vm:entry-point')
  Future<void> start() async {
    await _sub?.cancel();
    // client.onCallEvents.stream.listen((es) {
    //   for (var e in es) {
    //     if (e.senderId == client.userID) continue;
    //     print("The on call events ${e.type} sender ${e.senderId}");
    //   }
    // });
    //
    // client.onNotification.stream.listen((e) {
    //   if (e.senderId == client.userID) return;
    //   print(
    //       "The on notification events ${e.type} sender ${e.senderId} ,content: ${e.content.toString()}");
    // });
    //
    // client.onTimelineEvent.stream.listen((e) {
    //   if (e.senderId == client.userID) return;
    //   print("The on timeLineEvent events ${e.type} sender ${e.senderId}");
    // });
    // _sub = client.onTimelineEvent.stream.listen(_handleEvent);
    // client.onNotification.stream.listen(_handleEvent);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<CallSession> startCall(Room room, CallType type,
      {String? userId}) async {
    final session = await voIP.inviteToCall(room, type, userId: userId);
    _activeByRoom[room.id] = session;
    notifyListeners();
    return session;
  }

  @pragma('vm:entry-point')
  Future<void> acceptIncomingCall(String roomId, String callId,
      [String? eventId]) async {
    final session = await createCallSession(roomId, callId, eventId);

    if (session == null) return;

    await session.answer();

    _activeByRoom[roomId] = session;

    await MatrixNotificationsBridge.showOngoingCall(
      roomId: session.room.id,
      callId: callId,
      muted: session.isMicrophoneMuted,
      speakerOn: _speakerOn,
      title: session.room.getLocalizedDisplayname(),
    );

    notifyListeners();
  }

  Future<void> declineIncomingCall(String callId) async {
    final voipId = voIP.currentCID;
    final s = voIP.calls[voipId];
    _activeByRoom.remove(s?.room.id);
    notifyListeners();
  }

  Future<CallSession?> createCallSession(String roomId, String callId,
      [String? eventId]) async {
    final room = client.getRoomById(roomId);
    if (room == null) return null;
    final iceServers = await voIP.getIceServers();
    final voipId = VoipId(roomId: roomId, callId: callId);
    CallSession? session = voIP.calls[voipId];
    if (session == null && eventId != null) {
      final event = await room.getEventById(eventId);
      if (event != null) {
        final remoteUserId = event.senderId;
        final remoteDeviceId =
            event.content.tryGet<String>('invitee_device_id');
        final content = event.content;
        final int lifetime = content['lifetime'] as int;
        final String? confId = content['conf_id'] as String?;
        var callType = CallType.kVoice;
        SDPStreamMetadata? sdpStreamMetadata;

        if (event.content['org.matrix.msc3077.sdp_stream_metadata'] != null) {
          sdpStreamMetadata = SDPStreamMetadata.fromJson(
              content.tryGetMap<String, dynamic>(
                      'org.matrix.msc3077.sdp_stream_metadata') ??
                  {});
        }

        final offerMap = content['offer'] as Map<String, dynamic>;

        final offer = RTCSessionDescription(
          offerMap['sdp'],
          offerMap['type'],
        );

        session ??= voIP.createNewCall(CallOptions(
          callId: callId,
          type:callType,
          dir: CallDirection.kIncoming,
          localPartyId: client.deviceID ?? '',
          voip: voIP,
          room: room,
          iceServers: iceServers,
        ));

        session.remoteUserId = remoteUserId;
        session.remoteDeviceId = remoteDeviceId;
        session.remotePartyId = content['party_id'] as String?;
        session.remoteSessionId = content['sender_session_id'] as String?;

       await session.initWithInvite(
            CallType.kVoice, offer, sdpStreamMetadata, lifetime, false,);
      }
    }

    return session;
  }

  Future<bool> acceptIncomingCallByPayload(
      String roomId, String callId, Map<String, dynamic> offer) async {
    return false;
  }

  String _randomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    return List.generate(16, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  void _startRinging(String roomId) {
    _stopRinging(roomId);
    _ringByRoom[roomId] = Timer.periodic(const Duration(seconds: 1), (_) {});
    SystemSound.play(SystemSoundType.alert);
  }

  @pragma('vm:entry-point')
  void _stopRinging(String roomId) {
    final t = _ringByRoom.remove(roomId);
    t?.cancel();
  }
}

@pragma('vm:entry-point')
class IncomingCall {
  final String callId;
  final Room room;
  final Map<String, dynamic> offer;

  IncomingCall({required this.callId, required this.room, required this.offer});
}
