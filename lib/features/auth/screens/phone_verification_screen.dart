import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/grade_model.dart';
import 'package:private_4t_app/core/providers/authentication_providers/phone_verification_provider.dart';
import 'package:private_4t_app/core/widgets/custom_button.dart';
import 'package:private_4t_app/core/widgets/loading_spinner.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({
    super.key,
  });

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'PhoneVerificationScreen';
  
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  GradeModel? _selectedGrade;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(phoneVerificationProvider.notifier).loadGrades();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    if (_formKey.currentState!.validate() && _selectedGrade != null) {
      logButtonClick('send_otp_button', data: {
        'phone': _phoneController.text.trim(),
        'grade_id': _selectedGrade!.id.toString(),
      });
      
      setState(() => _isLoading = true);

      try {
        final success =
            await ref.read(phoneVerificationProvider.notifier).sendOtp(
                  phone: _phoneController.text.trim(),
                  gradeId: _selectedGrade!.id.toString(),
                  context: context,
                );

        if (success && mounted) {
          logStep('otp_sent_for_phone_verification', data: {
            'phone': _phoneController.text.trim(),
          });
          
          final loggedUser = ref.read(ApiProviders.loginProvider).loggedUser;

          context.push('/confirm-otp', extra: {
            'phone': _phoneController.text.trim(),
            'gradeId': _selectedGrade!.id.toString(),
            'googleEmail': loggedUser?.email.toString(),
            'googleName': loggedUser?.name.toString(),
            'googleImage': loggedUser?.imageUrl.toString(),
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grades = ref.watch(phoneVerificationProvider).grades;
    final isLoadingGrades =
        ref.watch(phoneVerificationProvider).isLoadingGrades;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تأكيد رقم الهاتف',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: context.primaryText,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.primaryText),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 24.h),
                Text(
                  'لضمان تجربة سلسة يرجى تأكيد رقم هاتفك',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'سنرسل لك رمز التحقق لتأكيد رقم هاتفك',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48.h),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.grey[50],
                  ),
                  child: DropdownButtonFormField<GradeModel>(
                    value: _selectedGrade,
                    decoration: InputDecoration(
                      labelText: 'الصف الدراسي',
                      prefixIcon:
                          Icon(Icons.school, color: context.primaryText),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                    ),
                    items: grades.map((grade) {
                      return DropdownMenuItem<GradeModel>(
                        value: grade,
                        child: Text(
                          grade.grade ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }).toList(),
                    onChanged: (GradeModel? value) {
                      setState(() {
                        _selectedGrade = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'يرجى اختيار الصف الدراسي';
                      }
                      return null;
                    },
                    dropdownColor: Colors.white,
                    icon: Icon(Icons.keyboard_arrow_down,
                        color: context.primaryText),
                  ),
                ),
                SizedBox(height: 48.h),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    hintText: '5XXXXXXXX',
                    prefixIcon: Icon(Icons.phone, color: context.primaryText),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide:
                      BorderSide(color: context.primaryText, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال رقم الهاتف';
                    }
                    if (value.trim().length < 8) {
                      return 'يرجى إدخال رقم هاتف كويتي صحيح ';
                    }
                    if (!RegExp(r'\d{8}$').hasMatch(value.trim())) {
                      return 'يرجى إدخال رقم هاتف كويتي صحيح ';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 48.h),
                CustomButton(
                  onPressed: _isLoading || isLoadingGrades ? null : _onSubmit,
                  text: _isLoading ? 'جاري الإرسال...' : 'إرسال رمز التحقق',
                  isLoading: _isLoading,
                ),
                if (isLoadingGrades) ...[
                  SizedBox(height: 24.h),
                  const LoadingSpinner(),
                  SizedBox(height: 8.h),
                  Text(
                    'جاري تحميل الصفوف الدراسية...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
