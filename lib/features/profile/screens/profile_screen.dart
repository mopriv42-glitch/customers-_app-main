import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/grade_model.dart';
import 'package:private_4t_app/core/models/subject_model.dart';
import 'package:private_4t_app/core/models/user_model.dart';
import 'package:private_4t_app/core/models/governorate_model.dart';
import 'package:private_4t_app/core/models/region_model.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with WidgetsBindingObserver, AnalyticsScreenMixin {
  @override
  String get screenName => 'ProfileScreen';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _blockController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  UserModel? _loggedUser;
  GradeModel? _selectedGrade;
  // List<SubjectModel> _selectedSubjects = [];

  List<GradeModel> _grades = [];
  List<SubjectModel> _subjects = [];
  List<GovernorateModel> _governorates = [];
  List<RegionModel> _regions = [];
  String? _selectedGovernorate;
  String? _selectedArea;
  GovernorateModel? _selectedGovernorateModel;
  RegionModel? _selectedRegionModel;

  @override
  void initState() {
    super.initState();
    // Add observer for app lifecycle
    WidgetsBinding.instance.addObserver(this);

    // Pre-fill with sample data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ApiProviders.loginProvider).profile(context);
    });

    _nameController.addListener(() {
      setState(() {});
    });

    _emailController.addListener(() {
      setState(() {});
    });

    _phoneController.addListener(() {
      setState(() {});
    });

    _blockController.addListener(() {
      setState(() {});
    });

    _streetController.addListener(() {
      setState(() {});
    });

    _houseController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh profile data when dependencies change (e.g., when returning to screen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProfileData();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Refresh profile data when app is resumed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadProfileData();
        }
      });
    }
  }

  // Separate method to load profile data
  void _loadProfileData() {
    final loginProvider = ref.read(ApiProviders.loginProvider);
    if (!loginProvider.isLoading) {
      setState(() {
        debugPrint("From load Profile");
        _loggedUser = loginProvider.loggedUser;
        _nameController.text = _loggedUser?.name ?? '';
        _phoneController.text = _loggedUser?.phone ?? '';
        _emailController.text = _loggedUser?.email ?? '';

        // Load address fields from mapAddress first, then from profile
        final mapAddress = _loggedUser?.mapAddress;
        debugPrint("MapAddress: ${mapAddress?.toJson().toString()}");
        debugPrint("Profile: ${_loggedUser?.profile?.toJson().toString()}");
        _selectedGovernorateModel = _loggedUser?.profile?.governorate;
        _selectedRegionModel = _loggedUser?.profile?.region;
        _selectedGovernorate = _selectedGovernorateModel?.governorate;
        _selectedArea = _selectedRegionModel?.region;
        if (mapAddress != null) {
          // Use mapAddress data
          _blockController.text = mapAddress.blockNumber ?? '';
          _streetController.text = mapAddress.streetNumber ?? '';
          _houseController.text = mapAddress.houseNumber ?? '';
        } else {
          // Fallback to profile data
          _blockController.clear();
          _streetController.clear();
          _houseController.clear();
        }

        // Find the grade in the grades list that matches the user's grade
        if (_loggedUser?.profile?.grade != null &&
            loginProvider.gradesList.isNotEmpty) {
          try {
            _selectedGrade = loginProvider.gradesList.firstWhere(
              (grade) => grade.id == _loggedUser!.profile!.grade!.id,
            );
            debugPrint(
                'Found matching grade: ${_selectedGrade?.grade} (ID: ${_selectedGrade?.id})');
          } catch (e) {
            // If grade not found in list, use the user's grade
            _selectedGrade = _loggedUser!.profile!.grade;
            debugPrint(
                'Using user grade: ${_selectedGrade?.grade} (ID: ${_selectedGrade?.id})');
          }
        } else {
          _selectedGrade = _loggedUser?.profile?.grade;
          debugPrint('No user grade or grades list empty');
        }

        _grades = loginProvider.gradesList;
        _subjects = loginProvider.subjectsList;

        // Update governorates and regions lists
        _governorates = loginProvider.governoratesList;
        _regions = loginProvider.regionsList;

        // If governorate/region are selected but not in lists, try to find them
        if (_selectedGovernorateModel != null && _governorates.isNotEmpty) {
          try {
            final found = _governorates.firstWhere(
              (g) => g.id == _selectedGovernorateModel!.id,
            );
            _selectedGovernorateModel = found;
            _selectedGovernorate = found.governorate;
          } catch (e) {
            // Keep the selected model even if not in list
          }
        }

        if (_selectedRegionModel != null && _regions.isNotEmpty) {
          try {
            final found = _regions.firstWhere(
              (r) => r.id == _selectedRegionModel!.id,
            );
            _selectedRegionModel = found;
            _selectedArea = found.region;
          } catch (e) {
            // Keep the selected model even if not in list
          }
        }

        debugPrint(
            'Loaded ${_grades.length} grades and ${_subjects.length} subjects');
        debugPrint(
            'Current selected grade: ${_selectedGrade?.grade} (ID: ${_selectedGrade?.id})');
      });
    }
  }

  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);

    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _blockController.dispose();
    _streetController.dispose();
    _houseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = ref.watch(ApiProviders.loginProvider);
    bool isLoading = loginProvider.isLoading;

    // Update governorates and regions lists from provider
    if (!isLoading) {
      _governorates = loginProvider.governoratesList;
      _regions = loginProvider.regionsList;
    }

    // Don't update controllers in build method - do it in didChangeDependencies or callbacks
    if (!isLoading && _loggedUser == null && loginProvider.loggedUser != null) {
      // Initial load - update data once
      _loadProfileData();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'الملف الشخصي',
          showBackButton: true,
        ),
        body: isLoading
            ? CommonComponents.loadingDataFromServer()
            : SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    SizedBox(height: 24.h),
                    _buildPersonalInfoSection(),
                    SizedBox(height: 24.h),
                    // _buildAcademicInfoSection(),
                    // SizedBox(height: 24.h),
                    _buildSaveButton(),
                    if (_hasUnsavedChanges()) ...[
                      SizedBox(height: 16.h),
                      _buildResetButton(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50.r,
            backgroundColor: context.primary,
            child: Icon(
              Icons.person,
              size: 50.sp,
              color: context.surface,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            _loggedUser?.name ?? '',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'طالب - ${_loggedUser?.profile?.grade?.grade ?? 'لم يحدد الصف الدراسي بعد'}',
            style: TextStyle(
              fontSize: 14.sp,
              color: context.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المعلومات الشخصية',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoField('الاسم', _nameController, Icons.person),
          SizedBox(height: 16.h),
          _buildInfoField('الرقم', _phoneController, Icons.phone, true),
          SizedBox(height: 16.h),
          _buildInfoField('الايميل', _emailController, Icons.email),
          SizedBox(height: 16.h),
          _buildDropdownField(
            label: 'المحافظة',
            value: _selectedGovernorate,
            placeholder: 'اختر المحافظة',
            onTap: () => _showGovernorateDialog(),
          ),
          SizedBox(height: 16.h),
          _buildDropdownField(
            label: 'المنطقة',
            value: _selectedArea,
            placeholder: 'اختر المنطقة',
            onTap:
                _selectedGovernorate != null ? () => _showAreaDialog() : null,
            isEnabled: _selectedGovernorate != null,
          ),
          SizedBox(height: 16.h),
          _buildInfoField('رقم القطعة', _blockController, Icons.tag),
          SizedBox(height: 16.h),
          _buildInfoField('رقم الشارع', _streetController, Icons.place),
          SizedBox(height: 16.h),
          _buildInfoField('رقم المنزل', _houseController, Icons.home),
        ],
      ),
    );
  }

  Widget _buildAcademicInfoSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.secondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المعلومات الأكاديمية',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: context.primaryText,
            ),
          ),
          SizedBox(height: 16.h),
          if (_selectedGrade != null) ...[
            _buildGradeDropdown(),
            SizedBox(height: 16.h),
          ],
          // _buildMultiSelectField(
          //     'المواد', _selectedSubjects, _subjects, Icons.book),
        ],
      ),
    );
  }

  Widget _buildInfoField(
      String label, TextEditingController controller, IconData icon,
      [bool readOnly = false]) {
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
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: context.secondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: context.secondary.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: context.secondary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: context.border),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    String? value,
    required String placeholder,
    required VoidCallback? onTap,
    bool isEnabled = true,
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
          onTap: isEnabled ? onTap : null,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isEnabled
                  ? (value != null ? context.surface : Colors.grey[100])
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(8.r),
              border: value != null
                  ? Border.all(color: context.primary.withOpacity(0.3))
                  : Border.all(color: context.secondary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isEnabled
                          ? (value != null
                              ? context.primaryText
                              : context.secondaryText)
                          : context.secondaryText,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: isEnabled ? context.secondary : Colors.grey,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final hasUnsavedChanges = _hasUnsavedChanges();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: hasUnsavedChanges ? _saveProfile : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasUnsavedChanges ? context.primary : Colors.grey,
          foregroundColor: context.surface,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text(
          hasUnsavedChanges ? 'حفظ التغييرات' : 'لا توجد تغييرات',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Check if there are any unsaved changes
  bool _hasUnsavedChanges() {
    if (_loggedUser == null) return false;

    // Check if any field has changed
    final nameChanged =
        _nameController.text.trim() != (_loggedUser!.name ?? '');
    final emailChanged =
        _emailController.text.trim() != (_loggedUser!.email ?? '');
    final phoneChanged =
        _phoneController.text.trim() != (_loggedUser!.phone ?? '');

    final currentGovernorateId = _loggedUser!.profile?.governorateId;
    final selectedGovernorateId = _selectedGovernorateModel?.id;
    final governorateChanged = currentGovernorateId != selectedGovernorateId;

    final currentRegionId =
        _loggedUser!.profile?.regionId ?? _loggedUser!.mapAddress?.regionId;
    final selectedRegionId = _selectedRegionModel?.id;
    final regionChanged = currentRegionId != selectedRegionId;

    // Check address fields from mapAddress
    final mapAddress = _loggedUser!.mapAddress;
    final blockChanged =
        _blockController.text.trim() != (mapAddress?.blockNumber ?? '');
    final streetChanged =
        _streetController.text.trim() != (mapAddress?.streetNumber ?? '');
    final houseChanged =
        _houseController.text.trim() != (mapAddress?.houseNumber ?? '');

    // Check if grade has changed
    // final currentGradeId = _loggedUser!.profile?.grade?.id;
    // final selectedGradeId = _selectedGrade?.id;
    // final gradeChanged = currentGradeId != selectedGradeId;

    return nameChanged ||
        emailChanged ||
        phoneChanged ||
        governorateChanged ||
        regionChanged ||
        blockChanged ||
        streetChanged ||
        houseChanged;
  }

  /// Build grade dropdown field
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
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: _selectedGrade != null ? context.surface : Colors.grey[100],
            borderRadius: BorderRadius.circular(12.r),
            border: _selectedGrade != null
                ? Border.all(color: context.primary.withOpacity(0.3))
                : Border.all(color: context.secondary.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedGrade?.id,
              hint: Text(
                'اختر الصف',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.secondaryText,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: _selectedGrade != null
                    ? context.primary
                    : context.secondary,
                size: 20.sp,
              ),
              dropdownColor: context.surface,
              items: _grades.isEmpty
                  ? [
                      DropdownMenuItem<int>(
                        value: null,
                        enabled: false,
                        child: Text(
                          'لا توجد صفوف متاحة',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: context.secondaryText,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ]
                  : _grades.map((GradeModel grade) {
                      return DropdownMenuItem<int>(
                        value: grade.id,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                grade.grade ?? '',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: context.primaryText,
                                  fontWeight: _selectedGrade?.id == grade.id
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (_selectedGrade?.id == grade.id)
                              Icon(
                                Icons.check,
                                color: context.primary,
                                size: 16.sp,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
              onChanged: _grades.isEmpty
                  ? null
                  : (int? newValue) {
                      if (newValue != null) {
                        final selectedGrade = _grades.firstWhere(
                          (grade) => grade.id == newValue,
                          orElse: () => GradeModel(
                              id: newValue, grade: '', educationId: 0),
                        );
                        setState(() {
                          _selectedGrade = selectedGrade;
                        });
                        debugPrint(
                            'Grade selected: ${_selectedGrade?.grade} (ID: ${_selectedGrade?.id})');
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }

  /// Build reset button to discard unsaved changes
  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _resetChanges,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text(
          'إلغاء التغييرات',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Reset all changes to original values
  void _resetChanges() {
    if (_loggedUser == null) return;

    setState(() {
      // Reset text controllers
      _nameController.text = _loggedUser!.name ?? '';
      _emailController.text = _loggedUser!.email ?? '';
      _phoneController.text = _loggedUser!.phone ?? '';

      // Reset address fields from mapAddress first, then from profile
      final mapAddress = _loggedUser!.mapAddress;
      if (mapAddress != null) {
        _selectedGovernorateModel = mapAddress.governorate;
        _selectedRegionModel = mapAddress.region;
        _selectedGovernorate = _selectedGovernorateModel?.governorate;
        _selectedArea = _selectedRegionModel?.region;
        _blockController.text = mapAddress.blockNumber ?? '';
        _streetController.text = mapAddress.streetNumber ?? '';
        _houseController.text = mapAddress.houseNumber ?? '';
      } else {
        _selectedGovernorateModel = _loggedUser!.profile?.governorate;
        _selectedRegionModel = _loggedUser!.profile?.region;
        _selectedGovernorate = _selectedGovernorateModel?.governorate;
        _selectedArea = _selectedRegionModel?.region;
        _blockController.clear();
        _streetController.clear();
        _houseController.clear();
      }

      // Reset selected grade
      _selectedGrade = _loggedUser!.profile?.grade;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء جميع التغييرات'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMultiSelectDialog(
      String label, List<String> selectedItems, List<String> options) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selectedItems.contains(option);
              return CheckboxListTile(
                title: Text(option),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedItems.add(option);
                    } else {
                      selectedItems.remove(option);
                    }
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    try {
      // Update local user model with current form values
      if (_loggedUser != null) {
        _loggedUser!.name = _nameController.text.trim();
        _loggedUser!.email = _emailController.text.trim();
        _loggedUser!.phone = _phoneController.text.trim();
        if (_loggedUser!.profile != null) {
          _loggedUser!.profile!.governorateId = _selectedGovernorateModel?.id;
          _loggedUser!.profile!.regionId = _selectedRegionModel?.id;
          _loggedUser!.profile!.governorate = _selectedGovernorateModel;
          _loggedUser!.profile!.region = _selectedRegionModel;
          _loggedUser!.profile!.grade = _selectedGrade;
        }
      }

      // Call API to update profile
      final success = await ref.read(ApiProviders.loginProvider).updateProfile(
            context: context,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            address: '', // Keep empty or build from address fields
            gradeId: _selectedGrade?.id ?? 0,
            governorateId: _selectedGovernorateModel?.id,
            regionId: _selectedRegionModel?.id,
            blockNumber: _blockController.text.trim(),
            streetNumber: _streetController.text.trim(),
            houseNumber: _houseController.text.trim(),
          );

      if (success && mounted) {
        // Show success message
        // _loadProfileData();
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء حفظ التغييرات'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showGovernorateDialog() {
    if (_governorates.isEmpty) {
      CommonComponents.showCustomizedSnackBar(
        context: context,
        title: 'لا توجد محافظات متاحة',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر المحافظة'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _governorates.length,
              itemBuilder: (context, index) {
                final governorate = _governorates[index];
                final isSelected =
                    _selectedGovernorateModel?.id == governorate.id;
                return ListTile(
                  title: Text(governorate.governorate ?? ''),
                  trailing: isSelected
                      ? Icon(Icons.check, color: context.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedGovernorateModel = governorate;
                      _selectedGovernorate = governorate.governorate;
                      // Clear region when governorate changes
                      _selectedRegionModel = null;
                      _selectedArea = null;
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

  void _showAreaDialog() {
    if (_selectedGovernorate == null) {
      CommonComponents.showCustomizedSnackBar(
        context: context,
        title: 'يرجى اختيار المحافظة أولاً',
      );
      return;
    }

    if (_regions.isEmpty) {
      CommonComponents.showCustomizedSnackBar(
        context: context,
        title: 'لا توجد مناطق متاحة',
      );
      return;
    }

    var selectedGovernorateId = _selectedGovernorateModel?.id;
    var areas = _regions
        .where((e) => e.governorateId == selectedGovernorateId)
        .toList();

    if (areas.isEmpty) {
      CommonComponents.showCustomizedSnackBar(
        context: context,
        title: 'لا توجد مناطق متاحة لهذه المحافظة',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر المنطقة'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: areas.length,
              itemBuilder: (context, index) {
                final region = areas[index];
                final isSelected = _selectedRegionModel?.id == region.id;
                return ListTile(
                  title: Text(region.region),
                  trailing: isSelected
                      ? Icon(Icons.check, color: context.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedRegionModel = region;
                      _selectedArea = region.region;
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
}
