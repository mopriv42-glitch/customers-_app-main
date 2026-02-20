// lib/core/services/navigation_queue.dart أو ملف مشابه
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:private_4t_app/app_config/common_components.dart';

@pragma('vm:entry-point')
class PendingNavigation {
  final String path;
  final Object? extra; // أو أي معلومات إضافية تحتاجها
  // final Map<String, dynamic> offer; // إذا احتجتها لاحقًا

  PendingNavigation({required this.path, this.extra});

  Map<String, dynamic> toMap() {
    return {
      "path": path,
      "extra": extra,
    };
  }

  factory PendingNavigation.fromMap(Map map) {
    return PendingNavigation(path: map['path'] ?? '', extra: map['extra']);
  }

  @override
  String toString() {
    return toMap().toString();
  }
}

@pragma('vm:entry-point')
class NavigationQueue {
  @pragma('vm:entry-point')
  static final List<VoidCallback> _listeners = [];

  @pragma('vm:entry-point')
  static const shKey = "pendingNav";

  @pragma('vm:entry-point')
  static PendingNavigation? _pendingCallNavigation;

  static PendingNavigation? get pendingCallNavigation => _pendingCallNavigation;

  @pragma('vm:entry-point')
  static Future<void> setPendingCallNavigation(PendingNavigation? nav) async {
    _pendingCallNavigation = nav;
    if (nav == null) {
      await CommonComponents.deleteSavedData(shKey);
    } else {
     final result = await CommonComponents.saveData(
          key: shKey, value: jsonEncode(nav.toMap()));
      debugPrint("The save pending navigation result: $result");
    }
    notifyPendingCallNavigationChanged();
  }

  // يمكنك أيضًا إضافة Stream أو StreamController إذا أردت تنبيه الـ Widgets بشكل ديناميكي
  @pragma('vm:entry-point')
  static final StreamController<PendingNavigation?> _controller =
      StreamController<PendingNavigation?>.broadcast();

  @pragma('vm:entry-point')
  static Stream<PendingNavigation?> get onPendingCallNavigationChanged =>
      _controller.stream;

  @pragma('vm:entry-point')
  static void notifyPendingCallNavigationChanged() {
    _controller.sink.add(_pendingCallNavigation);
  }

  @pragma('vm:entry-point')
  static void dispose() {
    _controller.close();
  }

  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
}
