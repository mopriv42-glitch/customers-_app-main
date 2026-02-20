import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/governorate_model.dart';
import 'package:private_4t_app/core/models/region_model.dart';
import 'package:private_4t_app/core/models/user_address_model.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen>
    with AnalyticsScreenMixin {
  @override
  String get screenName => 'Addressscreen';

  String? selectedGovernorate;
  String? selectedArea;
  final TextEditingController blockController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController houseController = TextEditingController();
  final ValueNotifier<bool> isFormValid = ValueNotifier(false);
  UserAddressModel _userAddressModel = UserAddressModel();
  List<GovernorateModel> governorates = [];
  List<RegionModel> regions = [];

  @override
  void initState() {
    super.initState();
    // Initialize booking data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ApiProviders.bookingProvider).getDetailsBooking(context);
    });

    blockController.addListener(_validateForm);
    streetController.addListener(_validateForm);
    houseController.addListener(_validateForm);
  }

  void _validateForm() {
    isFormValid.value = selectedGovernorate != null &&
        selectedArea != null &&
        selectedGovernorate!.isNotEmpty &&
        selectedArea!.isNotEmpty &&
        blockController.text.isNotEmpty &&
        streetController.text.isNotEmpty &&
        houseController.text.isNotEmpty;
  }

  @override
  void dispose() {
    blockController.dispose();
    streetController.dispose();
    houseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = ref.watch(ApiProviders.bookingProvider);
    bool isLoading = bookingProvider.isLoading;
    // Update the lists when data is loaded
    if (!isLoading) {
      governorates = bookingProvider.governoratesList;
      regions = bookingProvider.regionsList;
      _userAddressModel = bookingProvider.userAddressModel;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: _buildAppBar(),
        body:
            isLoading ? CommonComponents.loadingDataFromServer() : _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.primary,
      elevation: 0,
      toolbarHeight: 60.h,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'حدد العنوان',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        _buildCartIcon(),
      ],
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildFormCard(),
            SizedBox(height: 24.h),
            _buildNextButton(),
          ],
        ),
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
          _buildDropdownField(
            label: 'المحافظة',
            value: selectedGovernorate,
            placeholder: 'اختر المحافظة',
            onTap: () => _showGovernorateDialog(),
          ),
          SizedBox(height: 20.h),
          _buildDropdownField(
            label: 'المنطقة',
            value: selectedArea,
            placeholder: 'اختر المنطقة',
            onTap: selectedGovernorate != null ? () => _showAreaDialog() : null,
            isEnabled: selectedGovernorate != null,
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            label: 'رقم القطعة',
            controller: blockController,
            placeholder: 'أدخل رقم القطعة',
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            label: 'رقم الشارع',
            controller: streetController,
            placeholder: 'أدخل رقم الشارع',
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            label: 'رقم المنزل',
            controller: houseController,
            placeholder: 'أدخل رقم المنزل',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
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
            color: context.primary,
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required TextInputType keyboardType,
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: placeholder,
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
          style: TextStyle(
            fontSize: 14.sp,
            color: context.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: isFormValid,
      builder: (context, isValid, _) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isValid ? _navigateToSummary : null,
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
      },
    );
  }

  void _showGovernorateDialog() {
    if (governorates.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر المحافظة'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: governorates.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(governorates[index].governorate ?? ''),
                  onTap: () {
                    setState(() {
                      selectedGovernorate =
                          governorates[index].governorate ?? '';
                      selectedArea = null;

                      _userAddressModel.regionId = null;

                      _userAddressModel.governorateId =
                          governorates[index].id ?? 0;
                      _userAddressModel.governorate = governorates[index];
                    });
                    _validateForm();
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
    if (selectedGovernorate == null || regions.isEmpty) return;

    var selectGovernorateIndex =
        governorates.indexWhere((e) => e.governorate == selectedGovernorate);

    var selectGovernorateId = governorates[selectGovernorateIndex].id;

    var areas =
        regions.where((e) => e.governorateId == selectGovernorateId).toList();

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
                return ListTile(
                  title: Text(areas[index].region),
                  onTap: () {
                    setState(() {
                      selectedArea = areas[index].region;
                      _userAddressModel.regionId = areas[index].id;
                      _userAddressModel.region = areas[index];
                    });
                    _validateForm();
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

  void _navigateToSummary() async {
    _userAddressModel.houseNumber = houseController.text.toString();
    _userAddressModel.streetNumber = streetController.text.toString();
    _userAddressModel.blockNumber = blockController.text.toString();

    final result = await ref
        .read(ApiProviders.bookingProvider)
        .sendBookingDetails(context, _userAddressModel);

    if (mounted && result) {
      context.push('/booking-summary');
    }
  }

  /// أيقونة السلة مع عدد العناصر
  Widget _buildCartIcon() {
    return Consumer(
      builder: (context, ref, child) {
        final cartProvider = ref.watch(ApiProviders.cartProvider);
        final itemCount = cartProvider.cartModel.items?.length ?? 0;

        return GestureDetector(
          onTap: () => context.push('/cart'),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(10.r),
                child: Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              // Badge يعرض عدد العناصر
              if (itemCount > 0)
                Positioned(
                  right: 5.r,
                  top: 5.r,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16.w,
                      minHeight: 16.h,
                    ),
                    child: Text(
                      itemCount > 99 ? '99+' : itemCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
