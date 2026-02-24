import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:private_4t_app/core/models/notification_model.dart'
    as local_notification_model;
import 'package:private_4t_app/core/providers/app_container.dart';
import 'package:private_4t_app/core/services/download_service.dart';
import 'package:private_4t_app/core/services/firebase_messaging_service.dart';
import 'package:private_4t_app/core/services/matrix_call_service.dart';
import 'package:private_4t_app/core/services/navigation_queue.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:riverpod_context/riverpod_context.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../app_config/api_providers.dart';

@pragma('vm:entry-point')
class NotificationService {
  static final NotificationService instance = NotificationService();
  static const String _portName =
      'notification_action_port'; // Define port name constant
  static const String messageChannelId = 'matrix_messages';
  static const String messageChannelName = 'رسائل الدردشة';
  static const String messageChannelDescription = 'إشعارات رسائل الماتركس';
  static const String _channelId = 'private_4t_notifications';
  static const String _channelName = 'Private 4T Notifications';
  static const String _channelDescription =
      'General notifications for Private 4T app';

  static const String callChannelId = 'private_4t_calls';
  static const String callChannelName = 'Private 4T Calls';
  static const String callChannelDescription = 'Incoming call notifications';

  static const Uuid _uuid = Uuid();
  static final _providerContainer = providerAppContainer;

  static const String actionKeyOpenRoom = 'OPEN_ROOM';
  static const String actionKeyMarkRead = 'MARK_READ';
  static const String actionKeyReply = 'REPLY_CHAT';
  static const String actionKeyAcceptCall = 'ACCEPT_CALL';
  static const String actionKeyDeclineCall = 'DECLINE_CALL';
  static const String actionKeyMute = 'MUTE_CALL';
  static const String actionKeySpeaker = 'SPEAKER_TOGGLE';
  static const String actionKeyHangup = 'HANGUP_CALL';

  static bool _init = false;

  /// Initialize the notification service
  @pragma('vm:entry-point')
  static Future<void> initializeNotifications() async {
    await AwesomeNotifications().initialize(
      "resource://drawable/logo",
      [
        NotificationChannel(
          channelKey: messageChannelId,
          channelName: messageChannelName,
          channelDescription: messageChannelDescription,
          defaultColor: const Color(0xFF0052CC),
          ledColor: const Color(0xFF0052CC),
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: _channelId,
          channelName: _channelName,
          channelDescription: _channelDescription,
          defaultColor: Colors.blue,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
        ),
        NotificationChannel(
          channelKey: callChannelId,
          channelName: callChannelName,
          channelDescription: callChannelDescription,
          defaultColor: Colors.green,
          ledColor: Colors.green,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
          playSound: true,
          defaultRingtoneType: DefaultRingtoneType.Ringtone,
        ),
        NotificationChannel(
          channelKey: DownloadService.DOWNLOAD_NOTIFICATION_CHANNEL_ID,
          channelName: "Download notifications",
          channelDescription:
              "This channel will received all downloading notifications",
          importance: NotificationImportance.Max,
          playSound: true,
          channelShowBadge: true,
        ),
      ],
      debug: kDebugMode,
    );

    if (!_init) {
      // تأكد من عدم تكرار التسجيل
      _init = true;

      // 1. إنشاء ReceivePort
      ReceivePort receivePort = ReceivePort();

      // 2. الحصول على SendPort المرتبط بـ ReceivePort
      SendPort sendPort = receivePort.sendPort; // <-- هذا هو الصحيح

      // 3. تسجيل SendPort باسم فريد في IsolateNameServer
      //    (SendPort هو الذي يُرسل، وبالتالي يُسجل)
      //    إزالة أي تسجيل قديم أولاً لتفادي الفشل عند إعادة التشغيل
      IsolateNameServer.removePortNameMapping(_portName);
      IsolateNameServer.registerPortWithName(
        sendPort, // <-- استخدم sendPort هنا
        _portName, // اسم فريد
      );

      print("Registered SendPort with name: $_portName");

      // الاستماع للرسائل على هذا الـ port
      receivePort.listen((dynamic serializedData) async {
        print('Received action data in main isolate via ReceivePort');
        try {
          // تحويل البيانات المستلمة إلى ReceivedAction
          final receivedAction = ReceivedAction().fromMap(serializedData);
          // استدعاء المعالج الفعلي في الـ main isolate
          await onActionReceived(receivedAction); // أو _processActionLocally
        } catch (e, s) {
          print('Error processing action in main isolate: $e');
          debugPrintStack(stackTrace: s);
        }
      });
    }

    // Set up action listeners
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationService.onActionReceivedEntryPoint,
      onNotificationCreatedMethod: NotificationService.onNotificationCreated,
      onNotificationDisplayedMethod:
          NotificationService.onNotificationDisplayed,
      onDismissActionReceivedMethod:
          NotificationService.onNotificationDismissed,
    );

    // Request permissions
    try {
      await _requestPermissions();
    } catch (_) {}
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  /// Handle incoming notification from Firebase
  static Future<void> handleIncomingNotification(
      Map<String, dynamic> payload) async {
    try {
      final notificationType = payload['type'] ?? 'general';

      switch (notificationType) {
        case 'call':
          await _handleIncomingCall(payload);
          break;
        case 'message':
          // await handleMatrixMessage(payload);
          break;
        case 'deep_link':
          await handleDeepLinkAction(payload);
          break;
        default:
          await _showGeneralNotification(payload);
      }
    } catch (e, s) {
      debugPrintStack(
          stackTrace: s, label: 'Error handling incoming notification: $e');
    }
  }

  /// Show general notification (offers, promotions, system updates, etc.)
  static Future<void> _showGeneralNotification(
      Map<String, dynamic> payload) async {
    final title = payload['title'] ?? 'Notification';
    final body = payload['body'] ?? '';
    final Map<String, String?>? data = payload['data'];
    final category = payload['category'] ?? 'general';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _uuid.v4().hashCode,
        channelKey: _channelId,
        title: title,
        body: body,
        payload: data,
        largeIcon: "resource://drawable/logo",
        category: getCategory(category),
        notificationLayout: getLayout(category),
      ),
    );
  }

  /// Handle Matrix message notification
  @pragma('vm:entry-point')
  static Future<void> handleMatrixMessage(
      Map<String, dynamic> notification, Map<String, dynamic> payload) async {
    final senderName = payload['sender_name'] ?? 'Unknown';
    final messagePreview = payload['message_preview'] ?? '';
    final roomId = payload['room_id'];
    final userId = payload['user_id'];
    final eventId = payload['event_id'];

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: roomId?.hashCode ?? _uuid.v4().hashCode,
        channelKey: messageChannelId,
        title: notification['title'] ?? "رسالة من $senderName",
        body: notification['body'] ?? messagePreview,
        payload: {
          'type': 'message',
          'room_id': roomId,
          'event_id': eventId,
          'user_id': userId,
          'sender_name': senderName,
        },
        category: NotificationCategory.Message,
        notificationLayout: NotificationLayout.Messaging,
      ),
      actionButtons: [
        NotificationActionButton(
          key: actionKeyOpenRoom,
          label: 'فتح',
        ),
        NotificationActionButton(
          key: actionKeyMarkRead,
          label: 'تمييز كمقروء',
          actionType: ActionType.SilentBackgroundAction,
          showInCompactView: true,
        ),
        NotificationActionButton(
          key: actionKeyReply,
          label: 'رد',
          requireInputText: true,
          actionType: ActionType.SilentBackgroundAction,
          showInCompactView: true,
          autoDismissible: true,
        ),
      ],
    );
  }

  /// Handle incoming call notification
  @pragma('vm:entry-point')
  static Future<void> _handleIncomingCall(Map<String, dynamic> payload) async {
    final callerName = payload['caller_name'] ?? 'Private 4T User';
    final callerId = payload['caller_id'] ?? '';
    final roomId = payload['room_id'] ?? '';
    final callId = payload['call_id'];
    String? avatar = payload['avatar'];
    var offer = payload['offer'];
    var eventId = payload['event_id'] ?? payload['matrix_event_id'] ?? '';
    if (offer is String) {
      offer = jsonDecode(offer);
    }

    debugPrint("The event id: $eventId");

    final matrix = await getMatrix();
    if (matrix.isLoggedIn && matrix.isInitialized) {
      // final session = await MatrixCallService.instance
      //     ?.createSession(callId, roomId, eventId);
      // if (session != null) {
      // avatar ??= matrix.client.getRoomById(roomId)?.avatar.toString();
      // if (Platform.isIOS) {
      //   // await CommonComponents.saveData(key: "matrix_call", value: callerId);
      //   // await NavigationQueue.setPendingCallNavigation(
      //   //     PendingNavigation(path: '/call/$roomId'));
      //   // await CommonComponents.saveData(key: 'matrix_call', value: callId);
      //
      //   await CallKitService.instance.showIncomingCall(
      //     callerName: callerName,
      //     callerId: callerId,
      //     roomId: roomId,
      //     callId: callId,
      //     eventId: eventId,
      //     avatarUrl: avatar,
      //   );
      // } else {
      //   await showIncomingCall(callId, roomId, callerName, avatar);
      // }
      // }
    }

    // MatrixSyncService(callId);
    //
  }

  /// Show iOS CallKit incoming call
  static Future<void> _showIOSIncomingCall(Map<String, dynamic> payload) async {
    final callerName = payload['caller_name'] ?? 'Unknown';
    final callerId = payload['caller_id'] ?? '';
    final roomId = payload['room_id'] ?? '';
    final callId = payload['call_id'] ?? _uuid.v4();

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'Private 4T',
      avatar: payload['avatar_url'] ?? '',
      handle: callerId,
      type: 1,
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      extra: {
        'room_id': roomId,
        'caller_id': callerId,
      },
      headers: <String, dynamic>{
        'apiKey': 'Abc@123!',
        'platform': 'flutter',
      },
      android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          logoUrl: 'https://i.pravatar.cc/100',
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          backgroundUrl: 'https://i.pravatar.cc/500',
          actionColor: '#4CAF50',
          textColor: '#ffffff',
          incomingCallNotificationChannelName: "Incoming Call",
          missedCallNotificationChannelName: "Missed Call",
          isShowCallID: false),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  // /// Handle notification action buttons
  // @pragma('vm:entry-point')
  // static Future<void> onActionReceived(ReceivedAction receivedAction) async {
  //   print("=========== FROM ACTION RECEIVED ==========");
  //   print("The actions : ${receivedAction.toMap().toString()}");
  //
  //   try {
  //     final payload = receivedAction.payload ?? {};
  //     final actionKey = receivedAction.buttonKeyPressed;
  //
  //     if (actionKey == 'ACCEPT_CALL') {
  //       await handleCallAction(payload, 'accept');
  //     } else if (actionKey == 'DECLINE_CALL') {
  //       await handleCallAction(payload, 'decline');
  //     } else if (payload['type'] == 'matrix_message' ||
  //         payload['type'] == 'message') {
  //       await handleMatrixMessageAction(payload);
  //     } else if (payload['type'] == 'deep_link') {
  //       await handleDeepLinkAction(payload);
  //     } else if ('REPLY_ACTION' == actionKey) {
  //       ApiRequests.postApiRequest(
  //         baseUrl: ApiKeys.baseUrl,
  //         apiUrl: "send-message",
  //         headers: {
  //           "Authorization":
  //               "${await CommonComponents.getSavedData(ApiKeys.userToken)}",
  //         },
  //         body: {"body": receivedAction.buttonKeyInput},
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint('Error handling action: $e');
  //   }
  // }

  /// Handle call actions (accept/decline)
  static Future<void> handleCallAction(
      Map<String, dynamic> payload, String action) async {
    final roomId = payload['room_id'];
    final callId = payload['call_id'];

    if (action == 'accept') {
      // Navigate to Matrix call screen
      final context = NavigationService.rootNavigatorKey.currentContext;
      if (context != null) {
        context.go('/home');
        NavigationService.navigateToCall(context, roomId);
      }
      // Initialize Matrix call
      final matrixService = MatrixCallService.instance;
      if (matrixService != null) {
        await matrixService.acceptIncomingCall(roomId, callId);
      }
    } else if (action == 'decline') {
      // Send decline API to backend
      await _sendCallResponseToBackend(callId, 'declined');

      // Dismiss iOS CallKit if needed
      if (Platform.isIOS) {
        await FlutterCallkitIncoming.endCall(callId);
      }
    }
  }

  /// Handle Matrix message action
  static Future<void> handleMatrixMessageAction(
      Map<String, dynamic> payload) async {
    final roomId = payload['room_id'];

    if (NavigationService.rootNavigatorKey.currentContext != null) {
      NavigationService.navigateToRoomTimeline(
          NavigationService.rootNavigatorKey.currentContext!, roomId);
    }
  }

  /// Handle deep link action
  static Future<void> handleDeepLinkAction(Map<String, dynamic> payload) async {
    final url = payload['url'] as String;
    final type = payload['link_type'] ?? 'internal';

    if (type == 'internal') {
      // Navigate to internal route
      if (NavigationService.rootNavigatorKey.currentContext != null) {
        NavigationService.navigateToHome(
            NavigationService.rootNavigatorKey.currentContext!);
        if (url != '/home') {
          GoRouter.of(NavigationService.rootNavigatorKey.currentContext!)
              .push(url);
        }
      } else {
        NavigationQueue.setPendingCallNavigation(PendingNavigation(path: url));
      }
    } else if (type == 'external') {
      // Open external link
      await _launchExternalUrl(url);
    }
  }

  /// Handle enhanced deep link notification with image support
  static Future<void> _handleEnhancedDeepLinkNotification(
      Map<String, dynamic> notification, Map<String, dynamic> metadata) async {
    try {
      final String title = notification['title'] ?? 'إشعار جديد';
      final String body = notification['body'] ?? '';
      final String notificationType = metadata['type'] ?? 'deep_link';
      final String url = metadata['url'] ?? '';
      final String linkType = metadata['link_type'] ?? 'internal';
      final List<dynamic> images = metadata['images'] ?? [];

      // Prepare payload for the notification
      Map<String, String> notificationPayload = {
        'type': notificationType,
        'url': url,
        'link_type': linkType,
        'images': jsonEncode(images),
      };

      // Add all metadata as strings
      metadata.forEach((key, value) {
        if (key != null && value != null) {
          notificationPayload[key.toString()] = value.toString();
        }
      });

      // Determine notification layout based on images
      NotificationLayout layout = NotificationLayout.Default;
      String? bigPictureUrl;

      if (images.isNotEmpty) {
        // Use the first image as big picture
        bigPictureUrl = images.first.toString();
        layout = NotificationLayout.BigPicture;
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _uuid.v4().hashCode,
          channelKey: _channelId,
          title: title,
          body: body,
          payload: notificationPayload,
          category: NotificationCategory.Event,
          icon: "resource://drawable/logo",
          largeIcon: bigPictureUrl ?? "resource://drawable/logo",
          bigPicture: bigPictureUrl,
          notificationLayout: layout,
          wakeUpScreen: true,
          showWhen: true,
        ),
        // actionButtons: [
        //   NotificationActionButton(
        //     key: 'OPEN_LINK',
        //     label: linkType == 'internal' ? 'فتح' : 'عرض',
        //     actionType: ActionType.SilentAction,
        //   ),
        // ],
      );

      debugPrint(
          "Enhanced deep link notification created with ${images.length} images");
    } catch (e, s) {
      debugPrintStack(
          stackTrace: s,
          label: 'Error handling enhanced deep link notification: $e');
    }
  }

  /// Send call response to backend
  static Future<void> _sendCallResponseToBackend(
      String callId, String response) async {
    try {
      debugPrint('Sending call response to backend: $callId - $response');
    } catch (e) {
      debugPrint('Error sending call response to backend: $e');
    }
  }

  /// Launch external URL
  static Future<void> _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error handling external link: $e');
    }
  }

  /// Handle open link action from notification
  static Future<void> _handleOpenLinkAction(
      Map<String, dynamic> payload) async {
    try {
      final String url = payload['url'] ?? '';
      final String linkType = payload['link_type'] ?? 'internal';
      final String imagesJson = payload['images'] ?? '[]';

      if (url.isEmpty) {
        debugPrint('No URL provided in notification payload');
        return;
      }

      // Parse images if available
      List<dynamic> images = [];
      try {
        images = jsonDecode(imagesJson);
      } catch (e) {
        debugPrint('Error parsing images: $e');
      }

      if (linkType == 'internal') {
        // Navigate to internal route (WebView for URLs starting with /webview)
        if (NavigationService.rootNavigatorKey.currentContext != null) {
          final context = NavigationService.rootNavigatorKey.currentContext!;

          if (url.startsWith('/webview')) {
            // Navigate to webview screen
            GoRouter.of(context).push(url);
          } else {
            // Navigate to other internal routes
            NavigationService.navigateToHome(context);
            if (url != '/home') {
              GoRouter.of(context).push(url);
            }
          }
        } else {
          NavigationQueue.setPendingCallNavigation(PendingNavigation(
            path: url,
            extra: {'images': images},
          ));
        }
      } else if (linkType == 'external') {
        // Open external link
        await _launchExternalUrl(url);
      }

      debugPrint(
          'Opened link: $url (type: $linkType) with ${images.length} images');
    } catch (e, s) {
      debugPrintStack(
          stackTrace: s, label: 'Error handling open link action: $e');
    }
  }

  /// Handle notification creation
  @pragma('vm:entry-point')
  static Future<void> onNotificationCreated(
      ReceivedNotification receivedNotification) async {
    try {
      final context = NavigationService.rootNavigatorKey.currentContext;
      if (context != null) {
        final newNotification =
            local_notification_model.NotificationModel.fromJson({
          // افتراضيات، استبدل بالقيم الفعلية من receivedNotification
          "id": receivedNotification.id ?? DateTime.now().millisecondsSinceEpoch,
          "title": receivedNotification.title ?? 'إشعار جديد',
          "message": receivedNotification.body ?? '',
          // type: NotificationType. ... // حدد النوع حسب payload أو channel
          "isRead": false, // الإشعارات الجديدة تكون غير مقروءة
          // استخراج البيانات الوصفية (metadata) من receivedNotification
          // receivedNotification.payload يحتوي على البيانات الإضافية
          "metadata": receivedNotification.payload?.cast<String, dynamic>() ?? {},
          // يمكنك إضافة created_at إذا كانت البيانات توفرها
          // created_at: DateTime.now(),
        });
        context
            .read(ApiProviders.notificationProvider.notifier)
            .addLocalNotification(newNotification);
      }
    } catch (e, s) {
      debugPrint('Error in onNotificationCreated: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  /// Handle notification display
  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayed(
      ReceivedNotification receivedNotification) async {}

  /// Handle notification dismissal
  @pragma('vm:entry-point')
  static Future<void> onNotificationDismissed(
      ReceivedAction receivedAction) async {}

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  /// Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  /// Show local notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, String?>? payload,
    NotificationCategory category = NotificationCategory.Event,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _uuid.v4().hashCode,
        channelKey: _channelId,
        title: title,
        body: body,
        payload: payload,
        category: category,
        icon: "resource://drawable/logo",
        largeIcon: "resource://drawable/logo",
        roundedLargeIcon: false,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
      ),
    );
  }

  static getCategory(category) {
    switch (category) {
      case 'message':
        return NotificationCategory.Message;
      case 'call':
        return NotificationCategory.Call;
      case 'reminder':
        return NotificationCategory.Reminder;
      case 'event':
        return NotificationCategory.Event;
      case 'service':
        return NotificationCategory.Service;
      case 'social':
        return NotificationCategory.Social;
      case 'email':
        return NotificationCategory.Email;
      case 'promotion':
        return NotificationCategory.Promo;
      case 'alert':
        return NotificationCategory.Alarm;
    }
    return null;
  }

  static getLayout(layout) {
    switch (layout) {
      case 'default':
        return NotificationLayout.Default;
      case 'big_picture':
        return NotificationLayout.BigPicture;
      case 'big_text':
        return NotificationLayout.BigText;
      case 'message':
        return NotificationLayout.Messaging;
    }
    return NotificationLayout.Default;
  }

  static getImportance(importance) {
    switch (importance) {
      case 'high':
        return NotificationImportance.High;
    }
    return NotificationImportance.High;
  }

  static getChannelKey(channelKey) {
    switch (channelKey) {
      case 'message':
        return _channelId;
    }
    return _channelId;
  }

  static getChannelName(channelName) {
    switch (channelName) {
      case 'message':
        return _channelName;
    }
  }

  // Handle notification tap when app is launched from terminated state
  static Future<void> handleInitialNotifications() async {
    try {
      // --- Handle Awesome Notifications Initial Action ---
      // Check if the app was opened via an awesome notification action
      ReceivedAction? initialAction =
          await AwesomeNotifications().getInitialNotificationAction();
      if (initialAction != null) {
        debugPrint(
            "App opened via Awesome Notification Action: ${initialAction.toString()}");
        await onActionReceived(initialAction);
        return; // Prioritize Awesome Notifications if both might be present
      }

      // --- Handle Firebase Messaging Initial Message ---
      // Check if the app was opened via a Firebase message tap
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
            "App opened via Firebase Message Tap: ${initialMessage.data.toString()}");
        await FirebaseMessagingService.handleFirebaseMessageAction(
            initialMessage);
        return;
      }

      debugPrint(
          "App opened normally, no initial notification action/message found.");
    } catch (e, s) {
      debugPrint("Error handling initial notifications: $e");
      debugPrintStack(stackTrace: s);
    }
  }

  /// نقطة الدخول الرئيسية لمعالجة الإجراءات - هذه هي التي تسجلها لدى AwesomeNotifications
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedEntryPoint(
      ReceivedAction receivedAction) async {
    print("onActionReceivedEntryPoint called");

    // 1. محاولة الحصول على SendPort المسجل مسبقًا في الـ main isolate
    SendPort? sendPort = IsolateNameServer.lookupPortByName(_portName);

    if (sendPort != null && receivedAction.actionType != ActionType.Default) {
      // 2. إذا وُجد SendPort، فنحن لسنا في الـ main isolate (أو على الأقل يمكننا التواصل معه)
      //    نقوم بإرسال البيانات إلى الـ main isolate عبر SendPort
      print("Sending action data to main isolate via SendPort");
      try {
        // إرسال البيانات (يجب أن تكون قابلة للترميز - encodable)
        sendPort.send(receivedAction.toMap());
        // لا نحتاج إلى متابعة التنفيذ هنا في الـ background isolate
        return;
      } catch (e) {
        print("Failed to send via SendPort, falling back: $e");
        // في حالة فشل الإرسال، ن_FALLBACK_ إلى التنفيذ المباشر (قد لا يعمل التوجيه)
        await _processActionLocally(receivedAction);
      }
    } else {
      // 3. إذا لم يوجد SendPort (مثلاً عند التشغيل في الـ main isolate مباشرة)، نعالج الإجراء محليًا
      print("Processing action directly (likely in main isolate or fallback)");
      await _processActionLocally(receivedAction);
    }
  }

  /// المعالج الفعلي الذي يعمل في الـ main isolate (يُستدعى من listen أو مباشرة)
  @pragma('vm:entry-point') // وضعه هنا أيضًا لضمان التوافق
  static Future<void> onActionReceived(ReceivedAction receivedAction) async {
    print("onActionReceived (main isolate logic) called");
    // هذا هو المعالج الحالي الذي يحتوي على منطقك
    // يمكنك نسخ منطقه إلى _processActionLocally أو استدعائه مباشرة
    await _processActionLocally(
      receivedAction,
    ); // أو استدعاء المعالج الأصلي مباشرة إن كان آمنًا
  }

  /// المعالج المشترك للإجراءات (يُستخدم في كلا الحالتين)
  @pragma('vm:entry-point')
  static Future<void> _processActionLocally(
      ReceivedAction receivedAction) async {
    print(
        "=========== FROM ACTION RECEIVED (_processActionLocally) ==========");
    print("The action data: ${receivedAction.toMap().toString()}");
    try {
      final payload = receivedAction.payload ?? {};
      final actionKey = receivedAction.buttonKeyPressed;
      final ctx = NavigationService.rootNavigatorKey.currentContext;

      debugPrint("Notification Payload: ${payload.toString()}");

      if (payload['type'] == 'deep_link') {
        await handleDeepLinkAction(payload);
      } else if (actionKey == 'OPEN_LINK') {
        await _handleOpenLinkAction(payload);
      } else if (payload['type'] == "message") {
        debugPrint("String Matrix Initializing....");
        final eventId = receivedAction.payload?['event_id'];
        final roomId = receivedAction.payload?['room_id'] ?? '';
        final matrix = await getMatrix();

        final room = matrix.clientNullable?.getRoomById(roomId);
        debugPrint("Room: ${room.toString()}");

        if (actionKey == actionKeyMarkRead) {
          if (room != null) {
            // Use setReadMarker instead of deprecated postReceipt
            await room.setReadMarker(eventId, mRead: eventId);
          }
        } else if (actionKey == actionKeyReply) {
          final text = receivedAction.buttonKeyInput;
          if (text.trim().isNotEmpty) {
            if (room != null) {
              await room.sendTextEvent(text.trim());
            }
          }
        } else {
          if (ctx != null) {
            NavigationService.navigateToHome(ctx);
            NavigationService.navigateToRoomTimeline(ctx, roomId);
          } else {
            NavigationQueue.setPendingCallNavigation(
                PendingNavigation(path: '/room/$roomId'));
          }
        }
      }

      final roomId = payload['roomId'];

      if (roomId == null) return;

      if (actionKey == actionKeyAcceptCall) {
        final callId = payload['callId'];
        final calls = MatrixCallService.instance;

        if (callId != null && calls != null) {
          await calls.acceptIncomingCall(roomId, callId);
        }

        if (ctx != null) {
          NavigationService.navigateToHome(ctx);
          NavigationService.navigateToCall(ctx, roomId);
        } else {
          try {
            await platform.invokeMethod('openApp');
          } catch (e, s) {
            debugPrintStack(label: e.toString(), stackTrace: s);
          }

          NavigationQueue.setPendingCallNavigation(
              PendingNavigation(path: '/call/$roomId'));
        }

        return;
      }

      if (actionKey == actionKeyDeclineCall) {
        final calls = MatrixCallService.instance;
        final s = calls?.getSession(roomId);
        if (s != null) {
          await s.reject(reason: CallErrorCode.userBusy);
        }
        return;
      }

      if (actionKey == actionKeyMute) {
        final calls = MatrixCallService.instance;
        final s = calls?.getSession(roomId);
        if (calls == null) return;
        if (s != null) {
          await s.setMicrophoneMuted(!s.isMicrophoneMuted);
          String? largeIcon;
          try {
            final avatar = s.room.avatar;
            if (avatar != null) {
              largeIcon = avatar
                  .getThumbnailUri(s.room.client, width: 96, height: 96)
                  .toString();
            }
          } catch (_) {}
          await showOngoingCall(
            roomId: roomId,
            callId: s.callId,
            muted: s.isMicrophoneMuted,
            speakerOn: calls.speakerOn,
            title: s.room.getLocalizedDisplayname(),
            largeIconUrl: largeIcon,
          );
        }
        return;
      }
      if (actionKey == actionKeySpeaker) {
        final calls = MatrixCallService.instance;
        if (calls == null) return;
        final s = calls?.getSession(roomId);
        if (s != null) {
          await calls.setSpeaker(!calls.speakerOn);
          String? largeIcon;
          try {
            final avatar = s.room.avatar;
            if (avatar != null) {
              largeIcon = avatar
                  .getThumbnailUri(s.room.client, width: 96, height: 96)
                  .toString();
            }
          } catch (_) {}
          await showOngoingCall(
            roomId: roomId,
            callId: s.callId,
            muted: s.isMicrophoneMuted,
            speakerOn: calls.speakerOn,
            title: s.room.getLocalizedDisplayname(),
            largeIconUrl: largeIcon,
          );
        }
        return;
      }
      if (actionKey == actionKeyHangup) {
        final calls = MatrixCallService.instance;
        final s = calls?.getSession(roomId);
        if (s != null) {
          await s.hangup(reason: CallErrorCode.userHangup);
          await dismissOngoingCall(roomId);
        }
        return;
      }
    } catch (e, s) {
      debugPrintStack(
          stackTrace: s,
          label: 'Error handling action in _processActionLocally: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> showLocalFCMNotification(RemoteMessage message,
      {bool allowCall = false, bool allowMessage = false}) async {
    try {
      // <-- إضافة try/catch للتعامل مع الأخطاء بشكل أفضل
      final data = message.data;
      var payload = data['metadata'] ?? {};
      var notification =
          message.notification?.toMap() ?? data['notification'] ?? {};

      debugPrint("Raw data received: ${data.toString()}"); // للتصحيح

      if (notification is String) {
        try {
          notification = jsonDecode(notification);
        } catch (e) {
          print("Error decoding notification JSON: $e");
          notification = {}; // تعيين قيمة افتراضية في حال الفشل
        }
      }

      if (payload is String) {
        try {
          payload = jsonDecode(payload);
        } catch (e) {
          print("Error decoding payload JSON: $e");
          payload = {}; // تعيين قيمة افتراضية في حال الفشل
        }
      }

      // التأكد من أن payload و notification هما Map
      if (notification is! Map) {
        notification = {};
      }
      if (payload is! Map) {
        payload = {};
      }

      final type = data['type'] ?? 'general';
      debugPrint("Processing notification type: $type"); // للتصحيح

      switch (type) {
        case 'message':
          if (allowMessage) {
            await handleMatrixMessage(notification.cast<String, dynamic>(),
                payload.cast<String, dynamic>());
          }
          break;
        case 'call':
          if (allowCall) {
            await _handleIncomingCall(payload.cast<String, dynamic>());
          }
          break;
        case 'deep_link':
          await _handleEnhancedDeepLinkNotification(
              notification.cast<String, dynamic>(),
              payload.cast<String, dynamic>());
          break;
        default:
          // طريقة أكثر أمانًا لتحويل payload إلى Map<String, String>
          Map<String, String> newPayload = {};

          // التأكد من نوع payload وتحويله بشكل آمن
          // استخدام map.forEach بشكل صحيح مع التحقق من الأنواع
          payload.forEach((key, value) {
            // التأكد من أن key و value ليسا null وأن key هو String
            if (key != null && key is String) {
              newPayload[key] = value?.toString() ?? '';
            }
          });

          // إضافة النوع إلى payload
          newPayload['type'] = type;

          if (notification['title'] == null && notification['body'] == null) {
            return;
          }

          // التأكد من أن notification يحتوي على title و body
          final title = (notification['title'] != null)
              ? notification['title'].toString()
              : 'إشعار جديد';
          final body = (notification['body'] != null)
              ? notification['body'].toString()
              : '';

          debugPrint(
              "Showing local notification: Title='$title', Body='$body', Payload=$newPayload"); // للتصحيح

          await showLocalNotification(
            title: title,
            body: body,
            payload: newPayload,
            category: NotificationCategory.Event,
          );
          break;
      }
    } catch (e, s) {
      debugPrint('Error in showLocalFCMNotification: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> dismissOngoingCall(String roomId) async {
    try {
      await AwesomeNotifications().dismiss(roomId.hashCode);
    } catch (_) {}
  }

  static Future<void> showOngoingCall({
    required String roomId,
    required String callId,
    required bool muted,
    required bool speakerOn,
    required String title,
    String? largeIconUrl,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: roomId.hashCode,
        channelKey: callChannelId,
        title: title,
        body: muted ? 'صامت' : 'نشط',
        payload: {'roomId': roomId, 'callId': callId},
        category: NotificationCategory.Call,
        notificationLayout: NotificationLayout.Default,
        largeIcon: largeIconUrl,
        autoDismissible: false,
        locked: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: actionKeyMute,
          label: muted ? 'إلغاء الكتم' : 'كتم',
          actionType: ActionType.SilentBackgroundAction,
        ),
        NotificationActionButton(
          key: actionKeySpeaker,
          label: speakerOn ? 'الهاتف' : 'المكبر',
          actionType: ActionType.SilentBackgroundAction,
        ),
        NotificationActionButton(
          key: actionKeyHangup,
          label: 'إنهاء',
          actionType: ActionType.SilentBackgroundAction,
        ),
      ],
    );
  }

  @pragma('vm:entry-point')
  static Future<void> showIncomingCall(
      String callId, String roomId, String callerName, String? avatar) async {
    try {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: callId.hashCode,
          channelKey: callChannelId,
          title: 'مكالمة واردة',
          body: callerName,
          payload: {'roomId': roomId, 'callId': callId},
          category: NotificationCategory.Call,
          fullScreenIntent: true,
          largeIcon: avatar,
          actionType: ActionType.DisabledAction,
          showWhen: true,
          wakeUpScreen: true,
          locked: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: actionKeyAcceptCall,
            label: 'رد',
            color: Colors.green,
            actionType: ActionType.SilentBackgroundAction,
          ),
          NotificationActionButton(
            key: actionKeyDeclineCall,
            label: 'رفض',
            color: Colors.redAccent,
            actionType: ActionType.SilentBackgroundAction,
          ),
        ],
      );
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: "showIncomingCall error: $e");
    }
  }
}
