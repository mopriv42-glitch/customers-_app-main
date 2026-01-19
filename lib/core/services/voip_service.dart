import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc_impl;
import 'package:matrix/matrix.dart';
import 'package:private_4t_app/core/services/matrix_call_service.dart';
import 'package:private_4t_app/core/services/matrix_notifications_bridge.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:webrtc_interface/src/mediadevices.dart';
import 'package:webrtc_interface/src/rtc_peerconnection.dart';

import 'call_kit_service.dart';

@pragma('vm:entry-point')
class VoipService implements WebRTCDelegate {
  @override
  @pragma('vm:entry-point')
  bool get canHandleNewCall => true;

  @override
  @pragma('vm:entry-point')
  Future<RTCPeerConnection> createPeerConnection(
      Map<String, dynamic> configuration,
      [Map<String, dynamic> constraints = const {}]) {
    return webrtc_impl.createPeerConnection(configuration, constraints);
  }

  @pragma('vm:entry-point')
  webrtc_impl.VideoRenderer createRenderer() => webrtc_impl.RTCVideoRenderer();

  @override
  @pragma('vm:entry-point')
  Future<void> handleCallEnded(CallSession session) async {
    await MatrixNotificationsBridge.dismissOngoingCall(session.room.id);
    await MatrixCallService.instance?.endCall(session.room.id);
    await CallKitService.instance.endCall(session.callId);
    NavigationService.hideCallOverlay();
  }

  @override
  Future<void> handleGroupCallEnded(GroupCallSession groupCall) async {
    // TODO: implement handleGroupCallEnded
    // throw UnimplementedError();
  }

  @override
  Future<void> handleMissedCall(CallSession session) async {
    // TODO: implement handleMissedCall
    // throw UnimplementedError();
  }

  @override
  @pragma('vm:entry-point')
  Future<void> handleNewCall(CallSession session) async {
    switch (session.direction) {
      case CallDirection.kOutgoing:
        String? largeIcon;
        try {
          final avatar = session.room.avatar;
          if (avatar != null) {
            largeIcon = (await avatar.getThumbnailUri(session.room.client,
                    width: 96, height: 96))
                .toString();
          }
        } catch (_) {}
        MatrixNotificationsBridge.showOngoingCall(
          roomId: session.room.id,
          callId: session.callId,
          muted: session.isMicrophoneMuted,
          speakerOn: false,
          title: session.room.getLocalizedDisplayname(),
          largeIconUrl: largeIcon,
        );
        break;
      case CallDirection.kIncoming:
        // if(NavigationService.rootNavigatorKey.currentContext != null){
        debugPrint(
            "Incoming call id: ${session.callId} From ${session.remoteUserId}");
        await CallKitService.instance.showIncomingCall(
          callerName: session.room.getLocalizedDisplayname(),
          callerId: session.remoteUser?.id.toString() ?? session.localPartyId,
          roomId: session.room.id,
          callId: session.callId,
          avatarUrl: session.room.avatar.toString(),
        );

        // }
        break;
    }
  }

  @override
  Future<void> handleNewGroupCall(GroupCallSession groupCall) async {
    // TODO: implement handleNewGroupCall
    // throw UnimplementedError();
  }

  @override
  // TODO: implement isWeb
  bool get isWeb => false;

  @override
  // TODO: implement keyProvider
  EncryptionKeyProvider? get keyProvider => null;

  @override
  // TODO: implement mediaDevices
  MediaDevices get mediaDevices => webrtc_impl.navigator.mediaDevices;

  @override
  Future<void> playRingtone() async {
    // TODO: implement playRingtone
    // throw UnimplementedError();
  }

  @override
  @pragma('vm:entry-point')
  Future<void> registerListeners(CallSession session) async {
    // TODO: implement registerListeners
    // throw UnimplementedError();
    session.onCallStreamsChanged.stream.listen((CallSession session) async {});
    session.onCallReplaced.stream.listen((CallSession session) async {});
    session.onCallHangupNotifierForGroupCalls.stream
        .listen((CallSession session) async {});
    session.onCallStateChanged.stream.listen((CallState event) async {
      debugPrint("Change the call state to ${event.toString()}");
    });
    session.onCallEventChanged.stream.listen((CallStateChange event) async {});
    session.onStreamAdd.stream.listen((WrappedMediaStream event) async {});
    session.onStreamRemoved.stream.listen((WrappedMediaStream event) async {});
  }

  @override
  Future<void> stopRingtone() async {
    // TODO: implement stopRingtone
    // throw UnimplementedError();
  }
}
