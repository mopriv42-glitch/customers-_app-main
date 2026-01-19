import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/models/grade_model.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with TickerProviderStateMixin, AnalyticsScreenMixin {
  
  @override
  String get screenName => 'SignInScreen';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  GradeModel? _selectGrade;

  List<GradeModel> _grades = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      logButtonClick('signin_button', data: {
        'phone': _phoneController.text,
        'has_grade': _selectGrade != null,
      });
      
      var result = await ref
          .read(ApiProviders.loginProvider)
          .userLogin(context: context, userPhone: _phoneController.text);

      // Simulate API call

      if (mounted && result) {
        logStep('otp_sent', data: {
          'phone': _phoneController.text,
        });
        context.go('/confirm-otp', extra: {
          "phone": _phoneController.text.toString(),
          "gradeId": _selectGrade?.id.toString()
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6D9), // Brand background
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Title
                      Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF482099), // Purple brand color
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'يرجى إدخال رقم الهاتف والصف، وسيصلك رمز الدخول عبر رسالة SMS.',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFF8C6042), // Brown text
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40.h),
              // Form
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Phone Number field
                        _buildPhoneField(),
                        SizedBox(height: 24.h),
                        // Class field
                        // _buildClassField(),
                        // SizedBox(height: 40.h),
                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1BA39C),
                              // Teal brand color
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              elevation: 4,
                              shadowColor:
                                  const Color(0xFF1BA39C).withOpacity(0.3),
                            ),
                            child: Text(
                              'دخول',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        // Sign Up link
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     Text(
                        //       'ليس لديك حساب ؟ ',
                        //       style: TextStyle(
                        //         fontSize: 14.sp,
                        //         color: const Color(0xFF8C6042),
                        //       ),
                        //     ),
                        //     TextButton(
                        //       onPressed: () {
                        //         context.go('/signup/student');
                        //       },
                        //       child: Text(
                        //         'إنشاء حساب جديد',
                        //         style: TextStyle(
                        //           fontSize: 14.sp,
                        //           color: const Color(
                        //               0xFF482099), // Purple brand color
                        //           fontWeight: FontWeight.w600,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(height: 32.h),
                        // _buildGoogleButton(),
                        // SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    final isLoading = ref.watch(ApiProviders.loginProvider).isLoading;
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: OutlinedButton.icon(
        onPressed: isLoading
            ? null
            : () async {
                logButtonClick('google_signin_button');
                final ok = await ref
                    .read(ApiProviders.loginProvider)
                    .signInWithGoogle(context: context);
                if (ok && mounted) {
                  final loggedUser =
                      ref.read(ApiProviders.loginProvider).loggedUser;
                  if (loggedUser?.phone == null ||
                      (loggedUser != null &&
                          loggedUser.phone != null &&
                          loggedUser.phone!.isEmpty)) {
                    logStep('google_signin_needs_phone');
                    context.push('/phone-verification');
                  } else {
                    logStep('google_signin_success');
                    context.go('/home');
                  }
                }
              },
        icon: Image.asset('assets/images/private-4t-logo.png', height: 20.h),
        label: Text(
          'تسجيل الدخول بواسطة جوجل',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF482099),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: const Color(0xFF482099).withOpacity(0.3)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'رقم الهاتف *',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF482099),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFF482099).withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              // Country code section
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6D9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.r),
                    bottomLeft: Radius.circular(12.r),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🇰🇼',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '965+',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF482099),
                      ),
                    ),
                  ],
                ),
              ),
              // Phone number input
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.black),
                  maxLength: 8,
                  decoration: InputDecoration(
                    hintText: 'XXXXXXXX',
                    counterText: '',
                    hintStyle: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF8C6042).withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال رقم الهاتف';
                    }
                    if (value.length < 8) {
                      return 'رقم الهاتف يجب أن يكون 8 أرقام على الأقل';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الصف الدراسي *',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF482099),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFF482099).withOpacity(0.2),
            ),
          ),
          child: DropdownButtonFormField<GradeModel>(
            value: _selectGrade,
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'اختر الصف –',
              hintStyle: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF8C6042).withOpacity(0.6),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF482099),
              ),
            ),
            items: _grades.map((GradeModel grade) {
              return DropdownMenuItem<GradeModel>(
                value: grade,
                child: Text(
                  grade.grade.toString(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF482099),
                  ),
                ),
              );
            }).toList(),
            onChanged: (GradeModel? newValue) {
              setState(() {
                _selectGrade = newValue;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'يرجى اختيار الصف الدراسي';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
