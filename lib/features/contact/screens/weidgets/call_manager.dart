import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/call_state.dart';
import 'package:private_4t_app/core/providers/authentication_providers/login_provider.dart';
import 'package:private_4t_app/core/providers/call_provider.dart';
import 'package:private_4t_app/core/providers/matrix_chat_provider.dart';
import 'package:private_4t_app/core/services/call_service.dart';
import 'package:private_4t_app/core/services/navigation_queue.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';

import '../../../../core/services/notification_service.dart'
    show NotificationService;

/// Widget manages call state and handles navigation.
class CallManager extends ConsumerStatefulWidget {
  const CallManager({super.key});

  @override
  ConsumerState<CallManager> createState() => _CallManagerState();
}

class _CallManagerState extends ConsumerState<CallManager> {
  @override
  void initState() {
    NotificationService.handleInitialNotifications().then((_) {
      debugPrint("Initial notification handling completed");
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final matrix = ref.watch(ApiProviders.matrixChatProvider);
    final loginProvider = ref.read(ApiProviders.loginProvider);
    final loggedUser = loginProvider.loggedUser;

    // Ensure user and Matrix client are initialized
    _initMatrixIfNeeded(matrix, loginProvider, loggedUser);

    if (matrix.isInitialized) {
      _listenForCallEvents();
      _handlePendingNavigation();
    }

    return const Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox.shrink(),
    );
  }

  // -------------------------------
  // Private helpers
  // -------------------------------

  void _initMatrixIfNeeded(
      MatrixChatProvider matrix,LoginProvider loginProvider, loggedUser) {
    if (loggedUser == null) {
      loginProvider.getLoggedUser().then((_) {
        if (!matrix.isInitialized) {
          matrix.init().then((_) async {
            if (!matrix.isLoggedIn && loggedUser != null) {
              await _tryAutoProvision(matrix, loggedUser);
            }
          });
        }
      });
    }
  }

  Future<void> _tryAutoProvision(
      MatrixChatProvider matrix, dynamic loggedUser) async {
    try {
      if (matrix.canAutoProvision(loggedUser)) {
        final result = await matrix.autoProvisionUser(appUser: loggedUser);
        debugPrint('Auto-provisioning: ${result.success} | ${result.message}');
      } else {
        debugPrint('User cannot be auto-provisioned (missing phone number)');
      }
    } catch (e, s) {
      debugPrintStack(
          label: 'Error during auto-provisioning: $e', stackTrace: s);
    }
  }

  void _listenForCallEvents() {
    ref.listen<AppCallState>(callProvider, (previous, next) {
      if (next.isIncoming && next.status == CallStatus.ringing) {
        _showIncomingCallDialog(next);
      } else if (next.status == CallStatus.connected &&
          previous?.status != CallStatus.connected) {
        _navigateToCallPage(next.callId!);
      }
    });
  }

  void _showIncomingCallDialog(AppCallState callState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => IncomingCallDialog(
        callerName: callState.callerName ?? 'Unknown',
        isVideoCall: callState.isVideoCall,
        onAnswer: () {
          Navigator.of(context).pop();
          ref.read(callProvider.notifier).answerCall({});
        },
        onDecline: () {
          Navigator.of(context).pop();
          ref.read(callProvider.notifier).declineCall();
        },
      ),
    );
  }

  void _navigateToCallPage(String callId) {
    final isIncoming = ref.read(callProvider).isIncoming;
    NavigationService.rootNavigatorKey.currentContext
        ?.push('/call/$callId?incoming=$isIncoming');
  }

  Future<void> _handlePendingNavigation() async {
    try {
      if (!GoRouter.of(
              NavigationService.rootNavigatorKey.currentContext ?? context)
          .state
          .fullPath!
          .contains('splash')) {
        return;
      }
    } catch (_) {
      return;
    }
    final pendingNav =
        await CommonComponents.getSavedData(NavigationQueue.shKey);
    final isCallNavigation =
        pendingNav is String && pendingNav.contains('/call/');

    debugPrint(
        "Pending navigation detected: $pendingNav, isCall: $isCallNavigation");

    await NavigationQueue.setPendingCallNavigation(null);
    if (!mounted) return;

    if (isCallNavigation) {
      try {
        final pv = PendingNavigation.fromMap(jsonDecode(pendingNav));
        if (ref.read(ApiProviders.loginProvider).loggedUser != null) {
          debugPrint("Fast call navigation: ${pv.path}");
          NavigationService.navigateToHome(
              NavigationService.rootNavigatorKey.currentContext ?? context);
          await Future.delayed(const Duration(milliseconds: 100));
          NavigationService.rootNavigatorKey.currentContext
              ?.push(pv.path, extra: pv.extra);
        } else {
          NavigationService.navigateToHome(
              NavigationService.rootNavigatorKey.currentContext ?? context);
          NavigationService.rootNavigatorKey.currentContext
              ?.push(pv.path, extra: pv.extra);
        }
      } catch (e) {
        debugPrint("Error parsing call navigation: $e");
        NavigationService.rootNavigatorKey.currentContext?.go('/welcome');
      }
    } else {
      NavigationService.rootNavigatorKey.currentContext?.go('/welcome');
    }
  }
}

// -------------------------------
// Incoming Call Dialog
// -------------------------------

class IncomingCallDialog extends StatelessWidget {
  final String callerName;
  final bool isVideoCall;
  final VoidCallback onAnswer;
  final VoidCallback onDecline;

  const IncomingCallDialog({
    super.key,
    required this.callerName,
    required this.isVideoCall,
    required this.onAnswer,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVideoCall ? Icons.videocam : Icons.call,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Incoming ${isVideoCall ? 'Video' : 'Voice'} Call',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              callerName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _circleButton(
          color: Colors.red,
          icon: Icons.call_end,
          onPressed: onDecline,
        ),
        _circleButton(
          color: Colors.green,
          icon: Icons.call,
          onPressed: onAnswer,
        ),
      ],
    );
  }

  Widget _circleButton({
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        iconSize: 32,
      ),
    );
  }
}

// -------------------------------
// Call Utilities
// -------------------------------

class CallUtils {
  static Future<void> startVoiceCall(WidgetRef ref, String roomId) async {
    await _startCall(ref, roomId, isVideo: false);
  }

  static Future<void> startVideoCall(WidgetRef ref, String roomId) async {
    await _startCall(ref, roomId, isVideo: true);
  }

  static Future<void> _startCall(
    WidgetRef ref,
    String roomId, {
    required bool isVideo,
  }) async {
    try {
      final hasPermission = await CallService.checkCallPermissions(isVideo);
      if (!hasPermission) {
        final granted = await CallService.requestCallPermissions(isVideo);
        if (!granted) {
          throw Exception(isVideo
              ? 'Camera and microphone permissions required for video calls'
              : 'Microphone permission required for voice calls');
        }
      }
      await ref.read(callProvider.notifier).startCall(roomId, isVideo);
    } catch (e) {
      debugPrint('Failed to start ${isVideo ? "video" : "voice"} call: $e');
      rethrow;
    }
  }

  static bool isCallSupported(Room room) {
    return room.isDirectChat && room.summary.mJoinedMemberCount == 2;
  }
}
