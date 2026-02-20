import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/order_course_model.dart';
import 'package:private_4t_app/core/models/our_teachers_model.dart';
import 'package:private_4t_app/core/providers/dashboard_providers/home_provider.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/widgets/optimized_cached_image.dart';
import 'package:private_4t_app/features/home/widgets/animated_tools_card.dart';
import 'package:private_4t_app/features/home/widgets/educational_services_cards.dart';
import 'package:private_4t_app/features/home/widgets/offer_slider_card.dart';
import 'package:private_4t_app/features/subscriptions/widgets/class_card.dart';
import 'package:riverpod_context/riverpod_context.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with AnalyticsScreenMixin {
  late HomeProvider homeProvider;

  @override
  String get screenName => 'HomeScreen';

  @override
  void initState() {
    super.initState();
    homeProvider = ref.read(ApiProviders.homeProvider);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      homeProvider.fetchDashboard(context);

      // تهيئة السلة
      final cartProvider = ref.read(ApiProviders.cartProvider);
      cartProvider.getCart(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure RTL layout
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'Private 4T',
          showBackButton: false,
          showLogo: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTagline(),
              SizedBox(height: 16.h),
              _buildPromoCards(),
              SizedBox(height: 24.h),
              _buildWhatDoYouNeedSection(),
              SizedBox(height: 24.h),
              _buildStatsSection(),
              SizedBox(height: 24.h),
              // _buildVideoLessons(),
              // SizedBox(height: 24.h),
              _buildUpcomingSessions(),
              SizedBox(height: 24.h),
              // _buildToolsSection(),
              // SizedBox(height: 24.h),
              // _buildEducationalServicesSection(),
              // SizedBox(height: 24.h),
              _buildTeachersSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return Text(
      'حصص ولدك خلها علينا',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: context.primaryText,
      ),
    );
  }

  Widget _buildPromoCards() {
    // Placeholder horizontal list of promo cards
    return SizedBox(
      height: 200.h, // Increased height to accommodate the new card design
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: homeProvider.offers.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (_, index) {
          final offer = homeProvider.offers[index];
          return OfferSliderCard(
            offer: offer,
            onTap: () {
              bool isExistingCustomer = context
                  .read(ApiProviders.loginProvider)
                  .loggedUser!
                  .isExistingCustomer;

              if (isExistingCustomer) {
                context.push('/existing-customer-lesson', extra: offer);
              } else {
                context.push('/lesson-details', extra: offer);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildWhatDoYouNeedSection() {
    const options = [
      'حصة بالبيت',
      'حصة بالمعهد',
      'حصة أونلاين',
      // 'شروحات فيديو',
    ];
    const icons = [
      Icons.home_filled,
      Icons.school,
      Icons.laptop_mac,
      Icons.play_circle_fill,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ماذا تريد؟',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: context.primaryText,
          ),
        ),
        SizedBox(height: 8.h),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1.3,
          ),
          itemBuilder: (_, index) =>
              _OptionCard(label: options[index], icon: icons[index]),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final home = ref.watch(ApiProviders.homeProvider);
    final stats = home.stats ?? const {};
    final tiles = <Map<String, dynamic>>[
      {
        'value': '${stats['teachers_count'] ?? '-'}',
        'label': 'مدرس ومدرسة',
        'iconColor': context.secondary,
      },
      {
        'value': '${stats['customer_count'] ?? '-'}',
        'label': 'طالب وطالبة وثقوا فينا',
        'iconColor': context.primary,
      },
      {
        'value': '${stats['orders_count'] ?? '-'}',
        'label': 'طلبات/حصص',
        'iconColor': context.accentSecondary,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إحصائيات المنصة',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: context.primaryText,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: tiles.map((e) => _StatCard(data: e)).toList(),
        ),
      ],
    );
  }

  Widget _buildVideoLessons() {
    return const _SectionPlaceholder(title: 'شروحات مبسطة لدروسك');
  }

  Widget _buildUpcomingSessions() {
    final home = ref.watch(ApiProviders.homeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حصصك القادمة',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: context.primaryText,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: context.secondary.withOpacity(0.2)),
          ),
          child: home.isLoading
              ? const Center(child: CircularProgressIndicator())
              : (home.error != null)
                  ? Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Text(
                        home.error!,
                        style: TextStyle(color: context.error, fontSize: 12.sp),
                      ),
                    )
                  : _buildUpcomingList(home.upcomingOrders),
        ),
      ],
    );
  }

  Widget _buildUpcomingList(List<OrderCourseModel> items) {
    if (items.isEmpty) {
      return SizedBox(
        height: 80.h,
        child: const Center(child: Text('لا يوجد حجوزات قادمة')),
      );
    }
    return SizedBox(
      height: 280.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 325.w,
            child: ClassCard(orderCourseModel: items[index], compact: true),
          );
        },
      ),
    );
  }

  Widget _buildToolsSection() {
    return const ToolsSection();
  }

  Widget _buildEducationalServicesSection() {
    return const EducationalServicesSection();
  }

  Widget _buildTeachersSection() {
    final home = ref.watch(ApiProviders.homeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تعرف على مدرسينا',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: context.primaryText,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          height: 280.h,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
          child: home.isLoading
              ? const Center(child: CircularProgressIndicator())
              : home.teachers.isEmpty
                  ? _buildNoTeachers()
                  : _buildTeachersCarousel(home.teachers),
        ),
      ],
    );
  }

  Widget _buildTeachersError(String error) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: context.error, size: 48.sp),
            SizedBox(height: 12.h),
            Text(
              'خطأ في تحميل بيانات المدرسين',
              style: TextStyle(
                color: context.error,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              style: TextStyle(color: context.secondaryText, fontSize: 12.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () =>
                  ref.read(ApiProviders.homeProvider).fetchOurTeachers(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTeachers() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              color: context.secondaryText,
              size: 48.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              'لا يوجد مدرسين متاحين حالياً',
              style: TextStyle(color: context.secondaryText, fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeachersCarousel(List<OurTeacher> teachers) {
    return _AutoScrollingTeachersCarousel(teachers: teachers);
  }
}

/* ---------------- Helper widgets ---------------- */
class _OptionCard extends StatelessWidget {
  final String label;
  final IconData icon;

  const _OptionCard({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Log button tap
        context.findAncestorStateOfType<_HomeScreenState>()?.logButtonClick(
          'option_card_$label',
          data: {'option': label},
        );
        _handleOptionTap(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: context.secondary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32.sp, color: context.accentSecondary),
              SizedBox(height: 8.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.primaryText, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleOptionTap(BuildContext context) {
    bool isExistingCustomer =
        context.read(ApiProviders.loginProvider).loggedUser!.isExistingCustomer;

    switch (label) {
      case 'حصة بالبيت':
        context.findAncestorStateOfType<_HomeScreenState>()?.logButtonClick(
          'home_lesson',
          data: {'type': 'حصة بالبيت', 'is_existing': isExistingCustomer},
        );
        if (isExistingCustomer) {
          context.push('/existing-customer-lesson');
        } else {
          context.push('/lesson-details');
        }
        break;
      case 'حصة بالمعهد':
        context.findAncestorStateOfType<_HomeScreenState>()?.logButtonClick(
          'institute_lesson',
          data: {'type': 'حصة بالمعهد', 'is_existing': isExistingCustomer},
        );
        if (isExistingCustomer) {
          context.push('/existing-customer-institute');
        } else {
          context.push('/institute-lesson-details');
        }
        break;
      case 'حصة أونلاين':
        context.findAncestorStateOfType<_HomeScreenState>()?.logButtonClick(
          'online_lesson',
          data: {'type': 'حصة أونلاين', 'is_existing': isExistingCustomer},
        );
        if (isExistingCustomer) {
          context.push('/existing-customer-online');
        } else {
          context.push('/online-lesson-details');
        }
        break;
      case 'شروحات فيديو':
        context.findAncestorStateOfType<_HomeScreenState>()?.logButtonClick(
          'video_lessons',
          data: {'type': 'شروحات فيديو'},
        );
        context.push('/course-cards');
        break;
    }
  }
}

class _StatCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: context.secondary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 16.r,
              backgroundColor: data['iconColor'] as Color,
              child: const Icon(Icons.menu_book, color: Colors.white, size: 18),
            ),
            SizedBox(height: 8.h),
            Text(
              data['value'] as String,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: context.primaryText,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              data['label'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: context.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  final String title;

  const _SectionPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: context.primaryText,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 100.h,
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: context.secondary.withOpacity(0.2)),
          ),
          child: Center(
            child: Text(
              'قريباً',
              style: TextStyle(color: context.secondaryText),
            ),
          ),
        ),
      ],
    );
  }
}

/* ---------------- Auto-Scrolling Teachers Carousel Widget ---------------- */
class _AutoScrollingTeachersCarousel extends StatefulWidget {
  final List<OurTeacher> teachers;

  const _AutoScrollingTeachersCarousel({required this.teachers});

  @override
  State<_AutoScrollingTeachersCarousel> createState() =>
      _AutoScrollingTeachersCarouselState();
}

class _AutoScrollingTeachersCarouselState
    extends State<_AutoScrollingTeachersCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  late List<OurTeacher> _infiniteTeachers;

  @override
  void initState() {
    super.initState();

    // Create infinite list by repeating teachers
    _infiniteTeachers = List.generate(
      widget.teachers.length * 1000, // Large number for infinite effect
      (index) => widget.teachers[index % widget.teachers.length],
    );

    // Start from middle to allow scrolling both ways
    _currentPage = (_infiniteTeachers.length / 2).floor();
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.85, // Show part of next/previous cards
    );

    // Auto-scroll every 3 seconds
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _pageController.hasClients) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        _startAutoScroll(); // Continue auto-scrolling
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemCount: _infiniteTeachers.length,
      itemBuilder: (context, index) {
        final teacher = _infiniteTeachers[index];
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          child: _TeacherCard(teacher: teacher),
        );
      },
    );
  }
}

/* ---------------- Teacher Card Widget ---------------- */
class _TeacherCard extends StatelessWidget {
  final OurTeacher teacher;

  const _TeacherCard({required this.teacher});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.secondary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher Image
          Container(
            width: 300.w,
            height: 150.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              color: context.secondary.withOpacity(0.1),
            ),
            child: teacher.ourTeacherImage?.url != null
                ? OptimizedCachedImage(
              imageUrl: teacher.ourTeacherImage!.url!,
              fit: BoxFit.cover,
              errorWidget: Container(
                color: context.secondary.withOpacity(0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 48.sp,
                      color: context.secondaryText,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'صورة المدرس',
                      style: TextStyle(
                        color: context.secondaryText,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : Container(
              color: context.secondary.withOpacity(0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: 48.sp,
                    color: context.secondaryText,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'صورة المدرس',
                    style: TextStyle(
                      color: context.secondaryText,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Teacher Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Teacher Name
                  Text(
                    teacher.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: context.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),

                  // Teacher Description
                  Expanded(
                    child: Text(
                      teacher.body,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: context.secondaryText,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
