import 'package:flutter/services.dart';
import 'package:private_4t_app/core/providers/app_container.dart';
import 'package:private_4t_app/core/services/call_kit_service.dart';
import 'package:private_4t_app/core/services/notification_service.dart';

@pragma("vm:entry-point")
class MatrixServiceListener {
  @pragma("vm:entry-point")
  static const MethodChannel _serviceChannel =
      MethodChannel('com.private-4t.service');

  // تفعيل listener
  @pragma("vm:entry-point")
  static void startListening() {
    _serviceChannel.setMethodCallHandler((call) async {
      if (call.method == 'startMatrixSync') {
        // هنا تشغل كود المزامنة مع Matrix
        await startMatrixSync();
      }
    });
  }

  @pragma("vm:entry-point")
  static Future<void> startMatrixSync() async {
    try {
      await CallKitService.instance.initialize();
    } catch (_) {}
    try {
      await NotificationService.initializeNotifications();
    } catch (_) {}
    await getMatrix();
  }
}
