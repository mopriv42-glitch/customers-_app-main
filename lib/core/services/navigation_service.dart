import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/core/services/matrix_call_service.dart';
// Removed direct screen imports; using GoRouter paths instead

/// Notification to communicate with MainNavigationScreen for tab changes
class MainNavigationNotification extends Notification {
  final int targetIndex;

  const MainNavigationNotification({required this.targetIndex});
}

class ClipsNavigationNotification extends Notification {
  final bool isActive;

  const ClipsNavigationNotification({required this.isActive});
}
@pragma('vm:entry-point')
class NavigationService {
  @pragma('vm:entry-point')
  // امسح الـ static GlobalKey و استخدم الـ router one
  @pragma('vm:entry-point')
  static GlobalKey<NavigatorState>? _navigatorKey;

  @pragma('vm:entry-point')
  static GlobalKey<NavigatorState> get rootNavigatorKey {
    // هتتحط من الـ router
    return _navigatorKey ?? GlobalKey<NavigatorState>();
  }

  @pragma('vm:entry-point')
  static void setRouter(GoRouter router) {
    // احصل على الـ navigatorKey من الـ router
    _navigatorKey = router.routerDelegate.navigatorKey;
  }

  @pragma('vm:entry-point')
  static void resetKeys() {
    _navigatorKey = GlobalKey<NavigatorState>();
    router = null;
    hideCallOverlay();
  }
  static OverlayEntry? _callOverlayEntry;
  static Timer? _callOverlayTimer;
  static Offset? _callOverlayPos;
  static const double _callOverlayWidth = 230;
  static const double _callOverlayHeight = 58;

  static GoRouter? router;

  static void initRouter(GoRouter goRouter) {
    router = goRouter;
  }

  static void navigateToRoomTimeline(BuildContext context, String roomId) {
    final r = router ?? GoRouter.of(context);

    r.push('/room/$roomId');
  }

  static void navigateToCall(BuildContext context, String roomId) {
    final r = router ?? GoRouter.of(context);
    r.push('/call/$roomId');
  }

  static void navigateToProfile(BuildContext context) {
    final r = router ?? GoRouter.of(context);
    r.push('/profile');
  }

  static void navigateToNotifications(BuildContext context) {
    final r = router ?? GoRouter.of(context);
    r.push('/notifications');
  }

  static void navigateToMenu(BuildContext context) {
    final r = router ?? GoRouter.of(context);
    r.push('/menu');
  }

  static void navigateToCart(BuildContext context) {
    final r = router ?? GoRouter.of(context);
    r.push('/cart');
  }

  /// Smart home navigation:
  /// - If user is on main navigation screen (/home), focus on home tab
  /// - If user is on any other screen, navigate to main navigation screen
  static void navigateToHome(BuildContext context) {
    final r = router ?? GoRouter.of(context);
    final currentLocation =
        r.routerDelegate.currentConfiguration.uri.toString();

    if (currentLocation == '/home') {
      // User is already on main navigation screen, focus on home tab
      _focusHomeTab(context);
    } else {
      // Navigate to main navigation screen (home tab will be selected by default)
      r.go('/home');
    }
  }

  /// Focuses on the home tab in the main navigation screen
  static void _focusHomeTab(BuildContext context) {
    // We'll use a custom notification to communicate with MainNavigationScreen
    const MainNavigationNotification(targetIndex: 0).dispatch(context);
  }

  // Mini call overlay over app UI
  static void showCallOverlay(BuildContext context, String roomId) {
    hideCallOverlay();
    final media = MediaQuery.of(context);
    _callOverlayPos ??= Offset(
      media.size.width - _callOverlayWidth - 12,
      media.padding.top + 12,
    );
    final entry = OverlayEntry(
      builder: (ctx) {
        String elapsedText = '';
        bool isMuted = false;
        try {
          final calls = MatrixCallService.instance;
          final session = calls?.getSession(roomId);
          if (session != null) {
            // final d = session.elapsed;
            // final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
            // final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
            // elapsedText = '$mm:$ss';
            // isMuted = session.muted;
          }
        } catch (_) {}
        final size = MediaQuery.of(ctx).size;
        double left = _callOverlayPos!.dx;
        double top = _callOverlayPos!.dy;
        left = left.clamp(0.0, size.width - _callOverlayWidth);
        top = top.clamp(media.padding.top, size.height - _callOverlayHeight);
        return Positioned(
          left: left,
          top: top,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12.r),
            clipBehavior: Clip.antiAlias,
            child: GestureDetector(
              onPanUpdate: (details) {
                final current = _callOverlayPos ?? Offset(left, top);
                _callOverlayPos = Offset(
                  current.dx + details.delta.dx,
                  current.dy + details.delta.dy,
                );
                _callOverlayEntry?.markNeedsBuild();
              },
              child: InkWell(
                onTap: () {
                  if (rootNavigatorKey.currentContext != null) {
                    final goRouter =
                        GoRouter.of(rootNavigatorKey.currentContext!);
                    final loc = goRouter.state.uri.toString();
                    final match = RegExp(r"^/call/(.+)").firstMatch(loc);
                    if (match == null) {
                      navigateToCall(rootNavigatorKey.currentContext!, roomId);
                    }
                  } else {
                    navigateToCall(ctx, roomId);
                  }
                },
                child: SizedBox(
                  width: _callOverlayWidth,
                  height: _callOverlayHeight,
                  child: Material(
                    color: Colors.black87,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.call, color: Colors.white, size: 16.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              elapsedText.isEmpty
                                  ? 'مكالمة جارية'
                                  : 'مكالمة $elapsedText',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12.sp),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          InkWell(
                            onTap: () async {
                              try {
                                final calls = MatrixCallService.instance;
                                final s = calls?.getSession(roomId);
                                // await s?.toggleMute();
                                _callOverlayEntry?.markNeedsBuild();
                              } catch (_) {}
                            },
                            child: Icon(
                              isMuted ? Icons.mic_off : Icons.mic,
                              color: Colors.white,
                              size: 30.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          InkWell(
                            onTap: () async {
                              try {
                                final calls = MatrixCallService.instance;
                                final s = calls?.getSession(roomId);
                                // await s?.hangup();
                              } catch (_) {}
                              cleanupAllOverlays();
                            },
                            child: Icon(Icons.call_end,
                                color: Colors.redAccent, size: 30.sp),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    _callOverlayEntry = entry;
    // rootNavigatorKey.currentState?.overlay?.insert(entry);
    // _callOverlayTimer?.cancel();
    // _callOverlayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
    //   _callOverlayEntry?.markNeedsBuild();
    // });

    // Also request system overlay (Android) to show over other apps
    _ensureSystemOverlay(roomId);
  }

  @pragma('vm:entry-point')
  static void hideCallOverlay() {
    try {
      // _callOverlayEntry?.remove();
      // _callOverlayEntry = null;
      // _callOverlayTimer?.cancel();
      // _callOverlayTimer = null;
      _closeSystemOverlay();

      // Reset position for next call
      // _callOverlayPos = null;
    } catch (e) {
      debugPrint('Error hiding call overlay: $e');
    }
  }

  static bool _permissionRequested = false;

  static Future<void> _ensureSystemOverlay(String roomId) async {
    try {
      final canDraw = await FlutterOverlayWindow.isPermissionGranted();
      if (!canDraw && !_permissionRequested) {
        _permissionRequested = true;
        await FlutterOverlayWindow.requestPermission();
        // Reset flag after a delay to allow future requests if needed
        Future.delayed(const Duration(minutes: 5), () {
          _permissionRequested = false;
        });
      }

      if (await FlutterOverlayWindow.isActive()) {
        return;
      }

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: 'Call',
        overlayContent: 'مكالمة جارية',
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.centerRight,
        height: 90,
        width: 220,
        visibility: NotificationVisibility.visibilityPublic,
      );
    } catch (e) {
      debugPrint('Error ensuring system overlay: $e');
    }
  }

  static Future<void> _closeSystemOverlay() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      debugPrint('Error closing system overlay: $e');
    }
  }

  // Public helper to ensure system overlay is shown for current active call
  static Future<void> showSystemCallOverlayForActiveCall() async {
    try {
      final calls = MatrixCallService.instance;
      if (calls == null) return;
      // Find any active session
      // We don't have a direct list; try to get from a known route context
      // Prefer last opened call via overlay tap; otherwise, skip
      // As a fallback, we can attempt to use current route params if available
      // For now, no direct room id discovery; rely on instance sessions map access via a helper in future
    } catch (_) {}
  }

  // Public: ensure system overlay is visible (Android), safe to call from background
  static Future<void> ensureSystemOverlay(String roomId) async {
    await _ensureSystemOverlay(roomId);
  }

  // Clean up all overlays when app is paused or call ends
  static void cleanupAllOverlays() {
    hideCallOverlay();
    _closeSystemOverlay();
  }

  // Check if any call overlay is currently active
  static bool get hasActiveOverlay => _callOverlayEntry != null;
}


