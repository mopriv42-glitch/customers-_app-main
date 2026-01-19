import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:private_4t_app/core/widgets/main_tab_bar.dart';
import 'package:private_4t_app/features/clips/screens/clips_screen.dart';
import 'package:private_4t_app/features/contact/screens/contact_screen.dart';
import 'package:private_4t_app/features/home/screens/home_screen.dart';
import 'package:private_4t_app/features/menu/screens/menu_screen.dart';
import 'package:private_4t_app/features/subscriptions/screens/subscriptions_screen.dart';
import 'package:riverpod_context/riverpod_context.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'MainNavigationscreen';
  
  int _currentIndex = 0;
  late final List<Widget Function()> _screenBuilders;
  late final List<Widget?> _builtScreens;
  late final List<bool> _initialized;

  @override
  void initState() {
    super.initState();
    _screenBuilders = [
      () => const HomeScreen(),
      () => const SubscriptionsScreen(),
      () => const ClipsScreen(),
      () => const ContactScreen(),
      () => const MenuScreen(),
    ];
    _builtScreens = List<Widget?>.filled(_screenBuilders.length, null);
    _initialized = List<bool>.filled(_screenBuilders.length, false);
    // Eagerly build only the first tab
    _builtScreens[0] = _screenBuilders[0]();
    _initialized[0] = true;
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe once to live incoming calls for this room

    return NotificationListener<MainNavigationNotification>(
      onNotification: (notification) {
        // Handle navigation notification to focus on specific tab
        setState(() {
          final targetIndex = notification.targetIndex;
          if (!_initialized[targetIndex]) {
            _builtScreens[targetIndex] = _screenBuilders[targetIndex]();
            _initialized[targetIndex] = true;
          }
          _currentIndex = targetIndex;
        });
        return true; // Mark notification as handled
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: context.background,
          body: IndexedStack(
            index: _currentIndex,
            children: List.generate(_screenBuilders.length, (index) {
              final child = _builtScreens[index] ?? const SizedBox.shrink();
              return TickerMode(
                enabled: index == _currentIndex,
                child: child,
              );
            }),
          ),
          bottomNavigationBar: MainTabBar(
            selectedIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                if (!_initialized[index]) {
                  _builtScreens[index] = _screenBuilders[index]();
                  _initialized[index] = true;
                }

                if (_currentIndex == 2 && index != 2) {
                  context
                      .read(ApiProviders.clipProvider)
                      .setScreenActive(false);
                }

                if (index == 2 &&
                    !context.read(ApiProviders.clipProvider).isScreenActive) {
                  context.read(ApiProviders.clipProvider).setScreenActive(true);
                }

                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
