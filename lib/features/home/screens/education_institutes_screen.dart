import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/models/lib_item_model.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:riverpod_context/riverpod_context.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class EducationInstitutesScreen extends ConsumerStatefulWidget {
  const EducationInstitutesScreen({super.key});

  @override
  ConsumerState<EducationInstitutesScreen> createState() =>
      _EducationInstitutesScreenState();
}

class _EducationInstitutesScreenState
    extends ConsumerState<EducationInstitutesScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'EducationInstitutesscreen';
  
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(ApiProviders.libraryProvider).getEducationInstitutes(context));
  }

  @override
  Widget build(BuildContext context) {
    final lib = ref.watch(ApiProviders.libraryProvider);
    final items = lib.educationInstitutesList;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'معاهد تعليمية',
          showCart: false,
          showProfile: false,
          showNotifications: false,
          showBackButton: true,
        ),
        body: lib.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _IntituteCard(sub: items[index]),
                  ),
                ),
              ),
      ),
    );
  }
}

class _IntituteCard extends StatelessWidget {
  final LibItemModel sub;
  const _IntituteCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: sub.subSection?.thumbnail == null
                    ? Container(color: context.background)
                    : Image.network(sub.subSection?.thumbnail.toString() ?? '',
                        fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              sub.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: context.primaryText),
            ),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: () {
                bool isExistingCustomer = context
                    .read(ApiProviders.loginProvider)
                    .loggedUser!
                    .isExistingCustomer;

                if (isExistingCustomer) {
                  context.push('/existing-customer-institute');
                } else {
                  context.push('/institute-lesson-details');
                }
              },
              child: const Text('احجز حصتك الخاصة'),
            ),
          ],
        ),
      ),
    );
  }
}
