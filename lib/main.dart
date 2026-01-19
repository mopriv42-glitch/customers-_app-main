import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/pusher_controller.dart';
import 'package:private_4t_app/core/analytics/analytics_service.dart';
import 'package:private_4t_app/core/analytics/analytics_global_listener.dart';
import 'package:private_4t_app/core/navigation/app_router.dart';
import 'package:private_4t_app/core/providers/notification_integration_provider.dart';
import 'package:private_4t_app/core/providers/theme_provider.dart';
import 'package:private_4t_app/core/services/app_optimization_service.dart';
import 'package:private_4t_app/core/services/app_state_manager.dart';
import 'package:private_4t_app/core/services/call_kit_service.dart';
import 'package:private_4t_app/core/services/matrix_call_service.dart';
import 'package:private_4t_app/core/services/matrix_service_listener.dart';
import 'package:private_4t_app/core/services/memory_optimization_service.dart';
import 'package:private_4t_app/core/services/navigation_queue.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:private_4t_app/core/services/network_optimization_service.dart';
import 'package:private_4t_app/core/services/performance_service.dart';
import 'package:private_4t_app/core/theme/app_theme.dart';
import 'package:private_4t_app/core/utils/constants.dart';
import 'package:private_4t_app/features/contact/screens/weidgets/call_manager.dart';
import 'package:riverpod_context/riverpod_context.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:upgrader/upgrader.dart';

import 'app_config/api_keys.dart';
import 'app_config/common_components.dart';
import 'core/providers/app_container.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

String? initialDeepLinkRoute;

@pragma('vm:entry-point')
Future<void> _messageHandler(RemoteMessage message) async {
  if (kIsWeb) return; // Skip on web platform

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  debugPrint("Background message received: ${message.messageId}");
  debugPrint("Message data: ${message.data}");
  debugPrint("Message notification: ${message.notification?.toMap()}");

  // Handle Matrix call invitations when app is terminated
  final data = message.data;
  final isMatrixCall = data['type'] == 'call' ||
      data['event_type'] == 'm.call.invite' ||
      (data.containsKey('call_id') && data.containsKey('room_id'));

  if (isMatrixCall) {
    debugPrint("Matrix call invitation detected in background");
    try {
      await _handleMatrixCallInvitation(data);
      return; // Early return for call invitations
    } catch (e, s) {
      debugPrintStack(
          stackTrace: s,
          label: "Matrix call background handler error: ${e.toString()}");
    }
  }

  // Handle regular notifications (non-call)
  if (message.notification == null) {
    try {
      await NotificationService.initializeNotifications();
    } catch (_) {}

    try {
      await NotificationService.showLocalFCMNotification(
        message,
        allowCall: false,
        allowMessage: true,
      ); // No call handling for regular notifications
      debugPrint("Handling a background message: ${message.messageId}");
    } catch (e, s) {
      debugPrintStack(
          stackTrace: s, label: "Background Handler error: ${e.toString()}");
    }
  }
}

@pragma('vm:entry-point')
Future<void> _handleMatrixCallInvitation(Map<String, dynamic> data) async {
  try {
    // Initialize CallKit service
    await CallKitService.instance.initialize();
    var payload = data['metadata'] ?? {};
    if (payload is String) {
      try {
        payload = jsonDecode(payload);
      } catch (e) {
        debugPrint("Error decoding payload JSON: ${e.toString()}");
        payload = {}; // تعيين قيمة افتراضية في حال الفشل
      }
    }

    // Extract call information
    final callId = payload['call_id'] as String?;
    final roomId = payload['room_id'] as String?;
    final eventId = payload['event_id'] as String?;
    final callerName = payload['caller_name'] as String? ??
        payload['sender_name'] as String? ??
        'Unknown Caller';
    final callerId = payload['caller_id'] as String? ??
        payload['sender_id'] as String? ??
        '';
    final avatarUrl = payload['avatar_url'] as String?;

    if (callId == null || roomId == null) {
      debugPrint("Missing required call data: callId=$callId, roomId=$roomId");
      return;
    }

    debugPrint("Showing CallKit for Matrix call: $callId in room: $roomId");

    // Show CallKit incoming call
    await CallKitService.instance.showIncomingCall(
      callerName: callerName,
      callerId: callerId,
      roomId: roomId,
      eventId: eventId,
      callId: callId,
      avatarUrl: avatarUrl,
      supportsVideo: data['is_video'] == 'true' || data['is_video'] == true,
    );

    // Store call information for when app is opened
    await CommonComponents.saveData(
        key: 'pending_matrix_call_id', value: callId);
    await CommonComponents.saveData(
        key: 'pending_matrix_room_id', value: roomId);
    if (eventId != null) {
      await CommonComponents.saveData(
          key: 'pending_matrix_event_id', value: eventId);
    }
  } catch (e, s) {
    debugPrintStack(
        stackTrace: s,
        label: "Error handling Matrix call invitation: ${e.toString()}");
  }
}

// دالة لجمع المعلومات وإرسال التقرير
@pragma("vm:entry-point")
Future<void> _reportError(Object error, StackTrace? stackTrace) async {
  try {
    // 1. جمع معلومات الخطأ
    final String errorMessage = error.toString();
    final String stackTraceString =
        stackTrace?.toString() ?? 'No stack trace available';

    // 2. جمع معلومات الجهاز والتطبيق (مثال)
    String appVersion = 'Unknown';
    String osInfo = 'Unknown';
    String deviceModel = 'Unknown';

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    } catch (e) {
      // التعامل مع الخطأ في الحصول على معلومات الحزمة
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        osInfo = 'Android ${androidInfo.version.release}';
        deviceModel = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        osInfo = 'IOS ${iosInfo.systemVersion}';
        deviceModel = iosInfo.model;
      }
    } catch (e) {
      // التعامل مع الخطأ في الحصول على معلومات الجهاز
    }

    // 3. جمع معلومات إضافية (اختيارية)
    final String timestamp = DateTime.now().toIso8601String();
    // final String locale = window.locale.toString(); // من dart:ui
    // final String orientation = WidgetsBinding.instance.window.orientation.toString(); // من dart:ui

    // 4. إنشاء تقرير نصي
    final String report = '''
----- Bug Report -----
Error: $errorMessage
Stack Trace:
$stackTraceString

App Version: $appVersion
OS: $osInfo
Device Model: $deviceModel
Timestamp: $timestamp
---------------------
''';

    // 5. إرسال التقرير
    await _sendReport(report);
  } catch (reportingError, reportingStack) {
    // من المهم أن تكون دالة إرسال التقرير محاطة بـ try/catch
    // لمنع حدوث خطأ أثناء إرسال تقرير خطأ من تدمير التطبيق أكثر.
    debugPrint("Failed to send error report: $reportingError");
    debugPrintStack(stackTrace: reportingStack);
  }
}

// دالة لإرسال التقرير (ستُعرّف لاحقًا)
@pragma("vm:entry-point")
Future<void> _sendReport(String report) async {
  ApiRequests.postApiRequest(
    baseUrl: ApiKeys.baseUrl,
    apiUrl: "error-reports",
    headers: {},
    body: {'report': report},
  );

  // Also log to analytics service
  try {
    AnalyticsService.instance.logEvent(
      'app_error',
      properties: {'report': report},
    );
  } catch (_) {}
}

@pragma("vm:entry-point")
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MatrixServiceListener.startListening();

  // Initialize Analytics Service
  await AnalyticsService.instance.initialize(
    baseUrl: ApiKeys.baseUrl,
  );

  AppStateManager().initialize();
// PlatformDispatcher.instance.onError متوفر في Flutter 3.3+
  PlatformDispatcher.instance.onError = (error, stack) {
    // أرسل تقرير الخطأ هنا
    _reportError(error, stack);
    return true; // تشير إلى أن الخطأ تمت معالجته
  };

  // 2. التقاط أخطاء Flutter Framework
  FlutterError.onError = (FlutterErrorDetails details) {
    // أرسل تقرير الخطأ هنا
    // يمكنك التحقق مما إذا كان الخطأ فادحًا بما يكفي لتقريره
    if (kDebugMode) {
      // في الوضع التطويري، فقط اطبع الخطأ
      FlutterError.dumpErrorToConsole(details);
    } else {
      // في الوضع الإنتاجي، أرسل التقرير
      _reportError(details.exception, details.stack);
    }
  };

  await EasyLocalization.ensureInitialized();
  await Upgrader.clearSavedSettings();
  await CallKitService.instance.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_messageHandler);
  }

  // Initialize Theme Provider
  await providerAppContainer
      .read(ApiProviders.themeProvider.notifier)
      .initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'languages',
      startLocale: const Locale("ar"),
      saveLocale: true,
      fallbackLocale: const Locale('ar'),
      child: ProviderScope(
        parent: providerAppContainer,
        child: const InheritedConsumer(
          child: MyApp(),
        ),
      ),
    ),
  );

  tz.initializeTimeZones();
  await initializeDateFormatting('ar', null); // تهيئة اللغة العربية

  debugPrint(
    "Token: ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
  );

  // Initialize Performance Service
  PerformanceService.instance.initialize();

  // Initialize Memory Optimization Service
  MemoryOptimizationService.instance.initialize();

  // Initialize Network Optimization Service
  NetworkOptimizationService.instance.initialize();

  // Initialize App Optimization Service
  await AppOptimizationService.instance.initialize();

  // Initialize Pusher
  try {
    await PusherController.init();
  } catch (e) {
    debugPrint('Failed to initialize Pusher: $e');
  }

  if (!kIsWeb) {
    await providerAppContainer
        .read(notificationIntegrationProvider.notifier)
        .initializeAllServices();
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  late StreamSubscription<PendingNavigation?> _navigationSubscription;

  // Removed unused stored room id; we derive it at runtime
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Log app opened
    AnalyticsService.instance.logEvent(
      'app_opened',
      properties: {'timestamp': DateTime.now().toIso8601String()},
      screen: 'App',
    );

    _navigationSubscription =
        NavigationQueue.onPendingCallNavigationChanged.listen((pending) {
      if (pending != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _processPendingNavigation(pending);
        });
      }
    });
    // Token refresh will be handled by NotificationProvider
    // Track app lifecycle to show system overlay when app minimized
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      final calls = MatrixCallService.instance;

      if (msg == AppLifecycleState.resumed.toString()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final pending = NavigationQueue.pendingCallNavigation;
          if (pending != null) {
            _processPendingNavigation(pending);
          }
        });
      }

      if (msg == AppLifecycleState.paused.toString() ||
          msg == AppLifecycleState.inactive.toString()) {
        try {
          if (calls != null) {
            // If a call is active, ensure system overlay is visible
            String? roomId = calls.anyActiveRoomId;
            if (roomId == null) {
              final ctx = NavigationService.rootNavigatorKey.currentContext;
              if (ctx != null) {
                final state = GoRouterState.of(ctx);
                final loc = state.uri.toString();
                final match = RegExp(r"^/call/(.+)").firstMatch(loc);
                if (match != null) roomId = match.group(1);
              }
            }
            if (roomId != null) {
              final ctx2 = NavigationService.rootNavigatorKey.currentContext;
              // In-app overlay (if app still has UI)
              if (ctx2 != null) {
                // NavigationService.showCallOverlay(ctx2, roomId);
              }
              // Ensure Android system overlay floats above other apps
              // await NavigationService.ensureSystemOverlay(roomId);
            }
          }
        } catch (_) {}
      }

      try {
        if (calls != null) {
          if (!calls.hasActiveCall) {
            NavigationService.hideCallOverlay();
          }
        }
      } catch (_) {}

      return null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Log app lifecycle changes
    switch (state) {
      case AppLifecycleState.resumed:
        AnalyticsService.instance.logEvent(
          'app_resumed',
          properties: {'timestamp': DateTime.now().toIso8601String()},
          screen: 'App',
        );
        // Ensure proper cleanup when app is resumed
        final calls = MatrixCallService.instance;
        if (calls != null && !calls.hasActiveCall) {
          NavigationService.hideCallOverlay();
        }
        break;
      case AppLifecycleState.inactive:
        AnalyticsService.instance.logEvent(
          'app_inactive',
          properties: {'timestamp': DateTime.now().toIso8601String()},
          screen: 'App',
        );
        break;
      case AppLifecycleState.paused:
        AnalyticsService.instance.logEvent(
          'app_backgrounded',
          properties: {'timestamp': DateTime.now().toIso8601String()},
          screen: 'App',
        );
        // Clean up overlays when app is paused or detached
        NavigationService.hideCallOverlay();
        break;
      case AppLifecycleState.detached:
        AnalyticsService.instance.logEvent(
          'app_detached',
          properties: {'timestamp': DateTime.now().toIso8601String()},
          screen: 'App',
        );
        // Clean up overlays when app is paused or detached
        NavigationService.hideCallOverlay();
        break;
      default:
        break;
    }
  }

  void _processPendingNavigation(PendingNavigation pending) {
    try {
      final context = NavigationService.rootNavigatorKey.currentContext;
      if (context != null) {
        NavigationQueue.setPendingCallNavigation(null);

        // استخدم GoRouter push مباشرة
        final router = GoRouter.of(context);
        router.push(pending.path, extra: pending.extra);
      }
    } catch (e, stack) {
      debugPrint('Error processing pending navigation: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  @override
  void dispose() {
    // Log app closed
    AnalyticsService.instance.logEvent(
      'app_closed',
      properties: {'timestamp': DateTime.now().toIso8601String()},
      screen: 'App',
    );

    WidgetsBinding.instance.removeObserver(this);
    _navigationSubscription.cancel();
    NavigationQueue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(ApiProviders.themeProvider);
    final themeNotifier = ref.watch(ApiProviders.themeProvider.notifier);
    final isCastle = themeNotifier.currentBrand == BrandTheme.castle;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationService.setRouter(router);
    });

    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      final calls = ref.watch(ApiProviders.matrixChatProvider).calls;
      calls?.incomingCalls.listen((inc) {
        // SystemSound.play(SystemSoundType.alert);
        // MatrixNotificationsBridge.showIncomingCall(inc);
        //   CallKitService.instance.showIncomingCall(
        //     callerName: inc.room.getLocalizedDisplayname(),
        //     callerId: inc.callId,
        //     roomId: inc.room.id,
        //     callId: inc.callId,
        //     offer: inc.offer,
        //   );
        /*showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('مكالمة واردة'),
          content: Text('من غرفة: ${inc.room.getLocalizedDisplayname()}'),
          actions: [
            TextButton(
              onPressed: () async {
                await calls.declineIncomingCall(inc.callId);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('رفض'),
            ),
            ElevatedButton(
              onPressed: () async {
                await calls.acceptIncomingCall(inc.room.id, inc.callId);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (!mounted) return;
                NavigationService.navigateToCall(context, inc.room.id);
              },
              child: const Text('رد'),
            ),
          ],
        ),
      );*/
      });
    }

    return AnalyticsGlobalListener(
      enableGlobalTracking: true,
      enableDebugInfo: kDebugMode,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        // iPhone X design size
        minTextAdapt: true,
        splitScreenMode: true,
        useInheritedMediaQuery: true,
        // Performance optimization
        builder: (context, child) => MaterialApp.router(
          title: Constants.appName,
          debugShowCheckedModeBanner: false,
          theme: isCastle ? AppThemes.castleLight : AppThemes.light,
          darkTheme: AppThemes.dark,
          themeMode: themeMode,
          routerConfig: router,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          ),
          builder: (context, child) {
            return UpgradeAlert(
              dialogStyle: (!kIsWeb && Platform.isIOS)
                  ? UpgradeDialogStyle.cupertino
                  : UpgradeDialogStyle.material,
              // Customize dialog style
              showIgnore: false,
              // Optional: Disable the ignore button
              showLater: true,
              upgrader: Upgrader(
                storeController: UpgraderStoreController(
                  onAndroid: () => UpgraderPlayStore(),
                  oniOS: () => UpgraderAppStore(),
                ),
                countryCode: "SA",
                // Changed to Saudi Arabia
                languageCode: 'ar',
                minAppVersion: "1.1.4",
                // Updated to current version
                durationUntilAlertAgain: const Duration(days: 1),
                // Show alert again after 1 day
                debugLogging: true, // Enable debug logging
              ),
              navigatorKey: NavigationService.rootNavigatorKey,
              child: PopScope(
                onPopInvokedWithResult: (value, d) {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
                child: Stack(
                  children: [const CallManager(), if (child != null) child],
                ),
                // const CallManager(),
              ),
            );
          },
        ),
      ),
    );
  }
}
