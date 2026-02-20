import 'package:flutter/material.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/utils/constants.dart';

/// Bottom navigation bar with 5 tabs, RTL ready.
class MainTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTap;
  const MainTabBar({super.key, this.selectedIndex = 0, this.onTap});

  void _handleTabTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
    } else {
      // Default navigation - just call the onTap callback
      // The actual navigation will be handled by the parent widget
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) => _handleTabTap(context, index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: context.surface,
      selectedItemColor: context.primary,
      unselectedItemColor: context.secondary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_filled),
          label: 'الرئيسية',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.subscriptions),
          label: 'اشتراكاتي',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.video_library),
          label: 'Clips',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'التواصل',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu),
          label: 'قائمة',
        ),
      ],
    );
  }
}
