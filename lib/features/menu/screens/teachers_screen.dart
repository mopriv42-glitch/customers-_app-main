import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/features/teachers/widgets/teacher_card.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class TeachersScreen extends ConsumerStatefulWidget {
  const TeachersScreen({super.key});

  @override
  ConsumerState<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends ConsumerState<TeachersScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'Teachersscreen';
  
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ApiProviders.teachersProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final teachersProvider = ref.watch(ApiProviders.teachersProvider);
    final isLoading = teachersProvider.isLoading;
    final teachers = teachersProvider.teachersList;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const AppHeader(
          title: "مدرسينك",
          showBackButton: true,
          showLogo: false,
        ),
        backgroundColor: context.background,
        body: SafeArea(
          child: isLoading
              ? CommonComponents.loadingDataFromServer(color: context.primary)
              : ListView.builder(
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];

                    return TeacherCard(
                      teacher: teacher,
                      onContact: teacher.matrixRoomId != null &&
                              teacher.matrixRoomId!.isNotEmpty
                          ? () => NavigationService.navigateToRoomTimeline(
                              context, teacher.matrixRoomId!)
                          : () => CommonComponents.showCustomizedSnackBar(
                              context: context,
                              title: "المراسلة غير متاحة حالياً مع هذا المدرس"),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
