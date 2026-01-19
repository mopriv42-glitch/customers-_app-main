import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/core/models/call_state.dart';
import 'package:private_4t_app/core/providers/call_provider.dart';
import 'package:private_4t_app/features/contact/screens/weidgets/call_avatar.dart';
import 'package:private_4t_app/features/contact/screens/weidgets/call_controls.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String roomId;

  const CallScreen({super.key, required this.roomId});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'Callscreen';
  
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    debugPrint('Video renderers initialized');
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    final callNotifier = ref.watch(callProvider.notifier);

    // Update video renderers when streams change
    ref.listen<AppCallState>(callProvider, (previous, next) {
      final localStream = callNotifier.localStream;
      final remoteStream = callNotifier.remoteStream;

      if (localStream != null && _localRenderer.srcObject != localStream) {
        _localRenderer.srcObject = localStream;
        debugPrint('Local stream attached to renderer');
      }

      if (remoteStream != null && _remoteRenderer.srcObject != remoteStream) {
        _remoteRenderer.srcObject = remoteStream;
        debugPrint(
            'Remote stream attached to renderer - audio should play automatically');
      }
    });

    // Handle call end - navigate back
    if (callState.status == CallStatus.ended ||
        callState.status == CallStatus.declined ||
        callState.status == CallStatus.error) {
      // context.pop();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background/Remote video
            if (callState.isVideoCall &&
                callState.status == CallStatus.connected)
              _buildVideoView()
            else
              _buildAudioView(),

            // Top info bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildTopBar(callState),
            ),

            // Local video (for video calls)
            if (callState.isVideoCall &&
                callState.status == CallStatus.connected)
              Positioned(
                top: 100,
                right: 16,
                child: _buildLocalVideo(),
              ),

            // Call controls
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: CallControls(
                callState: callState,
                onAnswer: () => ref.read(callProvider.notifier).answerCall({}),
                onDecline: () => ref.read(callProvider.notifier).declineCall(),
                onHangup: () => ref.read(callProvider.notifier).hangupCall(),
                onToggleMute: () =>
                    ref.read(callProvider.notifier).toggleMute(),
                onToggleSpeaker: () =>
                    ref.read(callProvider.notifier).toggleSpeaker(),
                onToggleVideo: () =>
                    ref.read(callProvider.notifier).toggleVideo(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoView() {
    return SizedBox.expand(
      child: RTCVideoView(_remoteRenderer, mirror: false),
    );
  }

  Widget _buildAudioView() {
    final callState = ref.watch(callProvider);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E1E1E),
            Color(0xFF0D1117),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CallAvatar(
            callerName: callState.callerName ?? 'Private 4T User',
            size: 120,
          ),
          const SizedBox(height: 32),
          Text(
            callState.callerName ?? 'Private 4T User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusText(callState.status),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          if (callState.duration != null) ...[
            const SizedBox(height: 8),
            Text(
              _formatDuration(callState.duration!),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalVideo() {
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: RTCVideoView(_localRenderer, mirror: true),
      ),
    );
  }

  Widget _buildTopBar(AppCallState callState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            callState.isVideoCall ? Icons.videocam : Icons.call,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            callState.isVideoCall ? 'Video Call' : 'Voice Call',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (callState.duration != null)
            Text(
              _formatDuration(callState.duration!),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusText(CallStatus status) {
    switch (status) {
      case CallStatus.connecting:
        return 'Connecting...';
      case CallStatus.ringing:
        return 'Ringing...';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.ended:
        return 'Call ended';
      case CallStatus.missed:
        return 'Missed call';
      case CallStatus.declined:
        return 'Call declined';
      case CallStatus.error:
        return 'Call failed';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
