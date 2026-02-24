import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationPermissionsService {
  static final NotificationPermissionsService _instance =
      NotificationPermissionsService._internal();
  factory NotificationPermissionsService() => _instance;
  NotificationPermissionsService._internal();

  /// Request all required permissions for notifications and calls
  static Future<Map<Permission, PermissionStatus>>
      requestAllPermissions() async {
    try {
      final Map<Permission, PermissionStatus> statuses = {};

      // Request notification permissions
      if (Platform.isAndroid) {
        // Android 13+ requires POST_NOTIFICATIONS permission
        if (await _isAndroid13OrHigher()) {
          statuses[Permission.notification] =
              await Permission.notification.request();
        }
      }

      // Request microphone permission for calls
      statuses[Permission.microphone] = await Permission.microphone.request();

      // Request camera permission for video calls
      statuses[Permission.camera] = await Permission.camera.request();

      // Request storage permissions for media
      if (Platform.isAndroid) {
        if (await _isAndroid10OrLower()) {
          statuses[Permission.storage] = await Permission.storage.request();
        } else {
          statuses[Permission.photos] = await Permission.photos.request();
          statuses[Permission.videos] = await Permission.videos.request();
        }
      } else if (Platform.isIOS) {
        statuses[Permission.photos] = await Permission.photos.request();
      }

      // Request location permissions if needed
      statuses[Permission.location] = await Permission.location.request();

      // Request phone state permission for calls
      if (Platform.isAndroid) {
        statuses[Permission.phone] = await Permission.phone.request();
      }

      // DO NOT request ignoreBatteryOptimizations here automatically. 
      // This causes a system intent to launch immediately on startup, 
      // causing the FlutterActivity to lose focus, freeze, and result in a black screen.
      // statuses[Permission.ignoreBatteryOptimizations] = await Permission.ignoreBatteryOptimizations.request();

      return statuses;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return {};
    }
  }

  /// Request specific permission
  static Future<PermissionStatus> requestPermission(
      Permission permission) async {
    try {
      return await permission.request();
    } catch (e) {
      debugPrint('Error requesting permission $permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Check if specific permission is granted
  static Future<bool> isPermissionGranted(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking permission $permission: $e');
      return false;
    }
  }

  /// Check if all required permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    try {
      final permissions = await requestAllPermissions();
      return permissions.values.every((status) => status.isGranted);
    } catch (e) {
      debugPrint('Error checking all permissions: $e');
      return false;
    }
  }

  /// Request notification permissions specifically
  static Future<bool> requestNotificationPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Request awesome_notifications permissions
        final isAllowed =
            await AwesomeNotifications().requestPermissionToSendNotifications();

        // Request system notification permission for Android 13+
        if (await _isAndroid13OrHigher()) {
          final status = await Permission.notification.request();
          return isAllowed && status.isGranted;
        }

        return isAllowed;
      } else if (Platform.isIOS) {
        // Request Firebase messaging permissions
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          announcement: true,
          badge: true,
          carPlay: false,
          criticalAlert: true,
          provisional: false,
          sound: true,
        );

        return settings.authorizationStatus == AuthorizationStatus.authorized;
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Request call permissions specifically
  static Future<bool> requestCallPermissions() async {
    try {
      final microphoneStatus = await Permission.microphone.request();
      final cameraStatus = await Permission.camera.request();

      if (Platform.isAndroid) {
        final phoneStatus = await Permission.phone.request();
        return microphoneStatus.isGranted &&
            cameraStatus.isGranted &&
            phoneStatus.isGranted;
      } else if (Platform.isIOS) {
        return microphoneStatus.isGranted && cameraStatus.isGranted;
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting call permissions: $e');
      return false;
    }
  }

  /// Open app settings if permissions are permanently denied
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied(
      Permission permission) async {
    try {
      final status = await permission.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      debugPrint('Error checking if permission is permanently denied: $e');
      return false;
    }
  }

  /// Get permission status description
  static String getPermissionStatusDescription(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Permission granted';
      case PermissionStatus.denied:
        return 'Permission denied';
      case PermissionStatus.restricted:
        return 'Permission restricted';
      case PermissionStatus.limited:
        return 'Permission limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permission permanently denied';
      default:
        return 'Unknown permission status';
    }
  }

  /// Check if Android version is 13 or higher
  static Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      try {
        // This is a simplified check - in production you might want to use device_info_plus
        return true; // Assume Android 13+ for now
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  /// Check if Android version is 10 or lower
  static Future<bool> _isAndroid10OrLower() async {
    if (Platform.isAndroid) {
      try {
        // This is a simplified check - in production you might want to use device_info_plus
        return false; // Assume Android 11+ for now
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  /// Show permission explanation dialog
  static Future<bool> showPermissionExplanationDialog(
    BuildContext context,
    String title,
    String message,
    String permissionName,
  ) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Grant Permission'),
              ),
            ],
          );
        },
      );

      return result ?? false;
    } catch (e) {
      debugPrint('Error showing permission explanation dialog: $e');
      return false;
    }
  }

  /// Get permission explanation message
  static String getPermissionExplanationMessage(Permission permission) {
    switch (permission) {
      case Permission.notification:
        return 'This app needs notification permission to show you important updates, messages, and incoming calls.';
      case Permission.microphone:
        return 'This app needs microphone permission to enable voice calls and audio messages.';
      case Permission.camera:
        return 'This app needs camera permission to enable video calls and photo sharing.';
      case Permission.location:
        return 'This app needs location permission to provide location-based services.';
      case Permission.phone:
        return 'This app needs phone permission to handle incoming calls properly.';
      case Permission.photos:
        return 'This app needs photos permission to access and share images.';
      case Permission.storage:
        return 'This app needs storage permission to save and access files.';
      default:
        return 'This app needs this permission to function properly.';
    }
  }
}
