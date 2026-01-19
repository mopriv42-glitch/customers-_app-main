import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/features/subscriptions/widgets/end_subscripations_widget.dart';
import 'package:private_4t_app/features/subscriptions/widgets/upcoming_courses_widget.dart';
import 'package:private_4t_app/features/subscriptions/widgets/upcoming_orders_widget.dart';
import 'package:private_4t_app/features/subscriptions/widgets/upcoming_packages_widget.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'Subscriptionsscreen';
  
  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'حصصي القادمة',
    'باقات الحصص',
    // 'دوراتي',
    'اشتراكاتي المنتهية',
  ];

  @override
  Widget build(BuildContext context) {
    Future<void> implementRefresh() async {
      switch (_selectedFilterIndex) {
        case 0:
          await ref
              .read(ApiProviders.subscriptionsProvider)
              .getUpcomingOrders(context);
          break;
        case 1:
          await ref
              .read(ApiProviders.subscriptionsProvider)
              .getUpcomingCourses(context);
          break;
        case 2:
          // await ref
          //     .read(ApiProviders.subscriptionsProvider)
          //     .getUpcomingPackages(context);
          await ref
              .read(ApiProviders.subscriptionsProvider)
              .getEndSubscriptions(context);
          break;
        case 3:
          await ref
              .read(ApiProviders.subscriptionsProvider)
              .getEndSubscriptions(context);
          break;
        default:
          break;
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'اشتراكاتي',
          showBackButton: false,
          showLogo: true,
        ),
        body: Column(
          children: [
            _buildFilterTabs(),
            Expanded(
              // ✅ لفينا RefreshIndicator هنا
              child: RefreshIndicator(
                onRefresh: () async {
                  await implementRefresh();
                },
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 28.h,
      margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      child: Row(
        children: _filters.asMap().entries.map((entry) {
          final index = entry.key;
          final filter = entry.value;
          final isSelected = index == _selectedFilterIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                logButtonClick('subscriptions_filter_tab', data: {
                  'filter_index': index,
                  'filter_name': filter,
                });
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 1.w),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isSelected ? context.primary : context.surface,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isSelected
                        ? context.primary
                        : context.secondary.withOpacity(0.15),
                    width: 0.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: context.primary.withOpacity(0.12),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    filter,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? context.textOnPrimary
                          : context.primaryText,
                      fontSize: 8.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedFilterIndex) {
      case 0:
        return const UpcomingOrdersWidget();
      case 1:
        return const UpcomingCoursesWidget();
      case 2:
        // return const UpcomingPackagesWidget();
        return const EndSubscriptionsWidget();
      case 3:
        return const EndSubscriptionsWidget();
      default:
        return const SizedBox.shrink();
    }
  }
}
