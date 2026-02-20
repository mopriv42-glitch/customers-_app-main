import 'dart:async';
import 'package:flutter/material.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/customer_booking_model.dart';
import 'package:private_4t_app/core/models/governorate_model.dart';
import 'package:private_4t_app/core/models/grade_model.dart';
import 'package:private_4t_app/core/models/offer_model.dart';
import 'package:private_4t_app/core/models/region_model.dart';
import 'package:private_4t_app/core/models/service_type_model.dart';
import 'package:private_4t_app/core/models/subject_model.dart';
import 'package:private_4t_app/core/models/user_address_model.dart';
import 'package:private_4t_app/core/providers/app_container.dart';
import 'package:private_4t_app/core/services/navigation_service.dart';
import 'package:riverpod_context/riverpod_context.dart';

class BookingProvider extends ChangeNotifier {
  final List<ServiceTypeModel> serviceTypesList = [];
  final List<SubjectModel> subjectsList = [];
  final List<GradeModel> gradesList = [];
  final List<GovernorateModel> governoratesList = [];
  final List<RegionModel> regionsList = [];

  CustomerBookingModel customerBooking = CustomerBookingModel.init();
  UserAddressModel userAddressModel = UserAddressModel();
  bool isLoading = false;
  bool isCalculatingPrice = false;
  int? calculatedPrice;

  // Debouncing for price calculation
  Timer? _priceCalculationTimer;
  String? _lastPriceCalculationKey;

  Future<void> initBooking(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'booking',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );
      debugPrint(data.toString());
      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];
        var grades = (dataMap['grades'] ?? []) as List;
        var subjects = (dataMap['subjects'] ?? []) as List;
        var serviceTypes = (dataMap['service_types'] ?? []) as List;

        serviceTypesList.clear();
        serviceTypesList.addAll(serviceTypes
            .map((e) => ServiceTypeModel.fromJson(e as Map<String, dynamic>)));

        subjectsList.clear();
        subjectsList.addAll(subjects
            .map((e) => SubjectModel.fromJson(e as Map<String, dynamic>)));

        gradesList.clear();
        gradesList.addAll(
            grades.map((e) => GradeModel.fromJson(e as Map<String, dynamic>)));
      }
    } catch (e) {
      debugPrint("Booking init error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getLastBooking(BuildContext context, [OfferModel? offer]) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'booking/last-booking',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );
      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];
        var grades = (dataMap['grades'] ?? []) as List;
        var subjects = (dataMap['subjects'] ?? []) as List;
        var serviceTypes = (dataMap['service_types'] ?? []) as List;

        serviceTypesList.clear();
        serviceTypesList.addAll(serviceTypes
            .map((e) => ServiceTypeModel.fromJson(e as Map<String, dynamic>)));

        subjectsList.clear();
        subjectsList.addAll(subjects
            .map((e) => SubjectModel.fromJson(e as Map<String, dynamic>)));

        gradesList.clear();
        gradesList.addAll(
            grades.map((e) => GradeModel.fromJson(e as Map<String, dynamic>)));

        if (offer == null) {
          customerBooking =
              CustomerBookingModel.fromJson(dataMap['customer_booking']);
        }
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: "Get last booking error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getDetailsBooking(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'booking/details?booking=${customerBooking.id}',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );
      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];
        var governorates = (dataMap['governorates'] ?? []) as List;
        var regions = (dataMap['regions'] ?? []) as List;

        customerBooking = CustomerBookingModel.fromJson(dataMap['booking']);

        governoratesList.clear();
        governoratesList.addAll(governorates
            .map((e) => GovernorateModel.fromJson(e as Map<String, dynamic>)));

        regionsList.clear();
        regionsList.addAll(regions
            .map((e) => RegionModel.fromJson(e as Map<String, dynamic>)));
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      debugPrint("Get last booking error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Calculate price with debouncing to prevent too many API calls
  Future<int?> calculatePrice(
    BuildContext context, {
    required int subjectId,
    required int gradeId,
    required double numberOfHours,
    int numberOfSessions = 1,
    int? teacherType,
    int? serviceTypeId,
    int? school,
    bool debounce = true,
  }) async {
    // Create a unique key for this calculation request
    final calculationKey =
        '$subjectId-$gradeId-$numberOfHours-$numberOfSessions-$teacherType-$serviceTypeId-$school';

    // Cancel previous pending calculation if same parameters
    if (debounce &&
        _priceCalculationTimer != null &&
        _lastPriceCalculationKey == calculationKey) {
      _priceCalculationTimer?.cancel();
      _priceCalculationTimer = null;
    }

    // If already calculating, cancel and wait or return cached result
    if (isCalculatingPrice && debounce) {
      _priceCalculationTimer?.cancel();
    }

    return await _executePriceCalculation(
      context,
      subjectId: subjectId,
      gradeId: gradeId,
      numberOfHours: numberOfHours,
      numberOfSessions: numberOfSessions,
      teacherType: teacherType,
      serviceTypeId: serviceTypeId,
      school: school,
    );
  }

  Future<int?> _performPriceCalculation(
    BuildContext context, {
    required int subjectId,
    required int gradeId,
    required double numberOfHours,
    int numberOfSessions = 1,
    int? teacherType,
    int? serviceTypeId,
    int? school,
    required bool debounce,
    required String calculationKey,
  }) async {
    if (debounce) {
      final completer = Completer<int?>();

      _priceCalculationTimer =
          Timer(const Duration(milliseconds: 500), () async {
        try {
          final result = await _executePriceCalculation(
            context,
            subjectId: subjectId,
            gradeId: gradeId,
            numberOfHours: numberOfHours,
            numberOfSessions: numberOfSessions,
            teacherType: teacherType,
            serviceTypeId: serviceTypeId,
            school: school,
          );
          _lastPriceCalculationKey = calculationKey;
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      });

      return completer.future;
    } else {
      return _executePriceCalculation(
        context,
        subjectId: subjectId,
        gradeId: gradeId,
        numberOfHours: numberOfHours,
        numberOfSessions: numberOfSessions,
        teacherType: teacherType,
        serviceTypeId: serviceTypeId,
        school: school,
      );
    }
  }

  Future<int?> _executePriceCalculation(
    BuildContext context, {
    required int subjectId,
    required int gradeId,
    required double numberOfHours,
    int numberOfSessions = 1,
    int? teacherType,
    int? serviceTypeId,
    int? school,
  }) async {
    // Prevent multiple simultaneous calls
    if (isCalculatingPrice) {
      return calculatedPrice;
    }

    try {
      isCalculatingPrice = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'booking/calculate-price',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
        body: {
          'subject_id': subjectId.toString(),
          'grade_id': gradeId.toString(),
          'number_of_hours': numberOfHours.toString(),
          'number_of_sessions': numberOfSessions.toString(),
          if (teacherType != null) 'teacher_type': teacherType.toString(),
          if (serviceTypeId != null)
            'service_type_id': serviceTypeId.toString(),
          if (school != null) 'school': school.toString(),
        },
        showLoadingWidget: true,
      );

      if (data != null) {
        if (data.containsKey('price')) {
          final price = data['price'];
          if (price != null) {
            calculatedPrice = price.toInt();
            notifyListeners();
            return calculatedPrice;
          } else {
            calculatedPrice = 0;
            notifyListeners();
            return calculatedPrice;
          }
        }

        if (data.containsKey('message') && context.mounted) {
          final message = data['message'] ?? 'Failed to calculate price';
          // Don't show "Too Many Attempts" error as snackbar - it's a rate limit issue
          if (!message.toString().toLowerCase().contains('too many attempts')) {
            CommonComponents.showCustomizedSnackBar(
                context: context, title: message);
          } else {
            debugPrint("Rate limit exceeded for price calculation");
          }
        }
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      debugPrint("Calculate price error: $e");
      // Don't show error snackbar for rate limiting
      if (context.mounted &&
          !e.toString().toLowerCase().contains('too many attempts')) {
        CommonComponents.showCustomizedSnackBar(
            context: context, title: 'Failed to calculate price');
      }
    } finally {
      isCalculatingPrice = false;
      notifyListeners();
    }
    return calculatedPrice;
  }

  Future<bool> createBooking(
    BuildContext context,
    CustomerBookingModel booking,
  ) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'booking',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
        body: {
          'customer_booking':
              customerBooking.id != 0 ? customerBooking.id.toString() : '',
          'service_type_id': booking.serviceTypeId.toString(),
          'subject_id': booking.subjectId.toString(),
          'grade_id': booking.gradeId.toString(),
          'booking_date': booking.bookingDate.toIso8601String(),
          'time_from': booking.timeFrom,
          'alt_time': booking.altTime ?? '',
          'number_of_hours': booking.numberOfHours.toString(),
          'price': booking.price != null ? booking.price.toString() : '',
          'offer_id': booking.offerId != null ? booking.offerId.toString() : '',
          'teacher_type': booking.teacherType != null
              ? booking.teacherType.toString()
              : '1',
          'school': booking.school != null ? booking.school.toString() : '1',
          'purpose_of_reservation': booking.purposeOfReservation ?? '',
        },
      );

      if (data != null) {
        if (data.containsKey('data')) {
          var dataMap = data['data'];

          customerBooking = CustomerBookingModel.fromJson(dataMap['booking']);
          notifyListeners();
          return true;
        }

        if (data.containsKey('message') && context.mounted) {
          CommonComponents.showCustomizedSnackBar(
              context: context, title: data['message'] ?? 'Something wrong');
        }
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      debugPrint("Get last booking error: $e");
    }
    return false;
  }

  Future<bool> sendBookingDetails(
    BuildContext context,
    UserAddressModel addressModel,
  ) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'booking/details',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
        body: {
          'region_id': addressModel.regionId != null
              ? addressModel.regionId.toString()
              : '',
          'governorate_id': addressModel.governorateId != null
              ? addressModel.governorateId.toString()
              : '',
          'block_number': addressModel.blockNumber ?? '',
          'building_number': addressModel.houseNumber ?? '',
          'street_number': addressModel.streetNumber ?? '',
        },
      );
      if (data != null && data.containsKey('success')) {
        userAddressModel = addressModel;

        if (context.mounted) {
          CommonComponents.showCustomizedSnackBar(
              context: context,
              title: data['message'] ??
                  'The booking details has been updated successfully');
        }

        notifyListeners();

        return true;
      } else {
        if (context.mounted) {
          CommonComponents.showCustomizedSnackBar(
              context: context, title: data?['message'] ?? 'Something wrong');
        }
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      debugPrint("Get last booking error: $e");
    }
    return false;
  }

  Future<void> getSummaryBooking(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'booking/summary?booking=${customerBooking.id}',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );

      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];
        var governorates = (dataMap['governorates'] ?? []) as List;
        var regions = (dataMap['regions'] ?? []) as List;
        var subjects = (dataMap['subjects'] ?? []) as List;
        var grades = (dataMap['grades'] ?? []) as List;
        debugPrint(dataMap['address'].toString());

        customerBooking = CustomerBookingModel.fromJson(dataMap['booking']);
        userAddressModel = UserAddressModel.fromJson(dataMap['address']);

        governoratesList.clear();
        governoratesList.addAll(governorates
            .map((e) => GovernorateModel.fromJson(e as Map<String, dynamic>)));

        regionsList.clear();
        regionsList.addAll(regions
            .map((e) => RegionModel.fromJson(e as Map<String, dynamic>)));

        subjectsList.clear();
        subjectsList.addAll(subjects
            .map((e) => SubjectModel.fromJson(e as Map<String, dynamic>)));

        gradesList.clear();
        gradesList.addAll(
            grades.map((e) => GradeModel.fromJson(e as Map<String, dynamic>)));
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      debugPrint("Get last booking error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendBookingSummary(
    BuildContext context,
    String name,
    String email,
  ) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'booking/summary/${customerBooking.id}',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
        body: {
          'service_type_id': customerBooking.serviceTypeId.toString(),
          'subject_id': customerBooking.subjectId.toString(),
          'grade_id': customerBooking.gradeId.toString(),
          'booking_date': customerBooking.bookingDate.toIso8601String(),
          'time_from': customerBooking.timeFrom,
          'alt_time': customerBooking.altTime ?? '',
          'number_of_hours': customerBooking.numberOfHours.toString(),
          'offer_id': customerBooking.offerId != null
              ? customerBooking.offerId.toString()
              : "",
          'price': customerBooking.price != null
              ? customerBooking.price.toString()
              : "",
          'region_id': userAddressModel.regionId != null
              ? userAddressModel.regionId.toString()
              : '',
          'governorate_id': userAddressModel.governorateId != null
              ? userAddressModel.governorateId.toString()
              : '',
          'block_number': userAddressModel.blockNumber ?? '',
          'building_number': userAddressModel.houseNumber ?? '',
          'street_number': userAddressModel.streetNumber ?? '',
          'name': name,
          'email': email,
        },
      );
      if (data != null && data.containsKey('data')) {
        var dataMap = data['data'];
        userAddressModel = UserAddressModel.fromJson(dataMap['address']);
        customerBooking = CustomerBookingModel.fromJson(dataMap['booking']);
        notifyListeners();
        return true;
      } else {
        if (context.mounted) {
          CommonComponents.showCustomizedSnackBar(
              context: context, title: data?['message'] ?? 'Something wrong');
        }
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
      debugPrint("Get last booking error: $e");
    }
    return false;
  }

  Future<String?> getPaymentLink(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      final loginProvider = context.read(ApiProviders.loginProvider);
      final loggedUser = loginProvider.loggedUser;
      var name = loggedUser?.name.toString();
      var email = loggedUser?.email.toString();
      if (loggedUser?.email == null ||
          loggedUser!.email!.isEmpty ||
          loggedUser.email!.startsWith('client') ||
          loggedUser.email!.startsWith("teacher")) {
        final googleUserData = await loginProvider.googleAuthentication();

        if (googleUserData != null) {
          name = googleUserData.displayName.toString();
          email = googleUserData.email.toString();
        }
      }

      debugPrint({'name': name, 'email': email}.toString());

      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'booking/${customerBooking.id}/payment',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
        body: {
          "name": name,
          "email": email,
        },
      );

      if (data != null) {
        if (data['success'] && data.containsKey('data')) {
          var dataMap = data['data'];
          return dataMap['link'];
        }

        if (context.mounted) {
          CommonComponents.showCustomizedSnackBar(
              context: context,
              title: data['message'] ?? "حدث خطأ ما يرجى المحاولة لاحثاً");
        }
      }
    } catch (e) {
      debugPrint("Booking init error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> implementGoogleMail() async {
    try {
      final loginProvider =
          providerAppContainer.read(ApiProviders.loginProvider);
      final loggedUser = loginProvider.loggedUser;
      if (loggedUser?.email == null ||
          loggedUser!.email!.isEmpty ||
          loggedUser.email!.startsWith('client')) {
        final googleUserData = await loginProvider.googleAuthentication();
        if (googleUserData != null) {
          Map<String, dynamic>? data = await ApiRequests.postApiRequest(
            baseUrl: ApiKeys.baseUrl,
            apiUrl: 'me/update-email',
            headers: {
              "Authorization":
                  "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
            },
            body: {
              'name': googleUserData.displayName.toString(),
              'email': googleUserData.email.toString(),
            },
          );

          if (data != null && data['success']) {
            return true;
          }

          CommonComponents.showCustomizedSnackBar(
              context: NavigationService.rootNavigatorKey.currentContext!,
              title: data?['message'] ?? "حدث خطأ ما يرجى المحاولة لاحثاً");
        }
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: e.toString());
    }

    return false;
  }

  void addOfferInCustomerBooking(int? id) {
    customerBooking.offerId = id;
    notifyListeners();
  }

  @override
  void dispose() {
    _priceCalculationTimer?.cancel();
    _priceCalculationTimer = null;
    super.dispose();
  }

  void setCustomerBooking(CustomerBookingModel booking) {
    customerBooking = booking;
    notifyListeners();
  }
}
