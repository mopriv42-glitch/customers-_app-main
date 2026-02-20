import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/notification_model.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'Notificationsscreen';
  
  String _selectedFilter = 'الكل';
  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'الكل',
    'أكاديمي',
    'النظام',
    'العروض',
    'الرسائل',
    'المكالمات',
  ];

  // Use real notifications from provider instead of dummy data
  List<NotificationData> get _notifications {
    final notificationState = ref.watch(ApiProviders.notificationProvider);
    debugPrint(
        'NotificationState: isLoading=${notificationState.isLoading}, error=${notificationState.error}, notifications.length=${notificationState.notifications.length}');

    return notificationState.notifications.map((notification) {
      debugPrint('Processing notification: ${notification.toString()}');
      return NotificationData(
        id: notification.id.toString(),
        title: notification.title,
        message: notification.message,
        type: _mapNotificationType(notification.type),
        isRead: notification.isRead,
        timestamp: notification.createdAt ?? DateTime.now(),
        icon: _getIconForType(_mapNotificationType(notification.type)),
      );
    }).toList();
  }

  // Map NotificationModel type to local NotificationType
  NotificationType _mapNotificationType(NotificationType modelType) {
    switch (modelType) {
      case NotificationType.academic:
        return NotificationType.academic;
      case NotificationType.system:
        return NotificationType.system;
      case NotificationType.offer:
        return NotificationType.offer;
      case NotificationType.message:
        return NotificationType.message;
      case NotificationType.call:
        return NotificationType.call;
      default:
        return NotificationType.system;
    }
  }

  // Get icon for notification type
  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.academic:
        return Icons.school;
      case NotificationType.system:
        return Icons.system_update;
      case NotificationType.offer:
        return Icons.local_offer;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.call:
        return Icons.call;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.booking:
        return Icons.book_online;
      case NotificationType.news:
        return Icons.newspaper;
      case NotificationType.promotion:
        return Icons.trending_up;
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch notifications when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ApiProviders.notificationProvider.notifier).fetchNotifications();
    });
  }

  List<NotificationData> get filteredNotifications {
    if (_selectedFilter == 'الكل') {
      return _notifications;
    }
    return _notifications.where((notification) {
      switch (_selectedFilter) {
        case 'أكاديمي':
          return notification.type == NotificationType.academic;
        case 'النظام':
          return notification.type == NotificationType.system;
        case 'العروض':
          return notification.type == NotificationType.offer;
        case 'الرسائل':
          return notification.type == NotificationType.message;
        case 'المكالمات':
          return notification.type == NotificationType.call;
        case 'التذكيرات':
          return notification.type == NotificationType.reminder;
        case 'المدفوعات':
          return notification.type == NotificationType.payment;
        case 'الحجوزات':
          return notification.type == NotificationType.booking;
        case 'الأخبار':
          return notification.type == NotificationType.news;
        case 'الترقيات':
          return notification.type == NotificationType.promotion;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the notification provider state
    final notificationState = ref.watch(ApiProviders.notificationProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'الإشعارات',
          showBackButton: true,
        ),
        body: Column(
          children: [
            _buildFilterTabs(),
            Expanded(
              child: _buildBody(notificationState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(dynamic notificationState) {
    if (notificationState.isLoading) {
      return _buildLoadingState();
    }

    if (notificationState.error != null) {
      return _buildErrorState(notificationState.error!);
    }

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }

    return _buildNotificationsList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(context.primary),
          ),
          SizedBox(height: 16.h),
          Text(
            'جاري تحميل الإشعارات...',
            style: TextStyle(
              fontSize: 16.sp,
              color: context.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80.sp,
            color: context.error,
          ),
          SizedBox(height: 16.h),
          Text(
            'حدث خطأ في تحميل الإشعارات',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(ApiProviders.notificationProvider.notifier)
                  .fetchNotifications();
            },
            child: Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.asMap().entries.map((entry) {
                  final index = entry.key;
                  final filter = entry.value;
                  final isSelected = _selectedFilterIndex == index;

                  return GestureDetector(
                    onTap: () {
                      logButtonClick('notifications_filter_tab', data: {
                        'filter_index': index,
                        'filter_name': filter,
                      });
                      setState(() {
                        _selectedFilterIndex = index;
                        _selectedFilter = filter;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(left: 8.w),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected ? context.primary : context.surface,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected
                              ? context.primary
                              : context.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? context.surface
                              : context.primaryText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Refresh button
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: context.primary,
              size: 24.sp,
            ),
            onPressed: () {
              logButtonClick('notifications_refresh');
              ref
                  .read(ApiProviders.notificationProvider.notifier)
                  .refreshNotifications();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(ApiProviders.notificationProvider.notifier)
            .refreshNotifications();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationData notification) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: notification.isRead
            ? context.surface
            : context.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: notification.isRead
              ? context.secondary.withOpacity(0.2)
              : context.primary.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            notification.icon,
            size: 20.sp,
            color: _getNotificationColor(notification.type),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
            color: context.primaryText,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.secondaryText,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _formatTimestamp(notification.timestamp),
              style: TextStyle(
                fontSize: 12.sp,
                color: context.secondaryText,
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: context.secondary),
                onSelected: (value) =>
                    _handleNotificationAction(value, notification),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'read',
                    child: Text(
                        notification.isRead ? 'إلغاء القراءة' : 'تحديد كمقروء'),
                  ),
                  // const PopupMenuItem(
                  //   value: 'delete',
                  //   child: Text('حذف'),
                  // ),
                ],
              ),
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  Widget _buildEmptyState() {
    final notificationState = ref.watch(ApiProviders.notificationProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80.sp,
            color: context.secondary.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'ستظهر هنا الإشعارات الجديدة',
            style: TextStyle(
              fontSize: 14.sp,
              color: context.secondaryText,
            ),
          ),
          // Debug information
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: context.secondary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  'معلومات التصحيح:',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: context.primaryText,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'إجمالي الإشعارات: ${notificationState.notifications.length}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: context.secondaryText,
                  ),
                ),
                Text(
                  'الإشعارات غير المقروءة: ${notificationState.unreadCount}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: context.secondaryText,
                  ),
                ),
                Text(
                  'حالة التحميل: ${notificationState.isLoading ? "جاري التحميل" : "تم التحميل"}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: context.secondaryText,
                  ),
                ),
                if (notificationState.error != null)
                  Text(
                    'خطأ: ${notificationState.error}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: context.error,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.academic:
        return context.primary;
      case NotificationType.system:
        return context.secondary;
      case NotificationType.offer:
        return context.accent;
      case NotificationType.message:
        return Colors.green;
      case NotificationType.call:
        return Colors.red;
      case NotificationType.reminder:
        return Colors.blue;
      case NotificationType.payment:
        return Colors.teal;
      case NotificationType.booking:
        return Colors.purple;
      case NotificationType.news:
        return Colors.amber;
      case NotificationType.promotion:
        return Colors.pink;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _handleNotificationTap(NotificationData notification) {
    logButtonClick('notification_tapped', data: {
      'notification_id': notification.id,
      'notification_type': notification.type.toString(),
      'was_read': notification.isRead,
    });
    
    setState(() {
      notification.isRead = true;
    });

    // Handle different notification types
    switch (notification.type) {
      case NotificationType.academic:
        _showAcademicNotificationDetails(notification);
        break;
      case NotificationType.system:
        _showSystemNotificationDetails(notification);
        break;
      case NotificationType.offer:
        _showOfferNotificationDetails(notification);
        break;
      case NotificationType.message:
        _showMessageNotificationDetails(notification);
        break;
      case NotificationType.call:
        _showCallNotificationDetails(notification);
        break;
      case NotificationType.reminder:
      case NotificationType.payment:
      case NotificationType.booking:
      case NotificationType.news:
      case NotificationType.promotion:
        _showGeneralNotificationDetails(notification);
        break;
    }
  }

  void _handleNotificationAction(String action, NotificationData notification) {
    logButtonClick('notification_action', data: {
      'action': action,
      'notification_id': notification.id,
    });
    
    switch (action) {
      case 'read':
        setState(() {
          notification = notification;
        });

        ref
            .read(ApiProviders.notificationProvider.notifier)
            .markNotificationAsRead(notification.id.toString());

        break;
      case 'delete':
        setState(() {
          _notifications.remove(notification);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حذف الإشعار'),
            backgroundColor: context.success,
          ),
        );
        break;
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تحديد جميع الإشعارات كمقروءة'),
        backgroundColor: context.success,
      ),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف جميع الإشعارات'),
        content: Text('هل أنت متأكد من حذف جميع الإشعارات؟'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حذف جميع الإشعارات'),
                  backgroundColor: context.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.error),
            child: Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showAcademicNotificationDetails(NotificationData notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            SizedBox(height: 16.h),
            Text(
              'النوع: إشعار أكاديمي',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.secondaryText,
              ),
            ),
            Text(
              'الوقت: ${_formatTimestamp(notification.timestamp)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showSystemNotificationDetails(NotificationData notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            SizedBox(height: 16.h),
            Text(
              'النوع: إشعار نظام',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.secondaryText,
              ),
            ),
            Text(
              'الوقت: ${_formatTimestamp(notification.timestamp)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showOfferNotificationDetails(NotificationData notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            SizedBox(height: 16.h),
            Text(
              'النوع: عرض خاص',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.secondaryText,
              ),
            ),
            Text(
              'الوقت: ${_formatTimestamp(notification.timestamp)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              // Navigate to offers page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('سيتم فتح صفحة العروض'),
                  backgroundColor: context.success,
                ),
              );
            },
            child: Text('عرض التفاصيل'),
          ),
        ],
      ),
    );
  }

  void _showMessageNotificationDetails(NotificationData notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            SizedBox(height: 16.h),
            Text(
              'النوع: رسالة',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.secondaryText,
              ),
            ),
            Text(
              'الوقت: ${_formatTimestamp(notification.timestamp)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              // Navigate to Matrix chat
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('سيتم فتح المحادثة'),
                  backgroundColor: context.success,
                ),
              );
            },
            child: Text('فتح المحادثة'),
          ),
        ],
      ),
    );
  }

  void _showCallNotificationDetails(NotificationData notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            SizedBox(height: 16.h),
            Text(
              'النوع: مكالمة',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.secondaryText,
              ),
            ),
            Text(
              'الوقت: ${_formatTimestamp(notification.timestamp)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              // Navigate to call screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('سيتم فتح شاشة المكالمة'),
                  backgroundColor: context.success,
                ),
              );
            },
            child: Text('فتح المكالمة'),
          ),
        ],
      ),
    );
  }

  void _showGeneralNotificationDetails(NotificationData notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            SizedBox(height: 16.h),
            Text(
              'النوع: ${_getNotificationTypeName(notification.type)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.secondaryText,
              ),
            ),
            Text(
              'الوقت: ${_formatTimestamp(notification.timestamp)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  String _getNotificationTypeName(NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return 'تذكير';
      case NotificationType.payment:
        return 'مدفوعات';
      case NotificationType.booking:
        return 'حجز';
      case NotificationType.news:
        return 'أخبار';
      case NotificationType.promotion:
        return 'ترقية';
      default:
        return 'إشعار';
    }
  }
}

class NotificationData {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  bool isRead;
  final DateTime timestamp;
  final IconData icon;

  NotificationData({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.timestamp,
    required this.icon,
  });
}
