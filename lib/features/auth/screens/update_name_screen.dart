import 'package:easy_localization/easy_localization.dart' as l;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/models/customer_role_model.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

import '../../../core/models/platform_model.dart';

class UpdateNameScreen extends ConsumerStatefulWidget {
  const UpdateNameScreen({super.key});

  @override
  ConsumerState<UpdateNameScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<UpdateNameScreen>
    with TickerProviderStateMixin, AnalyticsScreenMixin {
  
  @override
  String get screenName => 'UpdateNameScreen';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  CustomerRoleModel? _selectedCustomerRole;
  List<CustomerRoleModel> _customerRoles = [];
  List<PlatformModel> _platforms = [];
  PlatformModel? _selectedPlatform;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ApiProviders.loginProvider).initAuth(context);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      logButtonClick('update_name_button', data: {
        'name': _nameController.text,
        'customer_role_id': _selectedCustomerRole?.id.toString(),
        'platform_id': _selectedPlatform?.id.toString(),
      });
      
      var ok = await ref
          .read(ApiProviders.loginProvider)
          .updateName(
            context: context,
            name: _nameController.text.toString(),
            customerRoleId:
                _selectedCustomerRole?.id != null &&
                    _selectedCustomerRole?.id != 0
                ? _selectedCustomerRole?.id.toString()
                : '',
            platformId: _selectedPlatform?.id != null &&
                    _selectedPlatform?.id != 0
                ? _selectedPlatform?.id.toString()
                : '',
          );

      if (ok && mounted) {
        logStep('name_update_success', data: {
          'name': _nameController.text,
        });
        
        // Apply theme immediately after successful update
        if (_selectedPlatform != null) {
          ref
              .read(ApiProviders.loginProvider)
              .updateUserPlatform(_selectedPlatform!);
        }
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = ref.watch(ApiProviders.loginProvider);
    bool isLoading = loginProvider.isLoading;
    _customerRoles = loginProvider.customerRolesList;
    _platforms = loginProvider.platformsList;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6D9), // Brand background
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.sp),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),
                // Header
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        Text(
                          'أدخل إسمك الكامل',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(
                              0xFF482099,
                            ), // Purple brand color
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
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
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  "ولي الأمر *",
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF482099),
                  ),
                ),
                SizedBox(height: 20.h),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      child: DropdownButtonFormField<CustomerRoleModel>(
                        value: _selectedCustomerRole,
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
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
                          hintText: "اختار نوع ولي الامر",
                          hintStyle: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF8C6042).withOpacity(0.6),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          suffixIcon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF482099),
                          ),
                        ),
                        items: _customerRoles.map((
                          CustomerRoleModel customerRole,
                        ) {
                          return DropdownMenuItem<CustomerRoleModel>(
                            value: customerRole,
                            child: Text(
                              customerRole.role.toString(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF482099),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (CustomerRoleModel? newValue) {
                          setState(() {
                            _selectedCustomerRole = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return "يجب اختيار نوع ولي الامر";
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                // Platform Selection
                Text(
                  "المنصة *",
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF482099),
                  ),
                ),
                SizedBox(height: 20.h),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      child: DropdownButtonFormField<PlatformModel>(
                        value: _selectedPlatform,
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
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
                          hintText: "اختر المنصة",
                          hintStyle: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF8C6042).withOpacity(0.6),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          suffixIcon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF482099),
                          ),
                        ),
                        items:  _platforms.map((
                          PlatformModel platform,
                        ) {
                          return DropdownMenuItem<PlatformModel>(
                            value: platform,
                            child: Text(
                              platform.name.toString(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF482099),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (PlatformModel? newValue) {
                          setState(() {
                            _selectedPlatform = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return "يجب اختيار المنصة";
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
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
                      shadowColor: const Color(0xFF1BA39C).withOpacity(0.3),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.w,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'التالي',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                // Form
              ],
            ),
          ),
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
              borderSide: const BorderSide(color: Color(0xFF482099), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFDC3545)),
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
}
