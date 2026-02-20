import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/customer_booking_model.dart';
import 'package:private_4t_app/core/models/grade_model.dart';
import 'package:private_4t_app/core/models/service_type_model.dart';
import 'package:private_4t_app/core/models/subject_model.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/services/price_calculation_service.dart';
import 'package:private_4t_app/core/widgets/price_display_widget.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class InstituteLessonDetailsScreen extends ConsumerStatefulWidget {
  const InstituteLessonDetailsScreen({super.key});

  @override
  ConsumerState<InstituteLessonDetailsScreen> createState() =>
      _InstituteLessonDetailsScreenState();
}

class _InstituteLessonDetailsScreenState
    extends ConsumerState<InstituteLessonDetailsScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'InstituteLessonDetailsscreen';
  
  String selectedServiceType = 'حصة خصوصية';
  String selectedSubject = '';
  String selectedGrade = '';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  TimeOfDay? selectedAltTime; // وقت ثاني احتياطي للحصة
  String selectedDuration = 'ساعتين';
  int selectedTeacherType = 1; // Default: مدرس
  int selectedSchool = 1; // Default: مدارس عربية
  String purposeOfReservation = '';

  final List<String> serviceTypes = ['حصة خصوصية', 'حصة جماعية', 'دورة مكثفة'];
  final customerBooking = CustomerBookingModel.init();
  final TextEditingController purposeController = TextEditingController();
  int? calculatedPrice;

  // List<ServiceTypeModel> serviceTypes = [];
  List<GradeModel> grades = [];
  List<GradeModel> filteredGrades = [];
  List<SubjectModel> subjects = [];

  final List<String> durations = ["ساعة ونص", 'ساعتين'];

  @override
  void dispose() {
    purposeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize booking data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(ApiProviders.bookingProvider).initBooking(context);
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
    // Update the lists when data is loaded
    if (!isLoading && bookingProvider.serviceTypesList.isNotEmpty) {
      subjects = bookingProvider.subjectsList;
      grades = bookingProvider.gradesList;
      _updateFilteredGrades();
      customerBooking.serviceTypeId = 3;
      customerBooking.serviceType = bookingProvider.serviceTypesList.firstWhere(
          (e) => e.id == 3,
          orElse: () => bookingProvider.serviceTypesList.isNotEmpty
              ? bookingProvider.serviceTypesList.first
              : ServiceTypeModel(id: 3, serviceType: 'حصة جماعية'));
      selectedServiceType = customerBooking.serviceType?.serviceType ?? '';
      customerBooking.teacherType = selectedTeacherType;
      customerBooking.school = selectedSchool;

      // Calculate price after data is loaded in build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_canShowPrice() && calculatedPrice == null) {
          _calculatePrice();
        }
      });
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: _buildAppBar(),
        body: isLoading
            ? CommonComponents.loadingDataFromServer(color: context.primary)
            : SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 24.h),
                      // _buildServiceTypeField(),
                      // SizedBox(height: 16.h),
                      _buildSchoolField(),
                      SizedBox(height: 16.h),
                      _buildSubjectField(),
                      SizedBox(height: 16.h),
                      _buildGradeField(),
                      SizedBox(height: 16.h),
                      _buildDateField(),
                      SizedBox(height: 16.h),
                      _buildTimeField(),
                      SizedBox(height: 16.h),
                      _buildDurationField(),
                      SizedBox(height: 16.h),
                      _buildTeacherTypeField(),
                      SizedBox(height: 16.h),
                      _buildPurposeField(),

                      // عرض السعر
                      if (_canShowPrice()) ...[
                        SizedBox(height: 24.h),
                        _buildPriceDisplay(),
                      ],
                      SizedBox(height: 32.h),
                      _buildNextButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return const AppHeader(
      title: 'اختر تفاصيل حصتك في المعهد',
      showBackButton: true,
      showCart: true,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.school, color: context.primary, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'حصة في المعهد',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: context.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypeField() {
    return _buildField(
      label: 'نوع الخدمة',
      value: selectedServiceType,
      onTap: () => _showServiceTypeDialog(),
      icon: Icons.category,
    );
  }

  Widget _buildSubjectField() {
    return _buildField(
      label: 'المادة الدراسية',
      value: selectedSubject,
      onTap: () => _showSubjectDialog(context),
      icon: Icons.book,
    );
  }

  Widget _buildGradeField() {
    return _buildField(
      label: 'الصف الدراسي',
      value: selectedGrade,
      onTap: () => _showGradeDialog(context),
      icon: Icons.grade,
    );
  }

  Widget _buildDateField() {
    return _buildField(
      label: 'التاريخ',
      value: selectedDate != null
          ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
          : 'اختر التاريخ',
      onTap: () => _showDatePicker(),
      icon: Icons.calendar_today,
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField(
          label: 'الوقت',
          value: selectedTime != null
              ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
              : 'اختر الوقت',
          onTap: () => _showTimePicker(),
          icon: Icons.access_time,
        ),
        SizedBox(height: 16.h),
        _buildField(
          label: 'وقت بديل للحصة',
          value: selectedAltTime != null
              ? '${selectedAltTime!.hour}:${selectedAltTime!.minute.toString().padLeft(2, '0')}'
              : 'اختر الوقت البديل (اختياري)',
          onTap: () => _showAltTimePicker(),
          icon: Icons.access_time,
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    return _buildField(
      label: 'مدة الحصة',
      value: selectedDuration,
      onTap: () => _showDurationDialog(context),
      icon: Icons.timer,
    );
  }

  Widget _buildTeacherTypeField() {
    return _buildField(
      label: 'نوع المدرس',
      value: selectedTeacherType == 1 ? 'مدرس' : 'مدرسة',
      onTap: () => _showTeacherTypeDialog(context),
      icon: Icons.person,
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
            color: context.primaryText,
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
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: context.secondary.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: context.secondary.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
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

  Widget _buildField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.primaryText,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: context.secondary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: context.primary, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.primaryText,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: context.secondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    final isFormComplete = selectedDate != null && selectedTime != null;

    return ElevatedButton(
      onPressed: isFormComplete ? _navigateToConfirmation : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: context.primary,
        foregroundColor: context.surface,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Text(
        'التالي',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showServiceTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر نوع الخدمة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: serviceTypes
              .map((type) => ListTile(
                    title: Text(type),
                    onTap: () {
                      setState(() => selectedServiceType = type);
                      context.pop();
                    },
                  ))
              .toList(),
        ),
      ),
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
          title: const Text('اختر الصف'),
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

  void _showDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => selectedDate = date);
      customerBooking.bookingDate = date;
    }
  }

  void _showTimePicker() async {
    final time = await showTimePicker(
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
    if (time != null) {
      // Validate time is between 9 AM and 9 PM (9:00 to 21:59)
      final hour = time.hour;
      if (hour < 9 || hour >= 22) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: 'الوقت يجب أن يكون بين 9 صباحاً و 9 مساءً',
        );
        return;
      }
      setState(() => selectedTime = time);
      customerBooking.timeFrom =
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }
  }

  void _showAltTimePicker() async {
    final time = await showTimePicker(
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
    if (time != null) {
      // Validate time is between 9 AM and 9 PM (9:00 to 21:59)
      final hour = time.hour;
      if (hour < 9 || hour >= 22) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: 'الوقت يجب أن يكون بين 9 صباحاً و 9 مساءً',
        );
        return;
      }
      setState(() => selectedAltTime = time);
      customerBooking.altTime =
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }
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
                          customerBooking.numberOfHours = 2;
                          break;
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

  Widget _buildSchoolField() {
    return _buildField(
      label: 'المدرسة',
      value: selectedSchool == 1
          ? 'مدارس عربية'
          : selectedSchool == 2
              ? 'مدارس أجنبية'
              : 'جامعات',
      onTap: () => _showSchoolDialog(context),
      icon: Icons.school,
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

  void _navigateToConfirmation() async {
    // Update booking with teacher type, school, and purpose
    customerBooking.teacherType = selectedTeacherType;
    customerBooking.school = selectedSchool;
    customerBooking.purposeOfReservation = purposeOfReservation;

    // Update booking price with calculated price
    if (calculatedPrice != null) {
      customerBooking.price = calculatedPrice!.toDouble();
    }

    final result = await ref
        .read(ApiProviders.bookingProvider)
        .createBooking(context, customerBooking);

    if (mounted && result) {
      final booking = ref.read(ApiProviders.bookingProvider).customerBooking;
      context.push('/existing-customer-institute-confirmation', extra: {
        'serviceType': selectedServiceType,
        'subject': selectedSubject,
        'grade': selectedGrade,
        'date': selectedDate ?? DateTime.now(),
        'time': selectedTime ?? TimeOfDay.now(),
        'duration': selectedDuration,
        'price': booking.price ?? 0.0,
      });
    }
  }

  /// التحقق من إمكانية عرض السعر
  bool _canShowPrice() {
    return selectedSubject.isNotEmpty &&
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

    final gradeId = customerBooking.gradeId;
    final subjectId = customerBooking.subjectId;
    final numberOfHours = customerBooking.numberOfHours ?? 1.5;
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
    final numberOfHours = customerBooking.numberOfHours ?? 1.5;
    final subject = selectedSubject;
    final grade = selectedGrade;
    final isLoading = bookingProvider.isCalculatingPrice;

    // Auto-calculate price when fields change
    if (_canShowPrice() && !isLoading && calculatedPrice == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _calculatePrice());
    }

    return PriceDisplayWidget(
      price: price,
      numberOfHours: numberOfHours,
      subject: subject,
      grade: grade,
      onNextPressed: _navigateToConfirmation,
      isLoading: isLoading,
    );
  }
}
