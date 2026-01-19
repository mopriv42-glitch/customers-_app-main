enum CallStatus {
  connecting,
  ringing,
  connected,
  ended,
  missed,
  declined,
  error,
}

class AppCallState {
  final String? callId;
  final String? roomId;
  final String? calleeId;
  final String? callerName;
  final CallStatus status;
  final bool isVideoCall;
  final bool isIncoming;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isVideoEnabled;
  final Duration? duration;
  final String? error;
  final bool isLoading;

  const AppCallState({
    this.callId,
    this.roomId,
    this.calleeId,
    this.callerName,
    this.status = CallStatus.connecting,
    this.isVideoCall = false,
    this.isIncoming = false,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isVideoEnabled = false,
    this.duration,
    this.error,
    this.isLoading = false,
  });

  AppCallState copyWith({
    String? callId,
    String? roomId,
    String? calleeId,
    String? callerName,
    CallStatus? status,
    bool? isVideoCall,
    bool? isIncoming,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isVideoEnabled,
    Duration? duration,
    String? error,
    bool? isLoading,
  }) {
    return AppCallState(
      callId: callId ?? this.callId,
      roomId: roomId ?? this.roomId,
      calleeId: calleeId ?? this.calleeId,
      callerName: callerName ?? this.callerName,
      status: status ?? this.status,
      isVideoCall: isVideoCall ?? this.isVideoCall,
      isIncoming: isIncoming ?? this.isIncoming,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      duration: duration ?? this.duration,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() {
    return 'CallState(callId: $callId, status: $status, isVideoCall: $isVideoCall, isIncoming: $isIncoming, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppCallState &&
        other.callId == callId &&
        other.roomId == roomId &&
        other.calleeId == calleeId &&
        other.callerName == callerName &&
        other.status == status &&
        other.isVideoCall == isVideoCall &&
        other.isIncoming == isIncoming &&
        other.isMuted == isMuted &&
        other.isSpeakerOn == isSpeakerOn &&
        other.isVideoEnabled == isVideoEnabled &&
        other.duration == duration &&
        other.error == error &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return callId.hashCode ^
    roomId.hashCode ^
    calleeId.hashCode ^
    callerName.hashCode ^
    status.hashCode ^
    isVideoCall.hashCode ^
    isIncoming.hashCode ^
    isMuted.hashCode ^
    isSpeakerOn.hashCode ^
    isVideoEnabled.hashCode ^
    duration.hashCode ^
    error.hashCode ^
    isLoading.hashCode;
  }
}
