import 'package:flutter/material.dart';

class AppNavigator {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  static toRoute(String route, {Object? args}) {
    navigatorKey.currentState?.pushNamed(route, arguments: args);
  }

  static toRouteAndReplace(String route, {Object? args}) {
    navigatorKey.currentState?.pushReplacementNamed(route, arguments: args);
  }

  static toRouteAndReplaceAll(String route, {Object? args}) {
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(route, (route) => false, arguments: args);
  }

  static back() {
    navigatorKey.currentState?.pop();
  }

  static String getCurrentRouteName() {
    String currentRoute = '';
    navigatorKey.currentState?.popUntil((route) {
      currentRoute = route.settings.name ?? '';
      return true;
    });
    return currentRoute;
  }
}
