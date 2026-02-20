import 'package:flutter/material.dart';
import 'analytics_service.dart';

/// Navigator observer for tracking screen views
class AnalyticsNavigatorObserver extends NavigatorObserver {
  final AnalyticsService _analytics = AnalyticsService.instance;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logScreenView(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _logScreenView(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logScreenView(newRoute);
    }
  }

  /// Log screen view
  void _logScreenView(Route<dynamic> route) {
    final screenName = _extractScreenName(route);
    if (screenName != null) {
      _analytics.currentScreen = screenName;
      _analytics.logEvent(
        'screen_view',
        properties: {
          'screen_name': screenName,
          'route_name': route.settings.name ?? 'unknown',
        },
        screen: screenName,
      );
    }
  }

  /// Extract screen name from route
  String? _extractScreenName(Route<dynamic> route) {
    // First try to get from route settings
    if (route.settings.name != null && route.settings.name!.isNotEmpty) {
      return route.settings.name!.replaceFirst('/', '');
    }
    
    return null;
  }
}

