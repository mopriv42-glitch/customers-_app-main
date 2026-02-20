import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class CallService {
  static Future<bool> requestCallPermissions(bool isVideoCall) async {
    try {
      // Request microphone permission
      final microphoneStatus = await Permission.microphone.request();

      if (microphoneStatus != PermissionStatus.granted) {
        return false;
      }

      // Request camera permission for video calls
      if (isVideoCall) {
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus != PermissionStatus.granted) {
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting call permissions: $e');
      }
      return false;
    }
  }

  static Future<bool> checkCallPermissions(bool isVideoCall) async {
    try {
      final microphoneStatus = await Permission.microphone.status;

      if (microphoneStatus != PermissionStatus.granted) {
        return false;
      }

      if (isVideoCall) {
        final cameraStatus = await Permission.camera.status;
        if (cameraStatus != PermissionStatus.granted) {
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking call permissions: $e');
      }
      return false;
    }
  }

  static Future<void> openPermissionSettings() async {
    await openAppSettings();
  }

  static String getPermissionMessage(bool isVideoCall) {
    if (isVideoCall) {
      return 'This app needs microphone and camera permissions to make video calls. Please grant permissions in Settings.';
    } else {
      return 'This app needs microphone permission to make voice calls. Please grant permission in Settings.';
    }
  }
}
