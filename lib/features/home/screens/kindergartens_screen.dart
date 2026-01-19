import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/extensions/context_extension.dart';
import 'package:private_4t_app/core/models/governorate_model.dart';
import 'package:private_4t_app/core/models/region_model.dart';
import 'package:private_4t_app/core/widgets/app_header.dart';
import 'package:private_4t_app/core/analytics/analytics_screen_mixin.dart';

class KindergartensScreen extends ConsumerStatefulWidget {
  const KindergartensScreen({super.key});

  @override
  ConsumerState<KindergartensScreen> createState() =>
      _KindergartensScreenState();
}

class _KindergartensScreenState extends ConsumerState<KindergartensScreen> with AnalyticsScreenMixin {
  GovernorateModel? selectedGovernorate;
  RegionModel? selectedRegion;
  
  @override
  String get screenName => 'Kindergartensscreen';
  

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(ApiProviders.homeProvider).getRegionsAndGovernorates(context));
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(ApiProviders.homeProvider);
    final governorates = home.governorates;
    final regions = home.regions
        .where((r) => selectedGovernorate == null
            ? true
            : r.governorateId == (selectedGovernorate!.id ?? 0))
        .toList();
    final rng = Random();
    final List<_MockPlace> items = List.generate(12, (i) {
      final num = rng.nextInt(9000) + 1000;
      return _MockPlace(
        name: 'حضانة رقم $num',
        address:
            'العنوان: شارع ${rng.nextInt(50) + 1}, مبنى ${rng.nextInt(20) + 1}',
        phone: '5${rng.nextInt(9000000) + 1000000}',
        logoColor: Colors.primaries[i % Colors.primaries.length],
      );
    });

    final filtered = items; // placeholder until real filtering is needed

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: const AppHeader(
          title: 'الحضانات',
          showCart: false,
          showProfile: false,
          showNotifications: false,
          showBackButton: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _GovernorateDropdown(
                      value: selectedGovernorate,
                      items: governorates,
                      onChanged: (g) {
                        setState(() {
                          selectedGovernorate = g;
                          selectedRegion = null;
                        });
                      },
                    )),
                    SizedBox(width: 12.w),
                    Expanded(
                        child: _RegionDropdown(
                      value: selectedRegion,
                      items: regions,
                      onChanged: (r) {
                        setState(() => selectedRegion = r);
                      },
                    )),
                  ],
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _PlaceCard(place: filtered[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GovernorateDropdown extends StatelessWidget {
  final GovernorateModel? value;
  final List<GovernorateModel> items;
  final ValueChanged<GovernorateModel?> onChanged;

  const _GovernorateDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<GovernorateModel>(
      decoration: const InputDecoration(labelText: 'اختر المحافظة'),
      value: value,
      items: items
          .map((g) =>
              DropdownMenuItem(value: g, child: Text(g.governorate ?? '')))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _RegionDropdown extends StatelessWidget {
  final RegionModel? value;
  final List<RegionModel> items;
  final ValueChanged<RegionModel?> onChanged;

  const _RegionDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<RegionModel>(
      decoration: const InputDecoration(labelText: 'اختر المنطقة'),
      value: value,
      items: items
          .map((r) => DropdownMenuItem(value: r, child: Text(r.region)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _MockPlace {
  final String name;
  final String address;
  final String phone;
  final Color logoColor;

  _MockPlace({
    required this.name,
    required this.address,
    required this.phone,
    required this.logoColor,
  });
}

class _PlaceCard extends StatelessWidget {
  final _MockPlace place;

  const _PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: place.logoColor.withOpacity(0.15),
            child: Icon(Icons.child_care, color: place.logoColor),
          ),
          SizedBox(height: 8.h),
          Text(place.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
          SizedBox(height: 6.h),
          Text(place.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.secondaryText, fontSize: 11.sp)),
          SizedBox(height: 6.h),
          Row(
            children: [
              const Icon(Icons.phone, size: 14, color: Colors.grey),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(place.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: context.secondaryText, fontSize: 11.sp)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
