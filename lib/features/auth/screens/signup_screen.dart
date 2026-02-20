import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/models/grade_model.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  final String role;

  const SignUpScreen({
    super.key,
    required this.role,
  });

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with TickerProviderStateMixin, AnalyticsScreenMixin {
  
  @override
  String get screenName => 'SignUpScreen';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ApiProviders.loginProvider).initAuth(context);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      logButtonClick('signup_button', data: {
        'name': _nameController.text,
        'email': _emailController.text,
        'role': widget.role,
      });
      
      var ok = await ref.read(ApiProviders.loginProvider).userRegister(
            context: context,
            // userPhone: _phoneController.text.toString(),
            userName: _nameController.text.toString(),
            userEmail: _emailController.text.toString(),
          );

      if (ok && mounted) {
        final loggedUser = ref.read(ApiProviders.loginProvider).loggedUser;
        if (loggedUser?.phone == null ||
            (loggedUser != null &&
                loggedUser.phone != null &&
                loggedUser.phone!.isEmpty)) {
          logStep('signup_needs_phone');
          context.go('/phone-verification');
        } else {
          logStep('signup_success');
          context.go('/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = ref.watch(ApiProviders.loginProvider);
    bool isLoading = loginProvider.isLoading;

    if (!isLoading) {
      _grades = loginProvider.gradesList;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6D9), // Brand background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 40.h),
              // Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Title
                      Text(
                        'إنشاء حساب جديد',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF482099), // Purple brand color
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'انضم إلى منصتنا التعليمية',
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
                      children: [
                        // Full Name field
                        _buildTextField(
                          controller: _nameController,
                          label: 'الاسم الكامل *',
                          hint: 'مثال: خالد عبدالله',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال الاسم الكامل';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),
                        // // Phone Number field
                        // _buildPhoneField(),
                        // SizedBox(height: 24.h),
                        // Email field
                        _buildEmailField(),
                        SizedBox(height: 24.h),
                        // // Class field
                        // _buildClassField(),
                        // SizedBox(height: 40.h),
                        // Create Account button
                        SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleSignUp,
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
                            child: isLoading
                                ? SizedBox(
                                    width: 24.w,
                                    height: 24.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : Text(
                                    'إنشاء الحساب',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          "أو",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        _buildGoogleButton(),
                        // Sign In link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'لديك حساب بالفعل ؟ ',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF8C6042),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                logButtonClick('go_to_signin_button');
                                context.go('/signin');
                              },
                              child: Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: const Color(
                                      0xFF482099), // Purple brand color
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                logButtonClick('google_signup_button');
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
                    logStep('google_signup_needs_phone');
                    context.push('/phone-verification');
                  } else {
                    logStep('google_signup_success');
                    context.go('/home');
                  }
                }
              },
        icon: Image.asset('assets/images/private-4t-logo.png', height: 20.h),
        label: Text(
          'إنشاء حساب بواسطة جوجل',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF482099),
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF8C6042).withOpacity(0.6),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: const Color(0xFF482099).withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: const Color(0xFF482099).withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: Color(0xFF482099),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: Color(0xFFDC3545),
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
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
              // Phone number input
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'XXXXXXXX',
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
              // Country code section
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6D9),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12.r),
                    bottomRight: Radius.circular(12.r),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'البريد الإلكتروني *',
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
              // Google entry (tap to sign in with Google)
              // InkWell(
              //   onTap: () async {
              //     final ok = await ref
              //         .read(ApiProviders.loginProvider)
              //         .signInWithGoogle(context: context);
              //     if (ok && mounted) {
              //       final loggedUser =
              //           ref.read(ApiProviders.loginProvider).loggedUser;
              //       if (loggedUser?.phone == null) {
              //         context.go('/phone-verification');
              //       } else {
              //         context.go('/home');
              //       }
              //     }
              //   },
              //   child: Container(
              //     padding:
              //         EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              //     decoration: BoxDecoration(
              //       color: const Color(0xFFF9F6D9),
              //       borderRadius: BorderRadius.only(
              //         topLeft: Radius.circular(12.r),
              //         bottomLeft: Radius.circular(12.r),
              //       ),
              //     ),
              //     child: Row(
              //       mainAxisSize: MainAxisSize.min,
              //       children: [
              //         Text(
              //           'G',
              //           style: TextStyle(
              //             fontSize: 16.sp,
              //             fontWeight: FontWeight.bold,
              //             color: const Color(0xFF482099),
              //           ),
              //         ),
              //         SizedBox(width: 8.w),
              //         Text(
              //           'Google',
              //           style: TextStyle(
              //             fontSize: 14.sp,
              //             fontWeight: FontWeight.w600,
              //             color: const Color(0xFF482099),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              // Email input
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'example@mail.com',
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
                      return 'يرجى إدخال البريد الإلكتروني';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'يرجى إدخال بريد إلكتروني صحيح';
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
            decoration: InputDecoration(
              hintText: 'اختر الصف -',
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
