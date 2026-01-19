import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:private_4t_app/core/analytics/analytics_navigator_observer.dart';
import 'package:private_4t_app/core/models/learning_course_model.dart';
import 'package:private_4t_app/core/models/offer_model.dart';
import 'package:private_4t_app/core/models/order_course_model.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:private_4t_app/features/auth/screens/confirm_otp_screen.dart';
import 'package:private_4t_app/features/auth/screens/phone_verification_screen.dart';
import 'package:private_4t_app/features/auth/screens/signin_screen.dart';
import 'package:private_4t_app/features/auth/screens/signup_screen.dart';
import 'package:private_4t_app/features/auth/screens/update_name_screen.dart';
import 'package:private_4t_app/features/booking/screens/address_screen.dart';
import 'package:private_4t_app/features/booking/screens/booking_summary_screen.dart';
import 'package:private_4t_app/features/booking/screens/data_confirmation_screen.dart';
import 'package:private_4t_app/features/booking/screens/existing_customer_institute_confirmation_screen.dart';
import 'package:private_4t_app/features/booking/screens/existing_customer_institute_screen.dart';
import 'package:private_4t_app/features/booking/screens/existing_customer_lesson_screen.dart';
import 'package:private_4t_app/features/booking/screens/existing_customer_online_confirmation_screen.dart';
import 'package:private_4t_app/features/booking/screens/existing_customer_online_screen.dart';
import 'package:private_4t_app/features/booking/screens/institute_booking_summary_screen.dart';
import 'package:private_4t_app/features/booking/screens/institute_lesson_details_screen.dart';
import 'package:private_4t_app/features/booking/screens/lesson_details_screen.dart';
import 'package:private_4t_app/features/booking/screens/online_booking_summary_screen.dart';
import 'package:private_4t_app/features/booking/screens/online_lesson_details_screen.dart';
import 'package:private_4t_app/features/booking/screens/payment_screen.dart'
    as booking_payment;
import 'package:private_4t_app/features/clips/screens/clips_screen.dart';
import 'package:private_4t_app/features/contact/screens/calls_screen.dart';
import 'package:private_4t_app/features/contact/screens/contact_screen.dart';
import 'package:private_4t_app/features/contact/screens/invitations_screen.dart';
import 'package:private_4t_app/features/contact/screens/room_timeline_screen.dart';
import 'package:private_4t_app/features/course_viewing/screens/course_viewing_screen.dart';
import 'package:private_4t_app/features/home/screens/education_institutes_screen.dart';
import 'package:private_4t_app/features/home/screens/home_screen.dart';
import 'package:private_4t_app/features/home/screens/kindergartens_screen.dart';
import 'package:private_4t_app/features/home/screens/libraries_screen.dart';
import 'package:private_4t_app/features/home/screens/schools_screen.dart';
import 'package:private_4t_app/features/main_navigation/main_navigation_screen.dart';
import 'package:private_4t_app/features/menu/screens/calendar_screen.dart';
import 'package:private_4t_app/features/menu/screens/exams_screen.dart';
import 'package:private_4t_app/features/menu/screens/favorites_screen.dart';
import 'package:private_4t_app/features/menu/screens/files_screen.dart';
import 'package:private_4t_app/features/menu/screens/help_support_screen.dart';
import 'package:private_4t_app/features/menu/screens/invite_friends_screen.dart';
import 'package:private_4t_app/features/menu/screens/live_stream_screen.dart';
import 'package:private_4t_app/features/menu/screens/menu_screen.dart';
import 'package:private_4t_app/features/menu/screens/offers_screen.dart';
import 'package:private_4t_app/features/menu/screens/progress_screen.dart';
import 'package:private_4t_app/features/menu/screens/share_app_screen.dart';
import 'package:private_4t_app/features/menu/screens/teacher_diagnostic_detail_screen.dart';
import 'package:private_4t_app/features/menu/screens/teacher_diagnostics_list_screen.dart';
import 'package:private_4t_app/features/menu/screens/teacher_follow_up_detail_screen.dart';
import 'package:private_4t_app/features/menu/screens/teacher_follow_ups_list_screen.dart';
import 'package:private_4t_app/features/menu/screens/teachers_screen.dart';
import 'package:private_4t_app/features/news/screens/news_screen.dart';
import 'package:private_4t_app/features/notes/screens/note_detail_screen.dart';
import 'package:private_4t_app/features/notes/screens/notes_screen.dart';
import 'package:private_4t_app/features/notifications/screens/notifications_screen.dart';
import 'package:private_4t_app/features/onboarding/screens/auth_choice_screen.dart';
import 'package:private_4t_app/features/onboarding/screens/role_selection_screen.dart';
import 'package:private_4t_app/features/onboarding/screens/splash_screen.dart';
import 'package:private_4t_app/features/onboarding/screens/welcome_screen.dart';
import 'package:private_4t_app/features/profile/screens/profile_screen.dart';
import 'package:private_4t_app/features/settings/screens/settings_screen.dart';
import 'package:private_4t_app/features/subscriptions/screens/booking_details_screen.dart';
import 'package:private_4t_app/features/subscriptions/screens/subscriptions_screen.dart';
import 'package:private_4t_app/features/video_lessons/screens/cart_payment_screen.dart'
    as cart_payment;
import 'package:private_4t_app/features/video_lessons/screens/cart_screen.dart';
import 'package:private_4t_app/features/video_lessons/screens/course_cards_screen.dart';
import 'package:private_4t_app/features/video_lessons/screens/course_details_screen.dart';
import 'package:private_4t_app/features/video_lessons/screens/payment_screen.dart'
    as video_payment;
import 'package:private_4t_app/features/webview/screens/webview_screen.dart';
import 'package:private_4t_app/main.dart';

/// Exposes a single global GoRouter instance via Riverpod
final routerProvider = Provider<GoRouter>((ref) {
  // Allow deep-link initial route from notifications (terminated state)
  final String? initial = initialDeepLinkRoute;
  return GoRouter(
    initialLocation: initial ?? '/splash',
    navigatorKey: NavigationService.rootNavigatorKey,
    // observers: [AnalyticsNavigatorObserver()],
    routes: [
      // Onboarding Routes
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/auth-choice/:role',
        builder: (context, state) {
          final role = state.pathParameters['role'] ?? 'student';
          return AuthChoiceScreen(role: role);
        },
      ),

      // Auth Routes
      GoRoute(
        path: '/signup/:role',
        builder: (context, state) {
          final role = state.pathParameters['role'] ?? 'student';
          return SignUpScreen(role: role);
        },
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/update-name',
        builder: (context, state) => const UpdateNameScreen(),
      ),

      GoRoute(
        path: '/phone-verification',
        builder: (context, state) {
          return const PhoneVerificationScreen();
        },
      ),
      GoRoute(
        path: '/confirm-otp',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final phone = (extras['phone'] ?? '') as String;
          final gradeId = (extras['gradeId'] ?? '') as String;
          final googleEmail = extras['googleEmail'] as String?;
          final googleName = extras['googleName'] as String?;
          final googleImage = extras['googleImage'] as String?;
          return ConfirmOtpScreen(
            phone: phone,
            gradeId: gradeId,
            googleEmail: googleEmail,
            googleName: googleName,
            googleImage: googleImage,
          );
        },
      ),

      // Main Navigation
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigationScreen(),
      ),

      // Home Routes
      GoRoute(
        path: '/home-screen',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/education-institutes',
        builder: (context, state) => const EducationInstitutesScreen(),
      ),
      GoRoute(
        path: '/schools',
        builder: (context, state) => const SchoolsScreen(),
      ),
      GoRoute(
        path: '/kindergartens',
        builder: (context, state) => const KindergartensScreen(),
      ),
      GoRoute(
        path: '/libraries',
        builder: (context, state) => const LibrariesScreen(),
      ),

      // Notes Routes
      GoRoute(
        path: '/notes',
        builder: (context, state) {
          var extra = state.extra as String?;
          var itemType = extra ?? 'مذكرات';
          return NotesScreen(itemType: itemType);
        },
      ),
      GoRoute(
        path: '/note-detail',
        builder: (context, state) {
          var itemId = state.extra as String;
          return NoteDetailScreen(itemId: itemId);
        },
      ),

      // Subscriptions Routes
      GoRoute(
        path: '/subscriptions',
        builder: (context, state) => const SubscriptionsScreen(),
      ),
      GoRoute(
        path: '/booking-details',
        builder: (context, state) {
          var order = state.extra as OrderCourseModel?;
          order ??= OrderCourseModel(
              id: int.tryParse(state.uri.queryParameters['id'] ?? ''));
          return BookingDetailScreen(
            order: order,
          );
        },
      ),
      // Clips Routes
      GoRoute(
        path: '/clips',
        builder: (context, state) => const ClipsScreen(),
      ),

      // Contact Routes
      GoRoute(
        path: '/contact',
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: '/invitations',
        builder: (context, state) => const InvitationsScreen(),
      ),
      GoRoute(
        path: '/room/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return RoomTimelineScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/call/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return CallsScreen(roomId: roomId);
        },
      ),

      // Menu Routes
      GoRoute(
        path: '/menu',
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: '/teacher-diagnostics',
        builder: (context, state) =>
            const TeacherDiagnosticsListScreen(),
      ),
      GoRoute(
        path: '/teacher-diagnostics/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TeacherDiagnosticDetailScreen(diagnosticId: id);
        },
      ),
      GoRoute(
        path: '/teacher-follow-ups',
        builder: (context, state) => const TeacherFollowUpsListScreen(),
      ),
      GoRoute(
        path: '/teacher-follow-ups/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TeacherFollowUpDetailScreen(followUpId: id);
        },
      ),

      // Profile Routes
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Settings Routes
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Notifications Routes
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // News Routes
      GoRoute(
        path: '/news',
        builder: (context, state) => const NewsScreen(),
      ),

      // Video Lessons Routes
      GoRoute(
        path: '/course-cards',
        builder: (context, state) {
          return const CourseCardsScreen();
        },
      ),
      GoRoute(
        path: '/course-details',
        builder: (context, state) {
          final course = state.extra as LearningCourseModel?;
          if (course == null) {
            // Return a placeholder or error screen if no course data
            return const Scaffold(
              body: Center(
                child: Text('Course data not found'),
              ),
            );
          }
          return CourseDetailsScreen(course: course);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/cart-payment',
        builder: (context, state) {
          return const cart_payment.CartPaymentScreen();
        },
      ),

      GoRoute(
        path: '/video-payment',
        builder: (context, state) {
          return const video_payment.PaymentScreen();
        },
      ),

      // Course Viewing Routes
      GoRoute(
        path: '/course-viewing',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final courseId = extras['courseId'] as String? ?? 'Course Title';
          return CourseViewingScreen(
            courseId: courseId,
          );
        },
      ),

      // Booking Routes
      GoRoute(
        path: '/lesson-details',
        builder: (context, state) {
          final offer = state.extra as OfferModel?;
          return LessonDetailsScreen(
            offer: offer,
          );
        },
      ),
      GoRoute(
        path: '/existing-customer-lesson',
        builder: (context, state) {
          final offer = state.extra as OfferModel?;
          return ExistingCustomerLessonScreen(
            offer: offer,
          );
        },
      ),
      GoRoute(
        path: '/institute-lesson-details',
        builder: (context, state) => const InstituteLessonDetailsScreen(),
      ),
      GoRoute(
        path: '/existing-customer-institute',
        builder: (context, state) => const ExistingCustomerInstituteScreen(),
      ),
      GoRoute(
        path: '/online-lesson-details',
        builder: (context, state) => const OnlineLessonDetailsScreen(),
      ),
      GoRoute(
        path: '/existing-customer-online',
        builder: (context, state) => const ExistingCustomerOnlineScreen(),
      ),
      GoRoute(
        path: '/booking-payment',
        builder: (context, state) => const booking_payment.PaymentScreen(),
      ),
      GoRoute(
        path: '/data-confirmation',
        builder: (context, state) => const DataConfirmationScreen(),
      ),
      GoRoute(
        path: '/address',
        builder: (context, state) => const AddressScreen(),
      ),
      GoRoute(
        path: '/existing-customer-online-confirmation',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final serviceType = extras['serviceType'] as String? ?? 'حصة خصوصية';
          final subject = extras['subject'] as String? ?? 'الرياضيات';
          final grade = extras['grade'] as String? ?? 'الصف التاسع';
          final date = extras['date'] as DateTime? ?? DateTime.now();
          final time = extras['time'] as TimeOfDay? ?? TimeOfDay.now();
          final duration = extras['duration'] as String? ?? '60 دقيقة';
          final price = extras['price'] as double? ?? 50.0;
          return ExistingCustomerOnlineConfirmationScreen(
            serviceType: serviceType,
            subject: subject,
            grade: grade,
            date: date,
            time: time,
            duration: duration,
            price: price,
          );
        },
      ),
      GoRoute(
        path: '/existing-customer-institute-confirmation',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final serviceType = extras['serviceType'] as String? ?? 'حصة خصوصية';
          final subject = extras['subject'] as String? ?? 'الرياضيات';
          final grade = extras['grade'] as String? ?? 'الصف التاسع';
          final date = extras['date'] as DateTime? ?? DateTime.now();
          final time = extras['time'] as TimeOfDay? ?? TimeOfDay.now();
          final duration = extras['duration'] as String? ?? '60 دقيقة';
          final price = extras['price'] as double? ?? 50.0;
          return ExistingCustomerInstituteConfirmationScreen(
            serviceType: serviceType,
            subject: subject,
            grade: grade,
            date: date,
            time: time,
            duration: duration,
            price: price,
          );
        },
      ),
      GoRoute(
        path: '/institute-booking-summary',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final serviceType = extras['serviceType'] as String? ?? 'حصة خصوصية';
          final subject = extras['subject'] as String? ?? 'الرياضيات';
          final grade = extras['grade'] as String? ?? 'الصف التاسع';
          final date = extras['date'] as DateTime? ?? DateTime.now();
          final time = extras['time'] as TimeOfDay? ?? TimeOfDay.now();
          final duration = extras['duration'] as String? ?? '60 دقيقة';
          final price = extras['price'] as double? ?? 50.0;
          return InstituteBookingSummaryScreen(
            serviceType: serviceType,
            subject: subject,
            grade: grade,
            date: date,
            time: time,
            duration: duration,
            price: price,
          );
        },
      ),
      GoRoute(
        path: '/booking-summary',
        builder: (context, state) => const BookingSummaryScreen(),
      ),
      GoRoute(
        path: '/online-booking-summary',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          final serviceType = extras['serviceType'] as String? ?? 'حصة خصوصية';
          final subject = extras['subject'] as String? ?? 'الرياضيات';
          final grade = extras['grade'] as String? ?? 'الصف التاسع';
          final date = extras['date'] as DateTime? ?? DateTime.now();
          final time = extras['time'] as TimeOfDay? ?? TimeOfDay.now();
          final duration = extras['duration'] as String? ?? '60 دقيقة';
          final price = extras['price'] as double? ?? 50.0;
          return OnlineBookingSummaryScreen(
            serviceType: serviceType,
            subject: subject,
            grade: grade,
            date: date,
            time: time,
            duration: duration,
            price: price,
          );
        },
      ),

      // Menu Feature Routes
      GoRoute(
        path: '/offers',
        builder: (context, state) => const OffersScreen(),
      ),

      GoRoute(
        path: '/teachers',
        builder: (context, state) => const TeachersScreen(),
      ),
      GoRoute(
        path: '/files',
        builder: (context, state) => const FilesScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/invite-friends',
        builder: (context, state) => const InviteFriendsScreen(),
      ),
      GoRoute(
        path: '/share-app',
        builder: (context, state) => const ShareAppScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/exams',
        builder: (context, state) => const ExamsScreen(),
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/live-stream',
        builder: (context, state) => const LiveStreamScreen(),
      ),
      GoRoute(
        path: '/help-support',
        builder: (context, state) => const HelpSupportScreen(),
      ),

      // WebView Route
      GoRoute(
        path: '/webview',
        builder: (context, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          final title = state.uri.queryParameters['title'];
          final imagesParam = state.uri.queryParameters['images'];

          List<String>? images;
          if (imagesParam != null && imagesParam.isNotEmpty) {
            try {
              final decoded = Uri.decodeComponent(imagesParam);
              final imagesList = decoded.split(',');
              images = imagesList.where((img) => img.isNotEmpty).toList();
            } catch (e) {
              debugPrint('Error parsing images parameter: $e');
            }
          }

          if (url.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: Text('webview.error'.tr())),
              body: Center(
                child: Text('webview.invalid_url'.tr()),
              ),
            );
          }

          return WebViewScreen(
            url: url,
            title: title,
            images: images,
          );
        },
      ),
    ],
  );
});
