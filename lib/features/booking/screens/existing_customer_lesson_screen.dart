import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/customer_booking_model.dart';
import 'package:private_4t_app/core/models/grade_model.dart';
import 'package:private_4t_app/core/models/offer_model.dart';
import 'package:private_4t_app/core/models/service_type_model.dart';
import 'package:private_4t_app/core/models/subject_model.dart';
import 'package:private_4t_app/core/models/user_model.dart';
import 'package:private_4t_app/core/widgets/price_display_widget.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class ExistingCustomerLessonScreen extends ConsumerStatefulWidget {
  final OfferModel? offer;

  const ExistingCustomerLessonScreen({
    super.key,
    this.offer,
  });

  @override
  ConsumerState<ExistingCustomerLessonScreen> createState() =>
      _ExistingCustomerLessonScreenState();
}

class _ExistingCustomerLessonScreenState
    extends ConsumerState<ExistingCustomerLessonScreen>
    with AnalyticsScreenMixin {
  @override
  String get screenName => 'ExistingCustomerLessonScreen';

  String selectedServiceType = 'حصة في المنزل';
  String selectedSubject = '';
  String selectedGrade = '';
  String selectedDate = '';
  String selectedTime = '';
  String selectedAltTime = ''; // وقت ثاني احتياطي للحصة
  String selectedDuration = '';
  int selectedTeacherType = 1; // Default: مدرس
  int selectedSchool = 1; // Default: مدارس عربية
  String purposeOfReservation = '';
  late UserModel? loggedUser;
  CustomerBookingModel customerBooking = CustomerBookingModel.init();
  final TextEditingController purposeController = TextEditingController();
  int? calculatedPrice;

  List<ServiceTypeModel> serviceTypes = [];
  List<GradeModel> grades = [];
  List<GradeModel> filteredGrades = [];
  List<SubjectModel> subjects = [];

  OfferModel? currentOffer;
  bool hasOffer = false;

  final List<String> durations = ['ساعة ونصف', 'ساعتين'];

  @override
  void dispose() {
    purposeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    currentOffer = widget.offer;
    hasOffer = currentOffer != null;

    // قيم أولية حسب العرض أو الحجز الأخير
    if (hasOffer && currentOffer != null) {
      selectedDuration = currentOffer!.hours == 1.5 ? "ساعة ونص" : 'ساعتين';
      customerBooking.offerId = currentOffer?.id;
      customerBooking.price = currentOffer?.price;
      customerBooking.numberOfHours = currentOffer?.hours ?? 2.0;
    } else {
      selectedDuration = customerBooking.numberOfHoursFormatted;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(ApiProviders.bookingProvider)
          .getLastBooking(context, widget.offer);

      setState(() {
        final bookingProvider = ref.read(ApiProviders.bookingProvider);

        serviceTypes = bookingProvider.serviceTypesList;
        subjects = bookingProvider.subjectsList;
        grades = bookingProvider.gradesList;

        if (hasOffer && currentOffer != null) {
          filteredGrades = grades
              .where((grade) => grade.educationId == currentOffer!.educationId)
              .toList();

          selectedSubject = subjects.firstOrNull?.subject ?? selectedSubject;
          selectedGrade = filteredGrades.firstOrNull?.grade ?? selectedGrade;

          customerBooking.gradeId =
              filteredGrades.firstOrNull?.id ?? customerBooking.gradeId;
          customerBooking.subjectId =
              subjects.firstOrNull?.id ?? customerBooking.subjectId;
        } else {
          customerBooking = bookingProvider.customerBooking;
          // Filter grades based on school selection
          _updateFilteredGrades();
          selectedSubject = customerBooking.subject?.subject ??
              subjects.firstOrNull?.subject ??
              '';
          selectedGrade = customerBooking.grade?.grade ??
              filteredGrades.firstOrNull?.grade ??
              '';
          selectedDuration = customerBooking.numberOfHoursFormatted;
          selectedSchool = customerBooking.school ?? 1;
        }

        if (selectedGrade.isNotEmpty && filteredGrades.isNotEmpty) {
          final selectedGradeModel = filteredGrades.firstWhere(
              (g) => g.grade == selectedGrade,
              orElse: () => filteredGrades.first);
          customerBooking.gradeId = selectedGradeModel.id ?? 0;
        } else {
          customerBooking.gradeId = filteredGrades.firstOrNull?.id ?? 0;
        }

        if (selectedSubject.isNotEmpty && subjects.isNotEmpty) {
          final selectedSubjectModel = subjects.firstWhere(
              (s) => s.subject == selectedSubject,
              orElse: () => subjects.first);
          customerBooking.subjectId = selectedSubjectModel.id ?? 0;
        } else {
          customerBooking.subjectId = subjects.firstOrNull?.id ?? 0;
        }
        customerBooking.serviceTypeId = serviceTypes.firstOrNull?.id ?? 1;
        customerBooking.serviceType = serviceTypes.firstOrNull;
        customerBooking.teacherType = selectedTeacherType;
        customerBooking.school = selectedSchool;
      });

      // Calculate price after booking data is loaded
      if (mounted && _canShowPrice()) {
        _calculatePrice();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = ref.watch(ApiProviders.bookingProvider);
    bool isLoading = bookingProvider.isLoading;
    loggedUser = ref.watch(ApiProviders.loginProvider).loggedUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        body: SafeArea(
          child: isLoading
              ? CommonComponents.loadingDataFromServer()
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildBody()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: context.accent.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon:
                    Icon(Icons.arrow_back, color: context.primary, size: 24.sp),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(
                  'حجز حصتك بالبيت',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: context.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // IconButton(
              //   icon: Icon(Icons.shopping_cart,
              //       color: context.primary, size: 24.sp),
              //   onPressed: () {},
              // ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'هلا ${loggedUser?.name}😊',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'بيانات اخر حصة لك عدل اللي تحتاجه واضغط التالي',
            style: TextStyle(
              fontSize: 14.sp,
              color: context.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: context.accentSecondary,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                height: 4.h,
                width: 40.w,
                decoration: BoxDecoration(
                  color: context.secondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: context.accentSecondary,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '1/2',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          if (hasOffer && currentOffer != null) ...[
            _buildOfferCard(),
            SizedBox(height: 20.h),
          ],
          _buildFormCard(),
          SizedBox(height: 20.h),
// عرض السعر
          if (_canShowPrice()) ...[
            SizedBox(height: 24.h),
            _buildPriceDisplay(),
          ],
          SizedBox(height: 32.h),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16.r),
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
          // if (!hasOffer) ...[
          //   _buildServiceTypeDropdown(),
          //   SizedBox(height: 20.h),
          // ],
          if (!hasOffer && currentOffer == null) ...[
            _buildSchoolDropdown(),
            SizedBox(height: 20.h),
          ],
          _buildSubjectDropdown(),
          SizedBox(height: 20.h),
          _buildGradeDropdown(),
          SizedBox(height: 20.h),
          _buildDateField(),
          SizedBox(height: 20.h),
          _buildTimeField(),
          SizedBox(height: 20.h),
          _buildTeacherTypeDropdown(),
          SizedBox(height: 20.h),
          if (!hasOffer && currentOffer == null) ...[
            _buildDurationDropdown(),
            SizedBox(height: 20.h),
          ],
          _buildPurposeField(),
        ],
      ),
    );
  }

  Widget _buildServiceTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الخدمة',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.primary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _showServiceTypeDialog(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit,
                  size: 20.sp,
                  color: context.accentSecondary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    selectedServiceType,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.primaryText,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20.sp,
                  color: context.secondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المادة',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.primary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _showSubjectDialog(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.book,
                  size: 20.sp,
                  color: context.accentSecondary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    selectedSubject,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.primaryText,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20.sp,
                  color: context.secondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الصف',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.primary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _showGradeDialog(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school,
                  size: 20.sp,
                  color: context.accentSecondary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    selectedGrade,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.primaryText,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20.sp,
                  color: context.secondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مدة الحصة',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.primary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _showDurationDialog(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20.sp,
                  color: context.accentSecondary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    selectedDuration,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.primaryText,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20.sp,
                  color: context.secondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التاريخ',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.primary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20.sp,
                  color: context.accentSecondary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    selectedDate,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'وقت الحصة',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.primary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _selectTime(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20.sp,
                  color: context.accentSecondary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    selectedTime.isEmpty ? 'اختر الوقت' : selectedTime,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: selectedTime.isEmpty
                          ? context.secondaryText
                          : context.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'وقت بديل للحصة',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.primary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _selectAltTime(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20.sp,
                  color: context.accentSecondary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    selectedAltTime.isEmpty
                        ? 'اختر الوقت البديل (اختياري)'
                        : selectedAltTime,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: selectedAltTime.isEmpty
                          ? context.secondaryText
                          : context.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع المدرس',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.primary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _showTeacherTypeDialog(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  size: 20.sp,
                  color: context.accentSecondary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    selectedTeacherType == 1 ? 'مدرس' : 'مدرسة',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.primaryText,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20.sp,
                  color: context.secondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المدرسة',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.primary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _showSchoolDialog(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school,
                  size: 20.sp,
                  color: context.accentSecondary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    selectedSchool == 1
                        ? 'مدارس عربية'
                        : selectedSchool == 2
                            ? 'مدارس أجنبية'
                            : 'جامعات',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.primaryText,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20.sp,
                  color: context.secondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurposeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الغرض من الحجز',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.primary,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: purposeController,
          onChanged: (value) {
            setState(() {
              purposeOfReservation = value;
              customerBooking.purposeOfReservation = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'أدخل الغرض من الحجز',
            hintStyle: TextStyle(
              fontSize: 14.sp,
              color: context.secondaryText,
            ),
            filled: true,
            fillColor: context.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: context.secondary.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: context.secondary.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: context.primary,
              ),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
          style: TextStyle(
            fontSize: 14.sp,
            color: context.primaryText,
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    final isFormComplete = selectedServiceType.isNotEmpty &&
        selectedSubject.isNotEmpty &&
        selectedGrade.isNotEmpty &&
        selectedDate.isNotEmpty &&
        selectedTime.isNotEmpty &&
        selectedDuration.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isFormComplete ? _navigateToDataConfirmation : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.secondary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: Text(
          'التالي',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showServiceTypeDialog(BuildContext context) {
    if (serviceTypes.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر نوع الخدمة'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: serviceTypes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(serviceTypes[index].serviceType ?? ''),
                  onTap: () {
                    setState(() {
                      selectedServiceType =
                          serviceTypes[index].serviceType ?? '';
                      customerBooking.serviceType = serviceTypes[index];
                      customerBooking.serviceTypeId =
                          serviceTypes[index].id ?? 0;
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showSubjectDialog(BuildContext context) {
    if (subjects.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر المادة'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(subjects[index].subject ?? ''),
                  onTap: () {
                    setState(() {
                      selectedSubject = subjects[index].subject ?? '';
                      customerBooking.subject = subjects[index];
                      customerBooking.subjectId = subjects[index].id ?? 0;
                      calculatedPrice = null; // Reset price to recalculate
                    });
                    Navigator.of(context).pop();
                    _calculatePrice();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showGradeDialog(BuildContext context) {
    if (filteredGrades.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(hasOffer ? 'اختر الصف (عرض خاص)' : 'اختر الصف'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredGrades.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(filteredGrades[index].grade ?? ''),
                  onTap: () {
                    setState(() {
                      selectedGrade = filteredGrades[index].grade ?? '';
                      customerBooking.grade = filteredGrades[index];
                      customerBooking.gradeId = filteredGrades[index].id ?? 0;
                      calculatedPrice = null; // Reset price to recalculate
                    });
                    Navigator.of(context).pop();
                    _calculatePrice();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showDurationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر مدة الحصة'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: durations.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(durations[index]),
                  onTap: () {
                    setState(() {
                      selectedDuration = durations[index];
                      switch (durations.indexOf(durations[index])) {
                        case 0:
                          customerBooking.numberOfHours = 1.5;
                          break;
                        case 1:
                        default:
                          customerBooking.numberOfHours = 2;
                          break;
                      }
                      calculatedPrice = null; // Reset price to recalculate
                    });
                    Navigator.of(context).pop();
                    _calculatePrice();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showTeacherTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر نوع المدرس'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('مدرس'),
                  onTap: () {
                    setState(() {
                      selectedTeacherType = 1;
                      customerBooking.teacherType = 1;
                      calculatedPrice = null; // Reset price to recalculate
                    });
                    Navigator.of(context).pop();
                    _calculatePrice();
                  },
                ),
                ListTile(
                  title: const Text('مدرسة'),
                  onTap: () {
                    setState(() {
                      selectedTeacherType = 2;
                      customerBooking.teacherType = 2;
                      calculatedPrice = null; // Reset price to recalculate
                    });
                    Navigator.of(context).pop();
                    _calculatePrice();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSchoolDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر المدرسة'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('مدارس عربية'),
                  onTap: () {
                    setState(() {
                      selectedSchool = 1;
                      customerBooking.school = 1;
                      _updateFilteredGrades();
                      // Reset grade if current selection is not in filtered list
                      if (filteredGrades.isNotEmpty &&
                          !filteredGrades
                              .any((g) => g.id == customerBooking.gradeId)) {
                        selectedGrade = '';
                        customerBooking.gradeId = 0;
                        customerBooking.grade = null;
                      }
                      calculatedPrice = null; // Reset price to recalculate
                    });
                    Navigator.of(context).pop();
                    _calculatePrice();
                  },
                ),
                ListTile(
                  title: const Text('مدارس أجنبية'),
                  onTap: () {
                    setState(() {
                      selectedSchool = 2;
                      customerBooking.school = 2;
                      _updateFilteredGrades();
                      // Reset grade if current selection is not in filtered list
                      if (filteredGrades.isNotEmpty &&
                          !filteredGrades
                              .any((g) => g.id == customerBooking.gradeId)) {
                        selectedGrade = '';
                        customerBooking.gradeId = 0;
                        customerBooking.grade = null;
                      }
                      calculatedPrice = null; // Reset price to recalculate
                    });
                    Navigator.of(context).pop();
                    _calculatePrice();
                  },
                ),
                ListTile(
                  title: const Text('جامعات'),
                  onTap: () {
                    setState(() {
                      selectedSchool = 3;
                      customerBooking.school = 3;
                      _updateFilteredGrades();
                      // Reset grade if current selection is not in filtered list
                      if (filteredGrades.isNotEmpty &&
                          !filteredGrades
                              .any((g) => g.id == customerBooking.gradeId)) {
                        selectedGrade = '';
                        customerBooking.gradeId = 0;
                        customerBooking.grade = null;
                      }
                      calculatedPrice = null; // Reset price to recalculate
                    });
                    Navigator.of(context).pop();
                    _calculatePrice();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateFilteredGrades() {
    if (selectedSchool == 1 || selectedSchool == 2) {
      // Show grades with IDs 1-12
      filteredGrades = grades.where((grade) {
        final gradeId = grade.id ?? 0;
        return gradeId >= 1 && gradeId <= 12;
      }).toList();
    } else if (selectedSchool == 3) {
      // Show grades with ID > 12
      filteredGrades = grades.where((grade) {
        final gradeId = grade.id ?? 0;
        return gradeId > 12;
      }).toList();
    } else {
      filteredGrades = grades;
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        selectedDate =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        debugPrint("d: ${picked.toIso8601String()}");
        customerBooking.bookingDate = picked;
      });
    }
  }

  void _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false,
          ),
          child: TimePickerDialog(
            initialTime: TimeOfDay.now(),
            helpText: 'اختر الوقت',
            hourLabelText: 'ساعة',
            minuteLabelText: 'دقيقة',
            cancelText: 'إلغاء',
            confirmText: 'تأكيد',
            initialEntryMode: TimePickerEntryMode.dial,
          ),
        );
      },
    );
    if (picked != null) {
      // Validate time is between 9 AM and 9 PM (9:00 to 21:59)
      final hour = picked.hour;
      if (hour < 9 || hour >= 22) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: 'الوقت يجب أن يكون بين 9 صباحاً و 9 مساءً',
        );
        return;
      }
      setState(() {
        selectedTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        customerBooking.timeFrom =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  void _selectAltTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false,
          ),
          child: TimePickerDialog(
            initialTime: TimeOfDay.now(),
            helpText: 'اختر الوقت البديل',
            hourLabelText: 'ساعة',
            minuteLabelText: 'دقيقة',
            cancelText: 'إلغاء',
            confirmText: 'تأكيد',
            initialEntryMode: TimePickerEntryMode.dial,
          ),
        );
      },
    );
    if (picked != null) {
      // Validate time is between 9 AM and 9 PM (9:00 to 21:59)
      final hour = picked.hour;
      if (hour < 9 || hour >= 22) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: 'الوقت يجب أن يكون بين 9 صباحاً و 9 مساءً',
        );
        return;
      }
      setState(() {
        selectedAltTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        customerBooking.altTime =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  void _navigateToDataConfirmation() async {
    // Update booking with school
    customerBooking.school = selectedSchool;
    // Update booking price with calculated price
    if (calculatedPrice != null) {
      customerBooking.price = calculatedPrice!.toDouble();
    }

    // المسار العادي - إرسال للـ API
    final result = await ref
        .read(ApiProviders.bookingProvider)
        .createBooking(context, customerBooking);

    if (mounted && result) {
      context.push('/data-confirmation');
    }
  }

  /// التحقق من إمكانية عرض السعر
  bool _canShowPrice() {
    return selectedServiceType.isNotEmpty &&
        selectedSubject.isNotEmpty &&
        selectedGrade.isNotEmpty &&
        selectedDuration.isNotEmpty &&
        customerBooking.subjectId != 0 &&
        customerBooking.gradeId != 0;
  }

  /// حساب السعر عبر API
  Future<void> _calculatePrice() async {
    if (!_canShowPrice()) {
      setState(() => calculatedPrice = null);
      return;
    }

    // إذا كان هناك عرض، استخدم أسعار العرض
    if (hasOffer && currentOffer != null) {
      setState(() => calculatedPrice = currentOffer!.price.toInt());
      return;
    }

    // الحساب عبر API إذا لم يكن هناك عرض
    final gradeId = customerBooking.gradeId;
    final subjectId = customerBooking.subjectId;
    final numberOfHours = customerBooking.numberOfHours;
    final teacherType = customerBooking.teacherType ?? 1;
    final serviceTypeId = customerBooking.serviceTypeId;
    final school = customerBooking.school ?? 1;

    final price = await ref.read(ApiProviders.bookingProvider).calculatePrice(
          context,
          subjectId: subjectId,
          gradeId: gradeId,
          numberOfHours: numberOfHours,
          numberOfSessions: 1,
          teacherType: teacherType,
          serviceTypeId: serviceTypeId,
          school: school,
        );

    if (mounted) {
      setState(() => calculatedPrice = price);
    }
  }

  /// بناء عرض السعر
  Widget _buildPriceDisplay() {
    final bookingProvider = ref.watch(ApiProviders.bookingProvider);
    final price = calculatedPrice ?? 0;
    final numberOfHours = customerBooking.numberOfHours;
    final subject = selectedSubject;
    final grade = selectedGrade;
    final isLoading = bookingProvider.isCalculatingPrice;

    // Auto-calculate price when fields change (debounced in provider)
    // Only calculate if we have all required fields and haven't calculated yet
    if (_canShowPrice() &&
        !isLoading &&
        calculatedPrice == null &&
        !hasOffer &&
        customerBooking.subjectId != 0 &&
        customerBooking.gradeId != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only calculate if still mounted and conditions still valid
        if (mounted && _canShowPrice() && calculatedPrice == null) {
          _calculatePrice();
        }
      });
    }

    return PriceDisplayWidget(
      price: price,
      numberOfHours: numberOfHours,
      subject: subject,
      grade: grade,
      onNextPressed: _navigateToDataConfirmation,
      isLoading: isLoading,
    );
  }

  Widget _buildOfferCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: context.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer,
                color: context.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'عرض خاص',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: context.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            currentOffer!.nameOffer ?? 'عرض مميز',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: context.primaryText,
            ),
          ),
          if (currentOffer!.numberOfSessions != null) ...[
            SizedBox(height: 4.h),
            Text(
              'عدد الحصص: ${currentOffer!.numberOfSessions}',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.secondaryText,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'مدة كل حصة: ${currentOffer!.hours} ساعة',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
