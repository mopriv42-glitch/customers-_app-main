import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/order_course_model.dart';
import 'package:private_4t_app/core/models/governorate_model.dart';
import 'package:private_4t_app/core/models/region_model.dart';
import 'package:private_4t_app/core/models/our_teachers_model.dart';
import 'package:private_4t_app/core/models/offer_model.dart';

class HomeProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  List<OrderCourseModel> _upcomingOrders = const [];
  Map<String, dynamic>? _stats;

  // Teachers data
  bool _teachersLoading = false;
  List<OfferModel> _offers = const [];
  List<OurTeacher> _teachers = const [];
  String? _teachersError;

  // Regions/Governorates data for filters in educational services
  bool _geoLoading = false;
  List<GovernorateModel> _governorates = const [];
  List<RegionModel> _regions = const [];

  // Caching
  DateTime? _lastDashboardFetch;
  DateTime? _lastTeachersFetch;
  DateTime? _lastGeoFetch;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  bool get isLoading => _loading;
  String? get error => _error;
  List<OrderCourseModel> get upcomingOrders => _upcomingOrders;
  Map<String, dynamic>? get stats => _stats;

  // Teachers getters
  bool get isTeachersLoading => _teachersLoading;
  List<OurTeacher> get teachers => _teachers;
  List<OfferModel> get offers => _offers;
  String? get teachersError => _teachersError;

  bool get isGeoLoading => _geoLoading;
  List<GovernorateModel> get governorates => _governorates;
  List<RegionModel> get regions => _regions;

  Future<void> fetchDashboard(BuildContext context,
      {bool forceRefresh = false}) async {
    if (_loading) return;

    // Check cache first
    if (!forceRefresh && _lastDashboardFetch != null) {
      final timeSinceLastFetch =
          DateTime.now().difference(_lastDashboardFetch!);
      if (timeSinceLastFetch < _cacheTimeout && _upcomingOrders.isNotEmpty) {
        return; // Use cached data
      }
    }

    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Use ApiRequests helper instead of apiServiceProvider
      final token = await CommonComponents.getSavedData(ApiKeys.userToken);
      final root = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'dashboard',
        headers: token == null
            ? {}
            : {
                'Authorization': 'Bearer $token',
              },
      ) as Map?;
      final data = (root?['data'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      final List upcomingJson = (data['upcoming_orders'] as List?) ?? const [];
      _upcomingOrders = upcomingJson
          .map((e) =>
              OrderCourseModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false);

      _stats = {
        'teachers_count': data['teachers_count'],
        'customer_count': data['customer_count'],
        'orders_count': data['orders_count'],
      }..removeWhere((k, v) => v == null);

      final List teachersJson = (data['our_teachers'] as List?) ?? const [];
      final List offersJson = (data['offers'] as List?) ?? const [];

      _offers = offersJson
          .map((e) => OfferModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false);

      _teachers = teachersJson
          .map((e) => OurTeacher.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
      // Update cache timestamp on successful fetch
      _lastDashboardFetch = DateTime.now();
    } catch (e, s) {
      _error = e.toString();
      debugPrintStack(stackTrace: s, label: e.toString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Fetch our teachers data
  Future<void> fetchOurTeachers(BuildContext context) async {
    if (_teachersLoading) return;
    _teachersLoading = true;
    _teachersError = null;
    notifyListeners();

    try {
      final token = await CommonComponents.getSavedData(ApiKeys.userToken);
      final root = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'our-teachers',
        headers: token == null
            ? {}
            : {
                'Authorization': 'Bearer $token',
              },
      ) as Map?;

      final data = (root?['data'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      debugPrint('our_teachers: ${data['our_teachers']}');

      final List ourTeachersJson = (data['our_teachers'] as List?) ?? const [];

      _teachers = ourTeachersJson
          .map((e) => OurTeacher.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
    } catch (e) {
      _teachersError = e.toString();
      if (kDebugMode) {
        debugPrint('fetchOurTeachers error: $e');
      }
    } finally {
      _teachersLoading = false;
      notifyListeners();
    }
  }

  // Fetch regions and governorates from single endpoint
  Future<void> getRegionsAndGovernorates(BuildContext context) async {
    if (_geoLoading) return;
    _geoLoading = true;
    notifyListeners();
    try {
      final token = await CommonComponents.getSavedData(ApiKeys.userToken);
      final root = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'regions-governorates',
        headers: token == null
            ? {}
            : {
                'Authorization': 'Bearer $token',
              },
      ) as Map?;

      final data = (root?['data'] as Map?)?.cast<String, dynamic>();
      final List regionsJson = (data?['regions'] as List?) ?? const [];
      final List governoratesJson =
          (data?['governorates'] as List?) ?? const [];

      _regions = regionsJson
          .map((e) => RegionModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
      _governorates = governoratesJson
          .map((e) =>
              GovernorateModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getRegionsAndGovernorates error: $e');
      }
    } finally {
      _geoLoading = false;
      notifyListeners();
    }
  }

  // Backward-compat simple aliases
  Future<void> getRegions(BuildContext context) =>
      getRegionsAndGovernorates(context);
  Future<void> getGovernorates(BuildContext context) =>
      getRegionsAndGovernorates(context);
}

// (no extra providers)
