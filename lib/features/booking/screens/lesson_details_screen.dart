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
import 'package:private_4t_app/core/services/price_calculation_service.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/widgets/price_display_widget.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class LessonDetailsScreen extends ConsumerStatefulWidget {
  final OfferModel? offer;

  const LessonDetailsScreen({super.key, this.offer});

  @override
  ConsumerState<LessonDetailsScreen> createState() =>
      _LessonDetailsScreenState();
}

class _LessonDetailsScreenState extends ConsumerState<LessonDetailsScreen>
    with AnalyticsScreenMixin {
  @override
  String get screenName => 'LessonDetailsscreen';

  String? selectedServiceType = 'حصتك في المنزل';
  String? selectedSubject;
  String? selectedGrade;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  TimeOfDay? selectedAltTime; // وقت ثاني احتياطي للحصة
  String? selectedDuration = 'ساعتين';
  int selectedTeacherType = 1; // Default: مدرس
  int selectedSchool = 1; // Default: مدارس عربية
  String purposeOfReservation = '';
  final customerBooking = CustomerBookingModel.init();
  final TextEditingController purposeController = TextEditingController();
  int? calculatedPrice;

  List<ServiceTypeModel> serviceTypes = [];
  List<GradeModel> grades = [];
  List<GradeModel> filteredGrades = []; // الصفوف المفلترة حسب العرض
  List<SubjectModel> subjects = [];

  // متغيرات العرض
  OfferModel? currentOffer;
  bool hasOffer = false;

  final List<String> durations = [
    'ساعة ونصف',
    'ساعتين',
  ];

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
      await ref
          .read(ApiProviders.bookingProvider)
          .getLastBooking(context, widget.offer);
      // Calculate price after booking data is loaded
      if (mounted && !hasOffer && _canShowPrice()) {
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
      serviceTypes = bookingProvider.serviceTypesList;
      subjects = bookingProvider.subjectsList;
      grades = bookingProvider.gradesList;

      currentOffer = widget.offer;
      hasOffer = currentOffer != null;

      // تصفية الصفوف حسب العرض إذا كان متوفراً
      if (hasOffer && currentOffer != null) {
        filteredGrades = grades
            .where((grade) => grade.educationId == currentOffer!.educationId)
            .toList();
        customerBooking.numberOfHours = currentOffer?.hours ?? 2.0;
        customerBooking.offerId = currentOffer?.id ?? 0;
        customerBooking.price = currentOffer?.price;
      } else {
        // Filter grades based on school selection
        _updateFilteredGrades();
      }

      selectedServiceType =
          serviceTypes.first.serviceType ?? selectedServiceType;
      customerBooking.serviceTypeId = serviceTypes.first.id ?? 0;
      customerBooking.teacherType = selectedTeacherType;
      customerBooking.school = selectedSchool;

      // Calculate price after data is loaded in build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!hasOffer && _canShowPrice() && calculatedPrice == null) {
          _calculatePrice();
        }
      });
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: isLoading
              ? CommonComponents.loadingDataFromServer()
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      if (hasOffer && currentOffer != null) ...[
                        _buildOfferCard(),
                        SizedBox(height: 20.h),
                      ],
                      _buildFormCard(),
                      SizedBox(height: 24.h),
                      _buildNextButton(isLoading),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return const AppHeader(
      title: 'اختر تفاصيل حصتك الخاصة',
      showBackButton: true,
      showCart: true,
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
          if (!hasOffer && currentOffer == null) ...[
            _buildFormField(
              label: 'نوع الخدمة',
              value: selectedServiceType,
              placeholder: 'اختر نوع الخدمة',
              onTap: () => _showServiceTypeDialog(),
              hasDropdown: true,
            ),
            SizedBox(height: 20.h),
          ],
          _buildFormField(
            label: 'المدرسة',
            value: selectedSchool == 1
                ? 'مدارس عربية'
                : selectedSchool == 2
                    ? 'مدارس أجنبية'
                    : 'جامعات',
            placeholder: 'اختر المدرسة',
            onTap: () => _showSchoolDialog(),
            hasDropdown: true,
          ),
          SizedBox(height: 20.h),
          _buildFormField(
            label: 'المادة',
            value: selectedSubject,
            placeholder: 'اختر المادة',
            onTap: () => _showSubjectDialog(context),
            hasDropdown: true,
          ),
          SizedBox(height: 20.h),
          _buildFormField(
            label: 'الصف',
            value: selectedGrade,
            placeholder: 'اختر الصف',
            onTap: () => _showGradeDialog(context),
            hasDropdown: true,
          ),
          SizedBox(height: 20.h),
          _buildFormField(
            label: 'التاريخ',
            value: selectedDate != null
                ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                : null,
            placeholder: 'mm/dd/yyyy',
            onTap: () => _showDatePicker(),
            hasDropdown: false,
            hasCalendar: true,
          ),
          SizedBox(height: 20.h),
          _buildFormField(
            label: 'وقت الحصة',
            value: selectedTime != null
                ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                : null,
            placeholder: '--:--',
            onTap: () => _showTimePicker(),
            hasDropdown: false,
            hasClock: true,
          ),
          SizedBox(height: 20.h),
          _buildFormField(
            label: 'وقت بديل للحصة',
            value: selectedAltTime != null
                ? '${selectedAltTime!.hour.toString().padLeft(2, '0')}:${selectedAltTime!.minute.toString().padLeft(2, '0')}'
                : null,
            placeholder: '--:-- (اختياري)',
            onTap: () => _showAltTimePicker(),
            hasDropdown: false,
            hasClock: true,
          ),
          SizedBox(height: 20.h),
          _buildFormField(
            label: 'نوع المدرس',
            value: selectedTeacherType == 1 ? 'مدرس' : 'مدرسة',
            placeholder: 'اختر نوع المدرس',
            onTap: () => _showTeacherTypeDialog(),
            hasDropdown: true,
          ),
          SizedBox(height: 20.h),
          _buildPurposeField(),
          SizedBox(height: 20.h),
          if (!hasOffer && currentOffer == null)
            _buildFormField(
              label: 'مدة الحصة',
              value: selectedDuration,
              placeholder: 'اختر مدة الحصة',
              onTap: () => _showDurationDialog(),
              hasDropdown: true,
            ),

          // عرض السعر
          if (_canShowPrice()) ...[
            SizedBox(height: 24.h),
            _buildPriceDisplay(),
          ],
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    String? value,
    required String placeholder,
    required VoidCallback onTap,
    required bool hasDropdown,
    bool hasCalendar = false,
    bool hasClock = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.primary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: value != null ? context.surface : Colors.grey[100],
              borderRadius: BorderRadius.circular(12.r),
              border: value != null
                  ? Border.all(color: context.primary.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: value != null
                          ? context.primaryText
                          : context.secondaryText,
                    ),
                  ),
                ),
                if (hasDropdown)
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: context.secondary,
                    size: 20.sp,
                  )
                else if (hasCalendar)
                  Icon(
                    Icons.calendar_today,
                    color: context.secondary,
                    size: 20.sp,
                  )
                else if (hasClock)
                  Icon(
                    Icons.access_time,
                    color: context.secondary,
                    size: 20.sp,
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
                color: context.primary.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: context.primary.withOpacity(0.3),
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

  Widget _buildNextButton([bool isLoading = false]) {
    final isFormComplete = selectedServiceType != null &&
        selectedSubject != null &&
        selectedGrade != null &&
        selectedDate != null &&
        selectedTime != null &&
        selectedDuration != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isFormComplete ? _navigateToAddress : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.secondary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? CommonComponents.loadingDataFromServer()
            : Text(
                'التالي',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showServiceTypeDialog() {
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

  void _showDurationDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildSelectionDialog(
        title: 'اختر مدة الحصة',
        items: durations,
        onSelect: (value) {
          setState(() {
            selectedDuration = value;
            switch (durations.indexOf(value)) {
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
          context.pop();
          _calculatePrice();
        },
      ),
    );
  }

  void _showTeacherTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  context.pop();
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
                  context.pop();
                  _calculatePrice();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSchoolDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                      selectedGrade = null;
                      customerBooking.gradeId = 0;
                      customerBooking.grade = null;
                    }
                    calculatedPrice = null; // Reset price to recalculate
                  });
                  context.pop();
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
                      selectedGrade = null;
                      customerBooking.gradeId = 0;
                      customerBooking.grade = null;
                    }
                    calculatedPrice = null; // Reset price to recalculate
                  });
                  context.pop();
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
                      selectedGrade = null;
                      customerBooking.gradeId = 0;
                      customerBooking.grade = null;
                    }
                    calculatedPrice = null; // Reset price to recalculate
                  });
                  context.pop();
                  _calculatePrice();
                },
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildSelectionDialog({
    required String title,
    required List<String> items,
    required Function(String) onSelect,
  }) {
    return AlertDialog(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: context.primaryText,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                items[index],
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.primaryText,
                ),
              ),
              onTap: () => onSelect(items[index]),
            );
          },
        ),
      ),
    );
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        customerBooking.bookingDate = picked;
      });
    }
  }

  void _showTimePicker() async {
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
        selectedTime = picked;
        customerBooking.timeFrom =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  void _showAltTimePicker() async {
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
        selectedAltTime = picked;
        customerBooking.altTime =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  void _navigateToAddress() async {
    // Update booking with teacher type, school, and purpose
    customerBooking.teacherType = selectedTeacherType;
    customerBooking.school = selectedSchool;
    customerBooking.purposeOfReservation = purposeOfReservation;

    // Update booking price with calculated price
    if (calculatedPrice != null) {
      customerBooking.price = calculatedPrice!.toDouble();
    }

    // إذا كان هناك عرض، لا ترسل للـ API الآن، انتقل مباشرة
    if (hasOffer && currentOffer != null) {
      // حفظ بيانات العرض في customerBooking
      customerBooking.offerId = currentOffer!.id;
      customerBooking.offerPrice =
          calculatedPrice?.toDouble() ?? currentOffer!.price;
      ref
          .read(ApiProviders.bookingProvider)
          .addOfferInCustomerBooking(currentOffer?.id);
    }

    // المسار العادي - إرسال للـ API
    final result = await ref
        .read(ApiProviders.bookingProvider)
        .createBooking(context, customerBooking);
    if (mounted && result) {
      context.push('/address');
    }
  }

  /// التحقق من إمكانية عرض السعر
  bool _canShowPrice() {
    return selectedServiceType != null &&
        selectedSubject != null &&
        selectedGrade != null &&
        selectedDuration != null &&
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
      final numberOfHours = customerBooking.numberOfHours ?? 1.5;
      if (numberOfHours == 1.5) {
        setState(() => calculatedPrice = currentOffer!.price1?.toInt() ?? 0);
      } else if (numberOfHours == 2.0) {
        setState(() => calculatedPrice = currentOffer!.price2?.toInt() ?? 0);
      } else {
        setState(() => calculatedPrice = currentOffer!.price.toInt());
      }
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

    // Auto-calculate price when fields change
    if (_canShowPrice() && !isLoading && calculatedPrice == null && !hasOffer) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _calculatePrice());
    }

    return PriceDisplayWidget(
      price: price,
      numberOfHours: numberOfHours,
      subject: subject,
      grade: grade,
      onNextPressed: _navigateToAddress,
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
                color: context.accent,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'عرض خاص',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: context.accent,
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
          ],
        ],
      ),
    );
  }
}
