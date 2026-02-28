import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:private_4t_app/core/services/notification_service.dart';

class FirebaseMessagingService {
  static final messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // Request permissions
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      final token = await messaging.getToken();
      if (token != null) {
        // Send token to backend on first launch (fire-and-forget)
        unawaited(_sendTokenToBackend(token));
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        // state = state.copyWith(fcmToken: newToken);
        _sendTokenToBackend(newToken);
      });

      // Set up message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp
          .listen(_handleForegroundMessageAction);
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final payload = message.data;
      payload['title'] = message.notification?.title;
      payload['body'] = message.notification?.body;
      debugPrint(
          "From Foreground : ${message.messageId}, data: ${payload.toString()}");
        await handleFirebaseMessage(message);
// state = state.copyWith(
//         lastNotification: payload,
//         notificationCount: state.notificationCount + 1,
//       );
    } catch (e, s) {
      debugPrintStack(
          stackTrace: s, label: 'Error handling foreground message: $e');
    }
  }

  static Future<void> _handleForegroundMessageAction(
      RemoteMessage message) async {
    try {
      final payload = message.data;
      payload['title'] = message.notification?.title;
      payload['body'] = message.notification?.body;
      debugPrint(
          "From ForegroundMessageAction : ${message.messageId}, data: ${payload.toString()}");

      await handleFirebaseMessageAction(message);
    } catch (e) {
      debugPrint('Error handling background message: $e');
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      // Get user token
      final userToken = await CommonComponents.getSavedData(ApiKeys.userToken);
      if (userToken == null) {
        debugPrint('User token not found, cannot send FCM token');
        return;
      }

      // Get APNS token and VoIP token for iOS
      String? apnToken;
      String? voipToken;
      if (Platform.isIOS) {
        apnToken = await FirebaseMessaging.instance.getAPNSToken();
        voipToken = await CommonComponents.getSavedData('voip_token');
      }

      final body = {
        'fcm_token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        if (apnToken != null) 'apn_token': apnToken,
        if (voipToken != null) 'voip_token': voipToken,
      };

      // ⚠️ نمرر context: null عمداً — لأن ApiRequests.postApiRequest
      // عند حدوث خطأ يستدعي Navigator.pop(context) حتى لو showLoadingWidget=false
      // وهذا يسحب الصفحة الرئيسية ويسبب شاشة سوداء
      final response = await ApiRequests.postApiRequest(
        context: null,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'notifications/fcm-token',
        headers: {
          'Authorization': 'Bearer $userToken',
          'Content-Type': 'application/json',
        },
        body: body,
        showLoadingWidget: false,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ _sendTokenToBackend timed out after 10s');
          return null;
        },
      );

      if (response != null) {
        debugPrint('FCM token sent to backend successfully');
        // Save FCM token locally
        await CommonComponents.saveData(
          key: ApiKeys.fcmToken,
          value: token,
        );
        if (Platform.isIOS && apnToken != null) {
          await CommonComponents.saveData(
            key: ApiKeys.apnToken,
            value: apnToken,
          );
        }
      }
    } catch (e) {
      // لا نريد أن نكسر تهيئة التطبيق بسبب فشل إرسال token
      debugPrint('Error sending FCM token to backend: $e');
    }
  }

  static Future<void> handleFirebaseMessage(RemoteMessage message) async {
    await NotificationService.showLocalFCMNotification(message,
        allowCall: false, allowMessage: true);
  }

  static Future<void> handleFirebaseMessageAction(RemoteMessage message) async {
    try {
      final payload = message.data;
      if (payload['type'] == 'matrix_message' || payload['type'] == 'message') {
        await NotificationService.handleMatrixMessageAction(payload);
      } else if (payload['type'] == 'deep_link') {
        await NotificationService.handleDeepLinkAction(payload);
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: 'Error handling action: $e');
    }
  }
}

