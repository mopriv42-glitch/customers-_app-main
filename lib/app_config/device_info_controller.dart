import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class DeviceInfoController {
  static final _deviceInfoPlugin = DeviceInfoPlugin();

  static Future<String?> getDeviceInfo() async {
    String? info;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        info = "Device: ${androidInfo.model}\n"
            "Manufacturer: ${androidInfo.manufacturer}\n"
            "Android Version: ${androidInfo.version.release}\n"
            "SDK: ${androidInfo.version.sdkInt}\n"
            "ID: ${androidInfo.id}";
      } else if (!kIsWeb && Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
        info = "Device: ${iosInfo.utsname.machine}\n"
            "Name: ${iosInfo.name}\n"
            "System Name: ${iosInfo.systemName}\n"
            "System Version: ${iosInfo.systemVersion}\n"
            "Model: ${iosInfo.model}";
      } else if (kIsWeb) {
        info = "Web Platform";
      }
    } catch (e) {
      debugPrint("Failed to get device info: $e");
    }
    return info;
  }
}
