import 'package:flutter/material.dart';
import 'package:private_4t_app/core/models/call_state.dart';

class CallControls extends StatelessWidget {
  final AppCallState callState;
  final VoidCallback onAnswer;
  final VoidCallback onDecline;
  final VoidCallback onHangup;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleVideo;

  const CallControls({
    super.key,
    required this.callState,
    required this.onAnswer,
    required this.onDecline,
    required this.onHangup,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onToggleVideo,
  });

  @override
  Widget build(BuildContext context) {
    if (callState.isIncoming && callState.status == CallStatus.ringing) {
      return _buildIncomingCallControls();
    } else {
      return _buildActiveCallControls();
    }
  }

  Widget _buildIncomingCallControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Decline button
          _CallButton(
            icon: Icons.call_end,
            backgroundColor: Colors.red,
            onPressed: onDecline,
            size: 64,
          ),
          // Answer button
          _CallButton(
            icon: Icons.call,
            backgroundColor: Colors.green,
            onPressed: onAnswer,
            size: 64,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCallControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row - toggle controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Mute button
              _CallButton(
                icon: callState.isMuted ? Icons.mic_off : Icons.mic,
                backgroundColor:
                callState.isMuted ? Colors.red : Colors.grey[800]!,
                onPressed: onToggleMute,
              ),

              // Speaker button
              _CallButton(
                icon:
                callState.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                backgroundColor:
                callState.isSpeakerOn ? Colors.blue : Colors.grey[800]!,
                onPressed: onToggleSpeaker,
              ),

              // Video button (only for video calls)
              if (callState.isVideoCall)
                _CallButton(
                  icon: callState.isVideoEnabled
                      ? Icons.videocam
                      : Icons.videocam_off,
                  backgroundColor: callState.isVideoEnabled
                      ? Colors.blue
                      : Colors.grey[800]!,
                  onPressed: onToggleVideo,
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Bottom row - end call
          _CallButton(
            icon: Icons.call_end,
            backgroundColor: Colors.red,
            onPressed: onHangup,
            size: 64,
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final double size;

  const _CallButton({
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.4,
          ),
        ),
      ),
    );
  }
}
