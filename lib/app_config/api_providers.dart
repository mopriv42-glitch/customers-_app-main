import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_4t_app/core/providers/authentication_providers/login_provider.dart';
import 'package:private_4t_app/core/providers/booking_providers/booking_provider.dart';
import 'package:private_4t_app/core/providers/booking_providers/video_courses_provider.dart';
import 'package:private_4t_app/core/providers/cart_providers/cart_provider.dart';
import 'package:private_4t_app/core/providers/library_providers/library_provider.dart';
import 'package:private_4t_app/core/providers/setting_provider.dart';
import 'package:private_4t_app/core/providers/subscriptions_providers/subscriptions_provider.dart';
import 'package:private_4t_app/core/providers/matrix_chat_provider.dart';
import 'package:private_4t_app/core/providers/teachers_provider.dart';
import 'package:private_4t_app/core/providers/theme_provider.dart';
import 'package:private_4t_app/core/providers/dashboard_providers/home_provider.dart';
import 'package:private_4t_app/core/providers/clips_providers/clip_provider.dart';
import 'package:private_4t_app/core/providers/wishlist_provider.dart';
import 'package:private_4t_app/core/providers/notification_provider.dart';

class ApiProviders {
  static final ChangeNotifierProvider<LoginProvider> loginProvider =
      ChangeNotifierProvider((ref) => LoginProvider());

  static final ChangeNotifierProvider<BookingProvider> bookingProvider =
      ChangeNotifierProvider((ref) => BookingProvider());

  static final ChangeNotifierProvider<VideoCoursesProvider>
      videoCoursesProvider = ChangeNotifierProvider(
    (ref) => VideoCoursesProvider(),
  );

  static final ChangeNotifierProvider<SettingProvider>
  settingProvider = ChangeNotifierProvider(
        (ref) => SettingProvider(),
  );

  static final ChangeNotifierProvider<SubscriptionsProvider>
      subscriptionsProvider = ChangeNotifierProvider(
    (ref) => SubscriptionsProvider(),
  );

  static final ChangeNotifierProvider<LibraryProvider> libraryProvider =
      ChangeNotifierProvider((ref) => LibraryProvider());

  static final ChangeNotifierProvider<CartProvider> cartProvider =
      ChangeNotifierProvider((ref) => CartProvider());

  static final ChangeNotifierProvider<MatrixChatProvider> matrixChatProvider =
      ChangeNotifierProvider((ref) => MatrixChatProvider());

  static final ChangeNotifierProvider<HomeProvider> homeProvider =
      ChangeNotifierProvider((ref) => HomeProvider());

  static final ChangeNotifierProvider<ClipProvider> clipProvider =
      ChangeNotifierProvider((ref) => ClipProvider());

  static final ChangeNotifierProvider<WishlistProvider> wishlistProvider =
      ChangeNotifierProvider((ref) => WishlistProvider());

  static final themeProvider = StateNotifierProvider<ThemeProvider, ThemeMode>(
    (ref) => ThemeProvider(),
  );

  static final notificationProvider =
      StateNotifierProvider<NotificationProvider, NotificationState>(
    (ref) => NotificationProvider(),
  );

  static final teachersProvider =
  ChangeNotifierProvider<TeachersProvider>(
    (ref) => TeachersProvider(),
  );
}
