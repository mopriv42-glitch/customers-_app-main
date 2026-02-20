import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/notification_model.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:private_4t_app/core/services/notification_service.dart';

class NotificationProvider extends StateNotifier<NotificationState> {
  NotificationProvider() : super(NotificationState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize notification service
      await NotificationService.initializeNotifications();

      state = state.copyWith(isInitialized: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, String?>? payload,
  }) async {
    try {
      await NotificationService.showLocalNotification(
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await NotificationService.cancelAllNotifications();
      state = state.copyWith(notificationCount: 0);
    } catch (e) {
      debugPrint('Error canceling notifications: $e');
    }
  }

  /// Fetch notifications from backend
  Future<void> fetchNotifications({int page = 1, int perPage = 20}) async {
    try {
      state = state.copyWith(isLoading: true);

      final userToken = await CommonComponents.getSavedData(ApiKeys.userToken);
      if (userToken == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User token not found',
        );
        return;
      }

      Map<String, dynamic>? response = await ApiRequests.getApiRequests(
        context: NavigationService.rootNavigatorKey.currentContext!,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'notifications/history?page=$page&per_page=$perPage',
        headers: {
          'Authorization': 'Bearer $userToken',
        },
      );

      debugPrint('response: ${response.toString()}');
      debugPrint('response type: ${response.runtimeType}');
      debugPrint('response data: ${response?['data']}');
      debugPrint('response data type: ${response?['data']?.runtimeType}');

      if (response != null && response['data'] != null) {
        final List<dynamic> notificationsData = response['data']['data'];
        debugPrint('notificationsData length: ${notificationsData.length}');
        debugPrint('notificationsData: ${notificationsData.toString()}');

        final notifications = notificationsData
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        debugPrint('parsed notifications length: ${notifications.length}');
        debugPrint('parsed notifications: ${notifications.toString()}');

        state = state.copyWith(
          notifications: notifications,
          isLoading: false,
          currentPage: page,
          hasMore: response['data']['next_page_url'] != null,
        );

        debugPrint('State updated with ${notifications.length} notifications');
      } else {
        debugPrint('Response is null or data is null');
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch notifications',
        );
      }
    } catch (e, stackTrace) {
      debugPrintStack(
          stackTrace: stackTrace, label: 'Error fetching notifications: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final userToken = await CommonComponents.getSavedData(ApiKeys.userToken);
      if (userToken == null) return;

      Map<String, dynamic>? response = await ApiRequests.postApiRequest(
        context: NavigationService.rootNavigatorKey.currentContext!,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'notifications/mark-read/$notificationId',
        headers: {
          'Authorization': "Bearer $userToken",
        },
        body: {},
        showLoadingWidget: true,
      );

      debugPrint("Mark Read response: $response");

      if (response != null && response['success'] == true) {
        // Update local state
        final updatedNotifications = state.notifications.map((notification) {
          if (notification.id.toString() == notificationId) {
            return notification.copyWith(isRead: true);
          }
          return notification;
        }).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
        );
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      final userToken = await CommonComponents.getSavedData(ApiKeys.userToken);
      if (userToken == null) return;

      final response = await ApiRequests.putRequests(
        context: NavigationService.rootNavigatorKey.currentContext!,
        apiUrl: 'notifications/mark-all-read',
        body: {},
        showLoadingWidget: false,
      );

      if (response != null) {
        final updatedNotifications = state.notifications.map((notification) {
          return notification.copyWith(isRead: true);
        }).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
        );
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final userToken = await CommonComponents.getSavedData(ApiKeys.userToken);
      if (userToken == null) return;

      final response = await ApiRequests.deleteRequest(
        context: NavigationService.rootNavigatorKey.currentContext!,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'notifications/$notificationId',
        headers: {
          'Authorization': 'Bearer $userToken',
          'Content-Type': 'application/json',
        },
        showLoadingWidget: false,
      );

      if (response != null) {
        final updatedNotifications = state.notifications
            .where((notification) => notification.id != notificationId)
            .toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          notificationCount: updatedNotifications.length,
        );
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Handle Matrix message notification
  Future<void> handleMatrixMessage({
    required String roomId,
    required String senderName,
    required String message,
    String? senderAvatar,
  }) async {
    try {
      // Create notification for Matrix message
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch,
        title: 'رسالة من $senderName',
        message: message,
        type: NotificationType.message,
        isRead: false,
        metadata: {'type': 'matrix_message', 'room_id': roomId},
      );

      // Add to notifications list
      final updatedNotifications = [notification, ...state.notifications];

      state = state.copyWith(
        notifications: updatedNotifications,
        notificationCount: updatedNotifications.length,
        unreadCount: state.unreadCount + 1,
        lastNotification: notification.toJson(),
      );

      // Show local notification
      await showLocalNotification(
        title: notification.title,
        body: notification.message,
        payload: {
          'type': 'matrix_message',
          'room_id': roomId,
          'sender_name': senderName,
        },
      );
    } catch (e) {
      debugPrint('Error handling Matrix message: $e');
    }
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    await fetchNotifications(page: 1);
  }

  /// Load more notifications
  Future<void> loadMoreNotifications() async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.currentPage + 1;
    await fetchNotifications(page: nextPage);
  }


  /// دالة لإضافة إشعار جديد محليًا إلى القائمة
  /// هذه الدالة ستُستدعى من onNotificationCreated
  Future<void> addLocalNotification(NotificationModel newNotification) async {
    try {
      debugPrint('Adding local notification to state: ${newNotification.title}');

      // تحديث قائمة الإشعارات
      final updatedNotifications = [newNotification, ...state.notifications];

      state = state.copyWith(
        notifications: updatedNotifications,
        notificationCount: updatedNotifications.length,
        unreadCount: state.unreadCount + 1,
        // تحديث lastNotification
        lastNotification: newNotification.toJson(),
      );

      debugPrint('Notification state updated successfully.');
    } catch (e, s) {
      debugPrint('Error in addLocalNotification: $e');
      debugPrintStack(stackTrace: s);
    }
  }
}

class NotificationState {
  final bool isInitialized;
  final bool isLoading;
  final String? fcmToken;
  final Map<String, dynamic>? lastNotification;
  final int notificationCount;
  final int unreadCount;
  final List<NotificationModel> notifications;
  final int currentPage;
  final bool hasMore;
  final String? error;

  NotificationState({
    this.isInitialized = false,
    this.isLoading = false,
    this.fcmToken,
    this.lastNotification,
    this.notificationCount = 0,
    this.unreadCount = 0,
    this.notifications = const [],
    this.currentPage = 1,
    this.hasMore = false,
    this.error,
  });

  NotificationState copyWith({
    bool? isInitialized,
    bool? isLoading,
    String? fcmToken,
    Map<String, dynamic>? lastNotification,
    int? notificationCount,
    int? unreadCount,
    List<NotificationModel>? notifications,
    int? currentPage,
    bool? hasMore,
    String? error,
  }) {
    return NotificationState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      fcmToken: fcmToken ?? this.fcmToken,
      lastNotification: lastNotification ?? this.lastNotification,
      notificationCount: notificationCount ?? this.notificationCount,
      unreadCount: unreadCount ?? this.unreadCount,
      notifications: notifications ?? this.notifications,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }

}

final notificationProvider =
    StateNotifierProvider<NotificationProvider, NotificationState>(
  (ref) => NotificationProvider(),
);
