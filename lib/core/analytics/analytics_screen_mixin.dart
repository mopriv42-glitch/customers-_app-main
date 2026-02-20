import 'package:flutter/material.dart';
import 'analytics_helpers.dart';

/// Mixin لإضافة تتبع Analytics تلقائياً للشاشات
mixin AnalyticsScreenMixin<T extends StatefulWidget> on State<T> {
  String get screenName;

  @override
  void initState() {
    super.initState();
    // Log screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logScreenEntry();
    });
  }

  /// تسجيل دخول الشاشة
  void logScreenEntry() {
    AnalyticsHelpers.logButtonTap(
      buttonId: 'screen_entered',
      screen: screenName,
      additionalData: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// تسجيل ضغط زر
  void logButtonClick(String buttonId, {Map<String, dynamic>? data}) {
    AnalyticsHelpers.logButtonTap(
      buttonId: buttonId,
      screen: screenName,
      additionalData: data,
    );
  }

  /// تسجيل خطوة في عملية
  void logStep(String step, {Map<String, dynamic>? data}) {
    AnalyticsHelpers.logBookingStep(
      step: step,
      screen: screenName,
      data: data,
    );
  }

  /// تسجيل Pull to Refresh
  void logRefresh() {
    AnalyticsHelpers.logPullToRefresh(screen: screenName);
  }
}
