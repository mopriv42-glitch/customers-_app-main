import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/order_course_model.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/features/subscriptions/widgets/class_card.dart';

class UpcomingCoursesWidget extends ConsumerStatefulWidget {
  const UpcomingCoursesWidget({super.key});

  @override
  ConsumerState<UpcomingCoursesWidget> createState() =>
      _UpcomingCoursesWidgetState();
}

class _UpcomingCoursesWidgetState extends ConsumerState<UpcomingCoursesWidget> {
  List<OrderCourseModel> upcomingCourses = [];

  @override
  void initState() {
    super.initState();
    // Initialize booking data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ApiProviders.subscriptionsProvider).getUpcomingCourses(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsProvider = ref.watch(ApiProviders.subscriptionsProvider);
    bool isLoading = subscriptionsProvider.isLoading;
    // Update the lists when data is loaded
    if (!isLoading) {
      upcomingCourses = subscriptionsProvider.upcomingCoursesList;
    }
    return isLoading
        ? CommonComponents.loadingDataFromServer()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'باقات الحصص',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: context.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6.h),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  itemCount: upcomingCourses.length,
                  shrinkWrap: true,
                  // ضروري داخل Column
                  physics: const NeverScrollableScrollPhysics(),
                  // منع التمرير الداخلي
                  itemBuilder: (BuildContext context, int index) {
                    var order = upcomingCourses[index];
                    return ClassCard(
                      orderCourseModel: order,
                      isCourse: true,
                    );
                  },
                ),
              ),
            ],
          );
  }
}
