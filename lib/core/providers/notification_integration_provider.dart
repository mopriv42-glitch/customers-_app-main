import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_4t_app/core/providers/notification_provider.dart';
import 'package:private_4t_app/core/providers/call_provider.dart';
import 'package:private_4t_app/core/providers/deep_link_provider.dart';
import 'package:private_4t_app/core/providers/permissions_provider.dart';
import 'package:private_4t_app/core/services/firebase_messaging_service.dart';
import 'package:private_4t_app/core/services/notification_service.dart';

/// Integration provider that combines all notification-related providers
class NotificationIntegrationProvider
    extends StateNotifier<NotificationIntegrationState> {
  NotificationIntegrationProvider(this.ref)
      : super(NotificationIntegrationState());

  final Ref ref;

  /// Initialize all notification services
  Future<void> initializeAllServices() async {
    try {
      state = state.copyWith(isInitializing: true);

      // Initialize notification service
      await NotificationService.initializeNotifications();
      await FirebaseMessagingService.init();

      // Request permissions
      await ref.read(permissionsProvider.notifier).requestAllPermissions();

      state = state.copyWith(
        isInitializing: false,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        error: e.toString(),
      );
    }
  }

  /// Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, String?>? payload,
  }) async {
    try {
      await ref.read(notificationProvider.notifier).showLocalNotification(
            title: title,
            body: body,
            payload: payload,
          );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }


  /// Decline call
  Future<void> declineCall() async {
    try {
      await ref.read(callProvider.notifier).declineCall();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Handle deep link
  Future<void> handleDeepLink(Map<String, dynamic> payload) async {
    try {
      await ref.read(deepLinkProvider.notifier).handleDeepLink(payload);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Request all permissions
  Future<void> requestAllPermissions() async {
    try {
      await ref.read(permissionsProvider.notifier).requestAllPermissions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Request specific permission
  Future<void> requestPermission(dynamic permission) async {
    try {
      await ref
          .read(permissionsProvider.notifier)
          .requestPermission(permission);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await ref.read(notificationProvider.notifier).cancelAllNotifications();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Get notification state
  NotificationState get notificationState => ref.read(notificationProvider);

  /// Get deep link state
  DeepLinkState get deepLinkState => ref.read(deepLinkProvider);

  /// Get permissions state
  PermissionsState get permissionsState => ref.read(permissionsProvider);
}

class NotificationIntegrationState {
  final bool isInitializing;
  final bool isInitialized;
  final String? error;

  NotificationIntegrationState({
    this.isInitializing = false,
    this.isInitialized = false,
    this.error,
  });

  NotificationIntegrationState copyWith({
    bool? isInitializing,
    bool? isInitialized,
    String? error,
  }) {
    return NotificationIntegrationState(
      isInitializing: isInitializing ?? this.isInitializing,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
    );
  }
}

final notificationIntegrationProvider = StateNotifierProvider<
    NotificationIntegrationProvider, NotificationIntegrationState>(
  (ref) => NotificationIntegrationProvider(ref),
);
