import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/order_course_model.dart';
import 'package:private_4t_app/core/providers/app_container.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:riverpod_context/riverpod_context.dart';

class ClassCard extends StatefulWidget {
  final OrderCourseModel orderCourseModel;
  final bool isCourse;
  final bool compact; // compact layout for tighter spaces (e.g., home screen)

  const ClassCard({
    super.key,
    required this.orderCourseModel,
    this.isCourse = false,
    this.compact = false,
  });

  @override
  State<ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<ClassCard> {
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.orderCourseModel.mapAddress ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Navigate to chat room for this order
  void _navigateToChat(BuildContext context) {
    if (widget.orderCourseModel.matrixRoomId != null &&
        widget.orderCourseModel.matrixRoomId!.isNotEmpty) {
      NavigationService.navigateToRoomTimeline(
          context, widget.orderCourseModel.matrixRoomId!);
    }
  }

  // Navigate to diagnostic - find the one related to this order if exists
  Future<void> _navigateToDiagnostic() async {
    // Open specific diagnostic detail
    context
        .push('/teacher-diagnostics/${widget.orderCourseModel.diagnosticId}');
  }

  // Navigate to follow-up - find the one related to this order if exists
  Future<void> _navigateToFollowUp() async {
    context.push('/teacher-follow-ups/${widget.orderCourseModel.followUpId}');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isCourse
          ? null
          : () =>
              context.push('/booking-details', extra: widget.orderCourseModel),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.background.withOpacity(0.9),
              context.surface,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: context.secondary.withOpacity(0.12),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              SizedBox(height: 8.h),
              _buildDetails(),
              SizedBox(height: 10.h),
              _buildStatusBar(),
              SizedBox(height: 10.h),
              const Divider(height: 1),
              SizedBox(height: 10.h),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            "${widget.orderCourseModel.subject?.subject ?? ''} - ${widget.orderCourseModel.grade?.grade ?? ''}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: context.primaryText,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.accent, context.accentSecondary],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(999.r),
            boxShadow: [
              BoxShadow(
                color: context.accent.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Text(
            'كود ${widget.orderCourseModel.id}',
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: context.textOnAccent,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    final List<_MetaItem> metaItems = [
      _MetaItem(
        icon: Icons.calendar_today,
        label: widget.orderCourseModel.formatBookingDateArabic,
      ),
      _MetaItem(
        icon: Icons.access_time,
        label: 'الساعة ${widget.orderCourseModel.timeFrom.toString()}',
      ),
      if (!widget.isCourse)
        _MetaItem(
          icon: Icons.person,
          label: widget.orderCourseModel.teacherName ?? 'لا يوجد مدرس',
        ),
      if (widget.isCourse)
        _MetaItem(
          icon: Icons.numbers,
          label: "${widget.orderCourseModel.numberOfSessions ?? 1} حصص",
        ),
      _MetaItem(
        icon: Icons.hourglass_empty,
        label:
            'المدة: ${widget.orderCourseModel.numberOfHours.toString()} ساعة',
      ),
    ];

    return Wrap(
      spacing: 12.w,
      runSpacing: 8.h,
      children: metaItems
          .map((m) => _buildMetaChip(icon: m.icon, label: m.label))
          .toList(),
    );
  }

  Widget _buildStatusBar() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 6.h,
      children: [
        _buildStatusChip(
          widget.orderCourseModel.orderStatus.toString(),
          widget.orderCourseModel.isCompleted!
              ? context.success
              : context.warning,
          widget.orderCourseModel.isCompleted!
              ? Icons.check_circle
              : Icons.schedule,
        ),
        _buildStatusChip(
          widget.orderCourseModel.payment.toString(),
          context.accentSecondary,
          Icons.payment,
        ),
        _buildStatusChip(
          widget.orderCourseModel.orderType.toString(),
          context.primary,
          Icons.home,
        ),
      ],
    );
  }

  Widget _buildStatusChip(String text, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18.r,
            height: 18.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 10.sp, color: color),
          ),
          SizedBox(width: 6.w),
          // REMOVED Flexible widget here - not needed in Row with mainAxisSize: MainAxisSize.min
          Text(
            text,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (widget.isCourse) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (widget.orderCourseModel.teacherId != null &&
              widget.orderCourseModel.teacherId! > 0)
            _buildActionPill(
              icon: Icons.chat_bubble_outline,
              label: 'مراسلة',
              color: context.accentSecondary,
              onTap: () => _navigateToChat(context),
            ),
        ],
      );
    }

    final actions = <Widget>[
      if (widget.orderCourseModel.teacherId != null &&
          widget.orderCourseModel.teacherId! > 0)
        _buildActionPill(
          icon: Icons.chat_bubble_outline,
          label: 'مراسلة',
          color: context.accentSecondary,
          onTap: () => _navigateToChat(context),
        ),
      if (widget.orderCourseModel.orderStatus == 'تم_الارسال_للمدرسين' ||
          widget.orderCourseModel.orderStatus == 'تم_اختيار_مدرس')
        _buildActionPill(
          icon: Icons.edit,
          label: 'تعديل',
          color: context.primary,
          onTap: () => _showEditModal(context),
        ),
      if (widget.orderCourseModel.orderStatus == 'مكتمل' && !widget.isCourse)
        _buildActionPill(
          icon: Icons.refresh,
          label: 'تجديد',
          color: context.success,
          onTap: () => _showRenewBookingDialog(context),
        ),
      if (widget.orderCourseModel.orderStatus == 'مكتمل' ||
          widget.orderCourseModel.orderStatus == 'انتظار_مراجعة') ...[
        _buildActionPill(
          icon: Icons.star,
          label: 'تقييم',
          color: context.accent,
          onTap: () => showTeacherRatingDialog(context),
        ),
        _buildActionPill(
          icon: Icons.note,
          label: 'ملاحظة',
          color: context.secondary,
          onTap: () => showStudentNoteDialog(context),
        ),
        if (widget.orderCourseModel.diagnosticId != null)
          _buildActionPill(
            icon: Icons.medical_services,
            label: 'التشخيص',
            color: context.primary,
            onTap: _navigateToDiagnostic,
          ),
        if (widget.orderCourseModel.followUpId != null)
          _buildActionPill(
            icon: Icons.track_changes,
            label: 'المتابعة',
            color: context.accent,
            onTap: _navigateToFollowUp,
          ),
      ],
    ];

    // Always use Wrap to avoid overflow when there are many buttons
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 8.w,
      runSpacing: 8.h,
      children: actions,
    );
  }

  void _showEditModal(BuildContext context) {
    String selectedAddress = widget.orderCourseModel.mapAddress ?? '';
    DateTime selectedDate =
        DateTime.tryParse(widget.orderCourseModel.bookingDate ?? '') ??
            DateTime.now();
    TimeOfDay selectedTime = widget.orderCourseModel.timeFromParsed;
    double selectedHours =
        double.tryParse(widget.orderCourseModel.numberOfHours ?? '') ?? 2.0;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'تعديل بيانات الحصة',
                  style: TextStyle(fontSize: 18.r, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 16.h),

              // Address Field
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'عنوانك',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  selectedAddress = value;
                },
              ),
              SizedBox(height: 16.h),

              // Date Picker
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(
                        text: DateFormat('MM/dd/yyyy').format(selectedDate),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'تاريخ الحجز',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(DateTime.now().year),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null && pickedDate != selectedDate) {
                          // Use a local state variable instead of setState on the parent
                          selectedDate = pickedDate;
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(DateTime.now().year),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null && pickedDate != selectedDate) {
                        selectedDate = pickedDate;
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // Time Picker
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(
                        text: selectedTime.format(context),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'تاريخ بداية الحجز',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (pickedTime != null && pickedTime != selectedTime) {
                          selectedTime = pickedTime;
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (pickedTime != null && pickedTime != selectedTime) {
                        selectedTime = pickedTime;
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Dropdown for Number of Hours
              // Row(
              //   children: [
              //     Expanded(
              //       child: DropdownButtonFormField<double>(
              //         value: selectedHours,
              //         items: const [
              //           DropdownMenuItem<double>(
              //             value: 1.5,
              //             child: Text('ساعة ونصف'),
              //           ),
              //           DropdownMenuItem<double>(
              //             value: 2.0,
              //             child: Text('ساعتين'),
              //           )
              //         ],
              //         onChanged: (value) {
              //           if (value != null) {
              //             selectedHours = value;
              //           }
              //         },
              //         decoration: const InputDecoration(
              //           labelText: 'عدد الساعات',
              //           border: OutlineInputBorder(),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              // SizedBox(height: 16.h),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await context
                          .read(ApiProviders.subscriptionsProvider)
                          .updateOrder(
                              context: context,
                              orderId: widget.orderCourseModel.id ?? 0,
                              orderType:
                                  widget.orderCourseModel.orderType.toString(),
                              address: selectedAddress,
                              date: selectedDate,
                              time: selectedTime,
                              numberOfHours: selectedHours);
                      Navigator.pop(context);
                    },
                    child: const Text('حفظ'),
                  ),
                  SizedBox(width: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void showTeacherRatingDialog(BuildContext context) async {
    final rateTeacherModel =
        await context.read(ApiProviders.subscriptionsProvider).getRateTeacher(
              context: context,
              orderId: widget.orderCourseModel.id ?? 0,
            );

    final TextEditingController notesController = TextEditingController();
    notesController.text = rateTeacherModel?.notes ?? '';
    int? selectedRating = rateTeacherModel?.rate;

    final List<String> ratings = ['ممتاز', 'جيد جدًا', 'جيد', 'ضعيف'];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تقييم المدرس', textAlign: TextAlign.right),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تقييم المدرس'),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedRating,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: ratings.asMap().entries.map((entry) {
                    int index = entry.key;
                    String rating = entry.value;
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(rating),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedRating = value;
                  },
                ),
                const SizedBox(height: 16),
                const Text('ملاحظات'),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedRating == null) {
                  CommonComponents.showCustomizedSnackBar(
                    context: context,
                    title: 'يرجى تقييم المدرس',
                  );
                  return;
                }
                await context
                    .read(ApiProviders.subscriptionsProvider)
                    .rateTeacher(
                      context: context,
                      orderId: widget.orderCourseModel.id ?? 0,
                      rate: selectedRating!,
                      notes: notesController.text.toString(),
                    );

                Navigator.pop(context);
              },
              child: const Text('تقييم'),
            ),
          ],
        );
      },
    );
  }

  void _showRenewBookingDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    final TextEditingController purposeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(20.r),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with icon
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: context.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.refresh,
                          color: context.success,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'تجديد حجز الحصة',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: context.primaryText,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Date Field
                  Text(
                    'تاريخ الحصة *',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.primaryText,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: TextEditingController(
                      text: DateFormat('yyyy/MM/dd').format(selectedDate),
                    ),
                    decoration: InputDecoration(
                      labelText: 'اختر التاريخ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: bottomSheetContext,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        selectedDate = pickedDate;
                      }
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Time Field
                  Text(
                    'وقت الحصة *',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.primaryText,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: TextEditingController(
                      text: selectedTime.format(bottomSheetContext),
                    ),
                    decoration: InputDecoration(
                      labelText: 'اختر الوقت',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      prefixIcon: const Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: bottomSheetContext,
                        initialTime: selectedTime,
                      );
                      if (pickedTime != null) {
                        selectedTime = pickedTime;
                      }
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Purpose Field (Optional)
                  Text(
                    'الغرض من الحصة (اختياري)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.primaryText,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: purposeController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'مثال: مراجعة للامتحان النهائي',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(bottomSheetContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.secondary.withOpacity(0.1),
                            foregroundColor: context.secondary,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: Consumer(
                          builder: (ctx, ref, _) {
                            return ElevatedButton(
                              onPressed: () async {
                                // Validate
                                if (selectedDate.isBefore(DateTime.now())) {
                                  CommonComponents.showCustomizedSnackBar(
                                    context: ctx,
                                    title: 'يرجى اختيار تاريخ مستقبلي',
                                  );
                                  return;
                                }

                                Navigator.pop(bottomSheetContext);

                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) async {
                                  final renewedBooking = await ref
                                      .read(ApiProviders.subscriptionsProvider)
                                      .renewOrder(
                                        context: context,
                                        orderId: widget.orderCourseModel.id!,
                                        bookingDate: selectedDate,
                                        bookingTime: selectedTime,
                                        purpose: purposeController.text.trim(),
                                      );

                                  debugPrint(
                                    "Renewed booking => ${renewedBooking?.toJson().toString()}",
                                  );

                                  if (renewedBooking != null) {
                                    providerAppContainer
                                        .read(ApiProviders.bookingProvider)
                                        .setCustomerBooking(renewedBooking);

                                    NavigationService.router
                                        ?.push('/booking-payment');
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.success,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh, size: 18.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'تجديد الحجز',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showStudentNoteDialog(BuildContext context) {
    final TextEditingController noteController = TextEditingController();

    // Pre-fill with existing note if available
    noteController.text = widget.orderCourseModel.ratingStudent ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer(
          builder: (context, ref, _) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.note, color: context.primary, size: 24.sp),
                  SizedBox(width: 8.w),
                  const Text('إضافة ملاحظة'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أضف ملاحظتك حول هذا الدرس:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: context.secondaryText,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: noteController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'اكتب ملاحظتك هنا...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                              color: context.secondary.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide:
                              BorderSide(color: context.primary, width: 2),
                        ),
                        contentPadding: EdgeInsets.all(12.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'ستساعدك هذه الملاحظة في تذكر التفاصيل المهمة حول الدرس',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.secondaryText.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(color: context.secondaryText),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final note = noteController.text.trim();
                    if (note.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('يرجى كتابة ملاحظة قبل الحفظ'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    // Save the note using the subscription provider
                    await ref
                        .read(ApiProviders.subscriptionsProvider)
                        .saveStudentNote(
                          context: context,
                          orderCourseId: widget.orderCourseModel.id!,
                          note: note,
                        );

                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primary,
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save, size: 16.sp),
                      SizedBox(width: 4.w),
                      const Text('حفظ'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // -- Helpers: unified meta chip & action pill ----------------------------

  Widget _buildMetaChip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: context.secondary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999.r),
        border:
            Border.all(color: context.secondary.withOpacity(0.15), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: context.secondary),
          SizedBox(width: 6.w),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 180.w),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                color: context.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool compact = widget.compact;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8.w : 10.w,
          vertical: compact ? 5.h : 7.h,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(compact ? 16.r : 999.r),
          border: Border.all(color: color.withValues(alpha: 0.18), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 11.sp : 12.sp, color: color),
            SizedBox(width: compact ? 3.w : 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 9.sp : 10.sp,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaItem {
  final IconData icon;
  final String label;

  _MetaItem({required this.icon, required this.label});
}
