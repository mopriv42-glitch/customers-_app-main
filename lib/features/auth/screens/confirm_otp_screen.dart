import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/providers/authentication_providers/phone_verification_provider.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class ConfirmOtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String gradeId;
  final String? googleEmail;
  final String? googleName;
  final String? googleImage;

  const ConfirmOtpScreen({
    super.key,
    required this.phone,
    required this.gradeId,
    this.googleEmail,
    this.googleName,
    this.googleImage,
  });

  @override
  ConsumerState<ConfirmOtpScreen> createState() => _ConfirmOtpScreenState();
}

class _ConfirmOtpScreenState extends ConsumerState<ConfirmOtpScreen> with AnalyticsScreenMixin {
  
  @override
  String get screenName => 'ConfirmOtpScreen';
  
  final _formKey = GlobalKey<FormState>();

  List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());
  List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  List<TextInputAction> actions = List.generate(
      6, (index) => index < 5 ? TextInputAction.next : TextInputAction.done);
  List<String? Function(String?)> validators = List.generate(
      6, (index) => (value) => value!.isEmpty ? 'الرجاء إدخال الكود' : null);
  List<bool> obscureTextList = List.generate(6, (index) => true);
  bool isError = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF2D2D2D),
                    const Color(0xFF1A1A1A),
                  ]
                : [
                    const Color(0xFFF9F6D9),
                    const Color(0xFFFFFFFF),
                    const Color(0xFFF9F6D9),
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 40.h),

                // Header Section with Icon and Title
                _buildHeader(context, isDark),

                SizedBox(height: 40.h),

                // OTP Form Section
                _buildOtpForm(context, isDark),

                SizedBox(height: 30.h),

                // Resend Code Section
                // _buildResendSection(context, isDark),

                // SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Animated Icon Container
        Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF6B3BC7),
                      const Color(0xFF482099),
                    ]
                  : [
                      const Color(0xFF482099),
                      const Color(0xFF6B3BC7),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (isDark ? const Color(0xFF6B3BC7) : const Color(0xFF482099))
                        .withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.sms_outlined,
            size: 60.sp,
            color: Colors.white,
          ),
        ),

        SizedBox(height: 24.h),

        // Title
        Text(
          'تأكيد الرمز',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF24104C),
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 12.h),

        // Subtitle
        Text(
          'يرجي إدخال الكود المرسل اليك عن طريق الرسائل النصية',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFFBBBBBB) : const Color(0xFF694731),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 8.h),

        // Phone Number Display
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2D2D2D).withOpacity(0.5)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF6B3BC7).withOpacity(0.3)
                  : const Color(0xFF482099).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone_outlined,
                size: 16.sp,
                color:
                    isDark ? const Color(0xFF6B3BC7) : const Color(0xFF482099),
              ),
              SizedBox(width: 8.w),
              Text(
                widget.phone,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF24104C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpForm(BuildContext context, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          otpFields(
            controllers: otpControllers,
            focusNodes: focusNodes,
            actions: actions,
            validators: validators,
            isError: isError,
            isDark: isDark,
            onChange: () {
              setState(() {
                isError = false;
              });
            },
            onSaved: () async {
              if (_formKey.currentState!.validate()) {
                final otpCode =
                    otpControllers.map((controller) => controller.text).join();

                logButtonClick('confirm_otp_button', data: {
                  'phone': widget.phone,
                  'is_google_signup': widget.googleEmail != null && widget.googleName != null,
                });

                bool response;

                // Check if this is a Google signup completion
                if (widget.googleEmail != null && widget.googleName != null) {
                  // Complete Google signup with phone verification
                  response = await ref
                      .read(phoneVerificationProvider.notifier)
                      .verifyOtp(
                        phone: widget.phone,
                        gradeId: widget.gradeId,
                        otp: otpCode,
                        context: context,
                      );
                } else {
                  // Regular OTP confirmation
                  response =
                      await ref.read(ApiProviders.loginProvider).userConfirmOTP(
                            context: context,
                            userPhone: widget.phone,
                            userCode: otpCode,
                            userGrade: widget.gradeId,
                          );
                }

                if (!response) {
                  logStep('otp_verification_failed', data: {
                    'phone': widget.phone,
                  });
                  setState(() {
                    isError = true;
                  });
                  for (var controller in otpControllers) {
                    controller.clear();
                  }
                }

                if (response && context.mounted) {
                  logStep('otp_verification_success', data: {
                    'phone': widget.phone,
                  });
                  
                  final isNew = await CommonComponents.getSavedData('is_new');
                  if (isNew != null) {
                    logStep('new_user_needs_name_update');
                    context.push('/update-name');
                  } else {
                    logStep('existing_user_login_complete');
                    context.go('/home');
                  }
                }
                ;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResendSection(BuildContext context, bool isDark) {
    return Column(
      children: [
        Text(
          'لم تستلم الكود؟',
          style: TextStyle(
            fontSize: 14.sp,
            color: isDark ? const Color(0xFFBBBBBB) : const Color(0xFF694731),
          ),
        ),
        SizedBox(height: 8.h),
        TextButton(
          onPressed: () {
            // TODO: Implement resend OTP functionality
          },
          child: Text(
            'إعادة إرسال الكود',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF6B3BC7) : const Color(0xFF482099),
            ),
          ),
        ),
      ],
    );
  }

  Widget otpFields({
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    required List<TextInputAction> actions,
    required List<String? Function(String?)?> validators,
    required Function onSaved,
    required Function onChange,
    required bool isDark,
    bool isError = false,
  }) {
    final primaryColor =
        isDark ? const Color(0xFF6B3BC7) : const Color(0xFF482099);
    final errorColor =
        isDark ? const Color(0xFFFF6B6B) : const Color(0xFFDC3545);
    final backgroundColor = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF24104C);
    final borderColor = isError ? errorColor : primaryColor;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.backspace) {
          for (int i = 0; i < focusNodes.length; i++) {
            if (focusNodes[i].hasFocus && controllers[i].text.isEmpty) {
              if (i > 0) {
                controllers[i - 1].clear();
                FocusScope.of(context).requestFocus(focusNodes[i - 1]);
              }
              break;
            } else if (focusNodes[i].hasFocus &&
                controllers[i].text.isNotEmpty) {
              controllers[i].clear();
              if (i > 0) {
                FocusScope.of(context).requestFocus(focusNodes[i - 1]);
              }
              break;
            }
          }
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50.w,
            height: 60.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: focusNodes[index].hasFocus
                  ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.grey)
                            .withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: TextFormField(
              autofocus: index == 0,
              controller: controllers[index],
              focusNode: focusNodes[index],
              keyboardType: TextInputType.number,
              textInputAction: actions[index],
              validator: validators[index],
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
              maxLength: 1,
              decoration: InputDecoration(
                counterText: "",
                contentPadding: EdgeInsets.zero,
                isDense: true,
                filled: true,
                fillColor: backgroundColor,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: borderColor.withOpacity(0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: borderColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: errorColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: errorColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1)
              ],
              autofillHints: const [AutofillHints.oneTimeCode],
              onTap: () {
                if (index != 0) {
                  for (var element in controllers) {
                    element.clear();
                  }
                  FocusScope.of(context).requestFocus(focusNodes[0]);
                }
              },
              onChanged: (v) {
                if (controllers[index].text.isNotEmpty && index < 5) {
                  focusNodes[index + 1].requestFocus();
                }
                if (isError) {
                  onChange();
                }
                bool allFilled = controllers
                    .every((controller) => controller.text.isNotEmpty);
                if (allFilled) {
                  onSaved();
                }
              },
            ),
          );
        }),
      ),
    );
  }
}
