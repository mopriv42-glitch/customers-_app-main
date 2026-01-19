import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/learning_course_model.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/features/subscriptions/widgets/course_card.dart';

class UpcomingPackagesWidget extends ConsumerStatefulWidget {
  const UpcomingPackagesWidget({super.key});

  @override
  ConsumerState<UpcomingPackagesWidget> createState() =>
      _UpcomingPackagesWidgetState();
}

class _UpcomingPackagesWidgetState
    extends ConsumerState<UpcomingPackagesWidget> {
  List<LearningCourseModel> upcomingPackages = [];

  @override
  void initState() {
    super.initState();
    // Initialize booking data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ApiProviders.subscriptionsProvider).getUpcomingPackages(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsProvider = ref.watch(ApiProviders.subscriptionsProvider);
    bool isLoading = subscriptionsProvider.isLoading;
    // Update the lists when data is loaded
    if (!isLoading) {
      upcomingPackages = subscriptionsProvider.upcomingPackagesList;
    }
    return isLoading
        ? CommonComponents.loadingDataFromServer()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'دوراتي',
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
                  itemCount: upcomingPackages.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Enable scrolling
                  itemBuilder: (BuildContext context, int index) {
                    var course = upcomingPackages[index];
                    return CourseCard(
                      course: course,
                    );
                  },
                ),
              ),
            ],
          );
  }
}
