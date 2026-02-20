import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:matrix/matrix.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/providers/app_container.dart';
import 'package:private_4t_app/core/providers/matrix_chat_provider.dart';
import 'package:private_4t_app/core/services/call_kit_service.dart';
import 'package:private_4t_app/core/services/matrix_call_service.dart';

import '../models/call_state.dart';
import '../services/call_service.dart';
import '../services/voip_config_service.dart';

class CallNotifier extends StateNotifier<AppCallState> {
  Timer? _durationTimer;
  DateTime? _callStartTime;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  late MatrixChatProvider _matrix;
  late MatrixCallService _calls;
  Map<String, dynamic> _storedOffer = {};

  // Queue remote ICE candidates until remote description is set
  final List<RTCIceCandidate> _pendingRemoteCandidates = <RTCIceCandidate>[];
  bool _remoteDescriptionSet = false;

  // Grace period to avoid ending the call on brief network/audio route hiccups
  Timer? _disconnectGraceTimer;
  static const int _disconnectGraceSeconds = 5;

  /// Remove unwanted codecs and optionally drop the entire video m-line.
  String _sanitizeSdp(String sdp, {required bool keepVideo}) {
    var text = sdp.replaceAll('\r\n', '\n');
    // Force ice-options trickle only
    text = text.replaceAll(
        'ice-options:trickle renomination', 'ice-options:trickle');

    if (!keepVideo) {
      final videoSection =
          RegExp(r'\nm=video[\s\S]*?(?=\n[m]=|$)', multiLine: true);
      text = text.replaceAll(videoSection, '\n');
    }

    final lines = text.split('\n');
    final filtered = <String>[];
    for (final l in lines) {
      if (l.startsWith('a=rtpmap') || l.startsWith('a=fmtp')) {
        final keep = l.contains('opus/48000/2') ||
            l.contains('telephone-event/8000') ||
            l.contains('telephone-event/48000');
        if (!keep) continue;
      }
      filtered.add(l);
    }
    return filtered.join('\n');
  }

  CallNotifier() : super(const AppCallState()) {
    _matrix = providerAppContainer.read(ApiProviders.matrixChatProvider);
    _calls = MatrixCallService.instance ?? MatrixCallService(_matrix.client,_matrix.voIp);
    // _setupCallListeners();
  }

  /// Refresh VoIP configuration from Matrix server
  Future<void> refreshVoipConfig() async {
    try {
      VoipConfigService.instance.clearCache();
      await VoipConfigService.instance.getIceServers();
      print('✅ VoIP configuration refreshed');
    } catch (e) {
      print('❌ Failed to refresh VoIP configuration: $e');
    }
  }

  /// For debugging prolonged ICE failures: force relay-only to test TURN path quickly
  Future<void> forceRelayOnly(bool enable) async {
    try {
      VoipConfigService.instance.setForceRelayOnly(enable);
      await refreshVoipConfig();
      debugPrint('Force relay-only mode: $enable');
    } catch (e) {
      debugPrint('Error toggling relay-only mode: $e');
    }
  }

  /// Get current VoIP configuration info for debugging
  Map<String, dynamic> getVoipConfigInfo() {
    return VoipConfigService.instance.getConfigInfo();
  }

  void _setupCallListeners() {
    debugPrint("Setup call listeners");
    try {
      final client = _matrix.client;
      client.onNotification.stream.listen((Event event) {
        if (event.type == 'm.call.invite') {
          _handleIncomingCall(event);
        }
      });

      client.onCallEvents.stream.listen(
        (events) {
          for (var event in events) {
            debugPrint(
                "The event type is ${event.type}, content: ${event.content.toString()}");
            final type = event.type;
            switch (type) {
              case EventTypes.CallAnswer:
                _handleCallAnswer(event);
                break;

              case 'm.call.hangup':
                _handleCallHangup(event);
                break;

              case 'm.call.candidates':
                _handleCallCandidates(event);
                break;

              case 'm.call.reject':
                _handleCallReject(event);
                break;

              case 'm.call.select_answer':
                _handleCallSelectAnswer(event);
                break;

              default:
                debugPrint('Unhandled call event: $type');
            }
          }
        },
        onError: (err) => debugPrint('Error in callEvents stream: $err'),
        onDone: () => debugPrint('CallEvents stream closed'),
      );

      debugPrint('Call listeners registered ✅');
    } catch (e, s) {
      debugPrintStack(
          label: 'Error setting up call listeners: $e', stackTrace: s);
    }
  }

  Future<void> startCall(String roomId, bool isVideoCall) async {
    try {
      // Check permissions first
      final hasPermissions = await _checkCallPermissions(isVideoCall);
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }

      state = state.copyWith(
        isLoading: true,
        roomId: roomId,
        isVideoCall: isVideoCall,
        isIncoming: false,
        status: CallStatus.connecting,
      );

      final client = _matrix.client;
      final room = client.getRoomById(roomId);

      if (room == null) {
        throw Exception('Room not found');
      }

      final session = await _calls.startCall(room,CallType.kVoice);

      state = state.copyWith(
        callId: session.callId,
        callerName: session.room.getLocalizedDisplayname(),
        status: CallStatus.ringing,
        isLoading: false,
      );

      // Auto-timeout after 60 seconds if no answer
      Timer(const Duration(seconds: 60), () {
        if (state.status == CallStatus.ringing) {
          _endCall(CallStatus.missed);
        }
      });
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: 'Failed to start call: $e');
      state = state.copyWith(
        isLoading: false,
        status: CallStatus.error,
        error: 'Failed to start call: $e',
      );
    }
  }

  Future<void> answerCall(Map<String, dynamic> offer) async {
    if (state.callId == null || state.roomId == null) return;

    try {
      // Check permissions before answering
      final hasPermissions = await _checkCallPermissions(state.isVideoCall);
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }

      state = state.copyWith(
        isLoading: true,
        status: CallStatus.connecting,
      );

      // Initialize WebRTC for incoming call
      await _calls.acceptIncomingCallByPayload(
          state.roomId!, state.callId!, offer);

      // Process the stored offer first
      // final offerDescription = RTCSessionDescription(
      //   _storedOffer['sdp']?.toString() ?? '',
      //   _storedOffer['type']?.toString() ?? 'offer',
      // );

      // await _peerConnection!.setRemoteDescription(offerDescription);
      // _remoteDescriptionSet = true;
      //
      // // Align transceivers with remote offer before creating answer
      // try {
      //   final transceivers = await _peerConnection!.getTransceivers();
      //   final remoteHasVideo =
      //       (_storedOffer['sdp']?.toString() ?? '').contains('\nm=video ');
      //   for (final t in transceivers) {
      //     final kindSender = t.sender.track?.kind;
      //     final kindReceiver = t.receiver.track?.kind;
      //     final isAudio = kindSender == 'audio' || kindReceiver == 'audio';
      //     final isVideo = kindSender == 'video' || kindReceiver == 'video';
      //     if (isAudio) {
      //       try {
      //         await t.setDirection(TransceiverDirection.SendRecv);
      //       } catch (_) {}
      //     }
      //     if (isVideo && !remoteHasVideo) {
      //       try {
      //         await t.stop();
      //       } catch (_) {}
      //     }
      //   }
      // } catch (e) {
      //   debugPrint('Error aligning transceivers before answer: $e');
      // }
      //
      // // Create answer after setting remote description
      // final remoteDesc = await _peerConnection!.getRemoteDescription();
      // final remoteHasVideo = (remoteDesc?.sdp ?? '').contains('\nm=video ');
      // var answer = await _peerConnection!.createAnswer({
      //   'offerToReceiveAudio': 1,
      //   'offerToReceiveVideo': remoteHasVideo && state.isVideoCall ? 1 : 0,
      // });
      // final sanitizedAnswerSdp = _sanitizeSdp(answer.sdp ?? '',
      //     keepVideo: remoteHasVideo && state.isVideoCall);
      // answer = RTCSessionDescription(sanitizedAnswerSdp, answer.type);
      // await _peerConnection!.setLocalDescription(answer);

      final client = _matrix.client;
      final room = client.getRoomById(state.roomId!);

      state = state.copyWith(
        status: CallStatus.connecting,
        isLoading: false,
      );

      // _startDurationTimer();
      // await CallKitService.instance.endCall(state.callId ?? const Uuid().v4());
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: 'Failed to answer call: $e');
      state = state.copyWith(
        isLoading: false,
        status: CallStatus.error,
        error: 'Failed to answer call: $e',
      );
    }
  }

  Future<void> declineCall() async {
    if (state.callId == null || state.roomId == null) return;

    try {
      final client = _matrix.client;
      final room = client.getRoomById(state.roomId!);

      if (room != null) {
        await room.sendEvent({
          'call_id': state.callId,
          'version': 1,
          'reason': 'user_declined',
        }, type: EventTypes.CallHangup);
      }

      await _endCall(CallStatus.declined);
      // await CallKitService.instance.endCall(state.callId ?? const Uuid().v4());
    } catch (e) {
      state = state.copyWith(error: 'Failed to decline call: $e');
    }
  }

  Future<void> hangupCall() async {
    if (state.callId == null || state.roomId == null) return;

    try {
      final client = _matrix.client;
      final room = client.getRoomById(state.roomId!);

      if (room != null) {
        await room.sendEvent({
          'call_id': state.callId,
          'version': 1,
          'reason': 'user_hangup',
        }, type: EventTypes.CallHangup);
      }

      await _endCall(CallStatus.ended);
    } catch (e) {
      state = state.copyWith(error: 'Failed to hang up call: $e');
    }
  }

  void toggleMute() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        final currentState = !state.isMuted;
        audioTracks.first.enabled = !currentState;
        state = state.copyWith(isMuted: currentState);
      }
    }
  }

  void toggleSpeaker() async {
    final newSpeakerState = !state.isSpeakerOn;
    state = state.copyWith(isSpeakerOn: newSpeakerState);

    // Configure actual audio output
    try {
      await Helper.setSpeakerphoneOn(newSpeakerState);
      debugPrint('Speaker phone set to: $newSpeakerState');
    } catch (e) {
      debugPrint('Error setting speaker phone: $e');
      // Revert state if setting failed
      state = state.copyWith(isSpeakerOn: !newSpeakerState);
    }
  }

  void toggleVideo() {
    if (_localStream != null && state.isVideoCall) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        final currentState = !state.isVideoEnabled;
        videoTracks.first.enabled = currentState;
        state = state.copyWith(isVideoEnabled: currentState);
      }
    }
  }

  void _handleIncomingCall(Event event) async {
    final content = event.content;
    final callId = content['call_id']?.toString();
    final roomId = event.room.id;
    final offer = content['offer'];
    final isVideoCall = _determineCallType(content, offer);

    // بدل senderFromMemoryOrFallback
    String? callerName = (await _matrix.client.getDisplayName(event.senderId));

    final member = event.room.unsafeGetUserFromMemoryOrFallback(event.senderId);
    if (member.displayName != null) {
      callerName = member.displayName!;
    }

    // Store the offer for when the call is answered
    _storedOffer = offer is Map<String, dynamic> ? offer : {};

    state = state.copyWith(
      callId: callId,
      roomId: roomId,
      // بدل event.roomId
      callerName: callerName,
      isVideoCall: isVideoCall,
      isIncoming: true,
      status: CallStatus.ringing,
    );

    // Show call notification
    if (callId != null) {
      CallKitService.instance.showIncomingCall(
        callerName: callerName ?? event.senderId,
        callerId: event.senderId,
        roomId: roomId,
        callId: callId,
      );
    }

    // Auto-decline after 60 seconds if not answered
    Timer(const Duration(seconds: 60), () {
      if (state.status == CallStatus.ringing && state.isIncoming) {
        declineCall();
      }
    });
  }

  bool _determineCallType(Map<String, dynamic> content, dynamic offer) {
    // Check if it's explicitly marked as video
    if (content['type'] == 'm.video') return true;

    // Check the SDP offer for video tracks
    if (offer != null && offer['sdp'] != null) {
      final sdp = offer['sdp'].toString().toLowerCase();
      return sdp.contains('m=video') && !sdp.contains('m=video 0');
    }

    return false;
  }

  void _handleCallAnswer(BasicEventWithSender event) {
    final callId = event.content['call_id']?.toString();
    if (callId == state.callId && _peerConnection != null) {
      final answerData = event.content['answer'];
      if (answerData != null && answerData is Map<String, dynamic>) {
        _processAnswer(answerData);
      }
    }
  }

  Future<void> _processAnswer(Map<String, dynamic> answerData) async {
    try {
      final description = RTCSessionDescription(
        answerData['sdp']?.toString() ?? '',
        answerData['type']?.toString() ?? 'answer',
      );

      await _peerConnection!.setRemoteDescription(description);
      _remoteDescriptionSet = true;
      print('Remote description set successfully');

      // Apply any queued remote ICE candidates now that remote description is set
      final queued = List<RTCIceCandidate>.from(_pendingRemoteCandidates);
      _pendingRemoteCandidates.clear();
      for (final c in queued) {
        try {
          await _peerConnection!.addCandidate(c);
          debugPrint('Applied queued ICE candidate after answer.');
        } catch (e) {
          debugPrint('Error applying queued ICE candidate after answer: $e');
        }
      }
    } catch (e, s) {
      debugPrintStack(
          stackTrace: s, label: 'Failed to process call answer: $e');
      state = state.copyWith(
        status: CallStatus.error,
        error: 'Failed to process call answer: $e',
      );
    }
  }

  void _handleCallHangup(BasicEventWithSender event) {
    final callId = event.content['call_id']?.toString();
    if (callId == state.callId) {
      final reason = event.content['reason'];
      CallStatus status = CallStatus.ended;

      if (reason == 'user_declined') {
        status = CallStatus.declined;
      } else if (state.status == CallStatus.ringing && state.isIncoming) {
        status = CallStatus.missed;
      }

      _endCall(status);
    }
  }

  void _handleCallCandidates(BasicEventWithSender event) {
    final callId = event.content['call_id']?.toString();
    if (callId == state.callId && _peerConnection != null) {
      final candidates = event.content['candidates'];
      if (candidates is List) {
        for (final candidateData in candidates) {
          if (candidateData is Map<String, dynamic>) {
            _processIceCandidate(candidateData);
          }
        }
      }
    }
  }

  Future<void> _processIceCandidate(Map<String, dynamic> candidateData) async {
    try {
      final candidate = RTCIceCandidate(
        candidateData['candidate']?.toString() ?? '',
        candidateData['sdpMid']?.toString(),
        (candidateData['sdpMLineIndex'] as num?)?.toInt(),
      );

      if (_peerConnection == null) return;
      if (_remoteDescriptionSet) {
        await _peerConnection!.addCandidate(candidate);
        print('ICE candidate added successfully');
      } else {
        _pendingRemoteCandidates.add(candidate);
        debugPrint('Queued ICE candidate (remote description not set yet)');
      }
    } catch (e) {
      print('Error adding ICE candidate: $e');
    }
  }

  void _handleCallSelectAnswer(BasicEventWithSender event) {
    final callId = event.content['call_id']?.toString();
    if (callId == state.callId) {
      // Another device answered the call
      _endCall(CallStatus.ended);
    }
  }

  void _handleCallReject(BasicEventWithSender event) {
    final callId = event.content['call_id']?.toString();
    if (callId == state.callId) {
      _endCall(CallStatus.declined);
    }
  }

  Future<void> _initializeWebRTC(bool isVideoCall) async {
    try {
      // Get user media with proper constraints
      final constraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': isVideoCall
            ? {
                'width': {'min': 640, 'ideal': 1280, 'max': 1920},
                'height': {'min': 480, 'ideal': 720, 'max': 1080},
                'frameRate': {'min': 15, 'ideal': 30, 'max': 60},
                'facingMode': 'user',
              }
            : false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      debugPrint(
          '🎤 Local stream created with ${_localStream!.getAudioTracks().length} audio tracks');

      // Ensure local audio tracks are enabled
      for (final audioTrack in _localStream!.getAudioTracks()) {
        audioTrack.enabled = true;
        debugPrint('Local audio track enabled: ${audioTrack.id}');
      }

      // Get VoIP configuration from Matrix server
      final rtcConfig = await VoipConfigService.instance.getRTCConfiguration();

      debugPrint('🌐 WebRTC Config: $rtcConfig');

      // Create peer connection with dynamic ICE servers
      _peerConnection = await createPeerConnection(rtcConfig);

      // Add local stream tracks
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // Ensure transceiver directions are correct (sendrecv for audio)
      try {
        final transceivers = await _peerConnection!.getTransceivers();
        for (final t in transceivers) {
          final kindSender = t.sender.track?.kind;
          final kindReceiver = t.receiver.track?.kind;
          final isAudio = kindSender == 'audio' || kindReceiver == 'audio';
          final isVideo = kindSender == 'video' || kindReceiver == 'video';
          if (isAudio) {
            try {
              await t.setDirection(TransceiverDirection.SendRecv);
            } catch (_) {}
          }
          if (isVideo && !isVideoCall) {
            try {
              await t.stop();
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('Error configuring transceivers: $e');
      }

      // Handle remote stream
      _peerConnection!.onAddStream = (stream) {
        _remoteStream = stream;
        debugPrint(
            'Remote stream received with ${stream.getAudioTracks().length} audio tracks');
        for (final audioTrack in stream.getAudioTracks()) {
          audioTrack.enabled = true;
        }
        state = state.copyWith(status: state.status);
      };

      // Unified-plan track handler
      _peerConnection!.onTrack = (RTCTrackEvent e) {
        if (e.streams.isNotEmpty) {
          final stream = e.streams.first;
          _remoteStream = stream;
          debugPrint(
              'onTrack: kind=${e.track.kind}, audioTracks=${stream.getAudioTracks().length}');
          for (final audioTrack in stream.getAudioTracks()) {
            audioTrack.enabled = true;
          }
          state = state.copyWith(status: state.status);
        }
      };

      // Handle ICE candidates
      _peerConnection!.onIceCandidate = (candidate) {
        try {
          final cand = candidate.candidate ?? '';
          if (cand.isNotEmpty) {
            if (cand.contains(' typ relay')) {
              debugPrint('📨 Local ICE candidate (TURN relay)');
            } else if (cand.contains(' typ srflx')) {
              debugPrint('📨 Local ICE candidate (STUN srflx)');
            } else if (cand.contains(' typ host')) {
              debugPrint('📨 Local ICE candidate (HOST)');
            } else {
              debugPrint('📨 Local ICE candidate: ${candidate.candidate}');
            }
          } else {
            debugPrint('📨 Local ICE candidate gathered: <empty/complete>');
          }
        } catch (_) {}
        _sendIceCandidate(candidate);
      };

      // Additional ICE/signaling diagnostics
      _peerConnection!.onIceGatheringState = (RTCIceGatheringState s) {
        debugPrint('🧩 ICE gathering state: $s');
      };
      _peerConnection!.onSignalingState = (RTCSignalingState s) {
        debugPrint('📶 Signaling state: $s');
      };

      // Handle connection state changes
      _peerConnection!.onConnectionState =
          (RTCPeerConnectionState connectionState) {
        debugPrint('🔗 Connection state changed: $connectionState');
        switch (connectionState) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            debugPrint('✅ Call connected successfully');
            _cancelDisconnectEnd();
            state = state.copyWith(status: CallStatus.connected);
            _startDurationTimer();
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            debugPrint('❌ Call connection failed');
            _scheduleDisconnectEnd(CallStatus.error);
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            debugPrint('🔌 Call disconnected');
            _scheduleDisconnectEnd(CallStatus.ended);
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
            debugPrint('🔄 Call connecting...');
            _cancelDisconnectEnd();
            break;
          default:
            debugPrint('🟡 Connection state: $connectionState');
            break;
        }
      };

      // Handle ICE connection state changes
      _peerConnection!.onIceConnectionState = (RTCIceConnectionState iceState) {
        debugPrint('🧊 ICE connection state: $iceState');
        switch (iceState) {
          case RTCIceConnectionState.RTCIceConnectionStateConnected:
          case RTCIceConnectionState.RTCIceConnectionStateCompleted:
            debugPrint('✅ ICE connection established - audio should work now');
            if (state.status != CallStatus.connected) {
              state = state.copyWith(status: CallStatus.connected);
              _startDurationTimer();
            }
            _cancelDisconnectEnd();
            break;
          case RTCIceConnectionState.RTCIceConnectionStateFailed:
            debugPrint('❌ ICE connection failed - no audio possible');
            // Try a quick recovery: toggle relay-only once during failure
            try {
              VoipConfigService.instance.setForceRelayOnly(true);
              debugPrint('🔁 Switching to relay-only to recover ICE');
            } catch (_) {}
            _scheduleDisconnectEnd(CallStatus.error);
            break;
          case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
            debugPrint('🔌 ICE connection lost');
            _scheduleDisconnectEnd(CallStatus.ended);
            break;
          case RTCIceConnectionState.RTCIceConnectionStateChecking:
            debugPrint('🔍 ICE checking connectivity...');
            break;
          case RTCIceConnectionState.RTCIceConnectionStateNew:
            debugPrint('🆕 ICE connection new');
            break;
          default:
            debugPrint('🟡 ICE state: $iceState');
            break;
        }
      };

      state = state.copyWith(isVideoEnabled: isVideoCall);

      // Set default audio configuration
      try {
        await Helper.setSpeakerphoneOn(state.isSpeakerOn);
        debugPrint('Audio output configured: speaker=${state.isSpeakerOn}');
      } catch (e) {
        debugPrint('Warning: Could not configure audio output: $e');
      }
    } catch (e) {
      throw Exception('Failed to initialize WebRTC: $e');
    }
  }

  Future<void> _sendIceCandidate(RTCIceCandidate candidate) async {
    try {
      final client = _matrix.client;
      final room = client.getRoomById(state.roomId!);

      if (room != null && state.callId != null) {
        await room.sendEvent({
          'call_id': state.callId,
          'version': 1,
          'candidates': [
            {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            }
          ],
        }, type: EventTypes.CallCandidates);
      }
    } catch (e) {
      print('Failed to send ICE candidate: $e');
    }
  }

  void _startDurationTimer() {
    _callStartTime = DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_callStartTime != null) {
        final duration = DateTime.now().difference(_callStartTime!);
        state = state.copyWith(duration: duration);
      }
    });
  }

  Future<void> _endCall(CallStatus status) async {
    _cancelDisconnectEnd();
    _durationTimer?.cancel();
    _durationTimer = null;
    _callStartTime = null;

    // Close WebRTC resources
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    await _peerConnection?.close();

    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;

    await _calls.endCall(state.roomId ?? '');

    state = state.copyWith(status: status);

    // Clear state after a delay
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        state = const AppCallState();
      }
    });
  }

  void _scheduleDisconnectEnd(CallStatus status) {
    // If already scheduled, keep existing timer
    if (_disconnectGraceTimer != null) return;
    debugPrint(
        '⏳ Scheduling call end in ${_disconnectGraceSeconds}s with status: $status');
    _disconnectGraceTimer =
        Timer(Duration(seconds: _disconnectGraceSeconds), () {
      _disconnectGraceTimer = null;
      // Only end if we haven't reconnected meanwhile
      if (mounted &&
          (state.status == CallStatus.connected ||
              state.status == CallStatus.ringing ||
              state.status == CallStatus.connecting)) {
        // If state shows we recovered, skip ending
        debugPrint('✅ Connection recovered, skipping scheduled end');
        return;
      }
      _endCall(status);
    });
  }

  void _cancelDisconnectEnd() {
    if (_disconnectGraceTimer != null) {
      debugPrint('🛑 Canceling scheduled call end');
      _disconnectGraceTimer?.cancel();
      _disconnectGraceTimer = null;
    }
  }

  Future<bool> _checkCallPermissions(bool isVideoCall) async {
    try {
      return await CallService.checkCallPermissions(isVideoCall);
    } catch (e) {
      debugPrint('Error checking call permissions: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _localStream?.dispose();
    _remoteStream?.dispose();
    _peerConnection?.close();
    super.dispose();
  }

// Getters for WebRTC streams
  MediaStream? get localStream => _localStream;

  MediaStream? get remoteStream => _remoteStream;
}

final callProvider = StateNotifierProvider<CallNotifier, AppCallState>((ref) {
  return CallNotifier();
});
