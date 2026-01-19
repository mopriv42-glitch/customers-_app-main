import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const AndroidNotificationChannel _androidNotificationChannel =
      AndroidNotificationChannel("private_4t_high_importance_channels",
          "Private 4T High Importance Notifications");

  static init() async {
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('logo'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification: onDidReceiveIOSLocalNotification,
      ),
    );
    await FlutterLocalNotificationsPlugin().initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final platform = FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_androidNotificationChannel);
  }

  static void onDidReceiveIOSLocalNotification(
      int id, String? title, String? body, String? payload) async {}

  static Future<void> displayWithButtons(RemoteMessage message) async {
    try {
      int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await FlutterLocalNotificationsPlugin().show(
        id,
        message.notification != null
            ? message.notification!.title
            : message.data['title'],
        message.notification != null
            ? message.notification!.body
            : message.data['body'],
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidNotificationChannel.id,
            _androidNotificationChannel.name,
            importance: Importance.max,
            playSound: true,
            priority: Priority.high,
            actions: [
              const AndroidNotificationAction(
                'ACCEPT',
                'قبول',
              ),
              const AndroidNotificationAction(
                'DENY',
                'رفض',
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  static Future<void> display(RemoteMessage message) async {
    try {
      int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await FlutterLocalNotificationsPlugin().show(
        id,
        message.notification != null
            ? message.notification!.title
            : message.data['title'],
        message.notification != null
            ? message.notification!.body
            : message.data['body'],
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidNotificationChannel.id,
            _androidNotificationChannel.name,
            importance: Importance.max,
            playSound: true,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(
      NotificationResponse notificationResponse) {
    print(notificationResponse.actionId);
    print('It is work');
  }

  static Future<void> onDidReceiveNotificationResponse(
      NotificationResponse response) async {
    print("It's work from anthor");
  }
}
