import 'package:flutter/material.dart';
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/core/models/lib_item_model.dart';
import 'package:private_4t_app/core/models/lib_sub_section_model.dart';

class LibraryProvider extends ChangeNotifier {
  final List<LibItemModel> libItemsList = [];
  final List<LibItemModel> educationInstitutesList = [];
  final List<LibSubSectionModel> libSubSectionList = [];
  LibItemModel? libItemModel;
  bool isLoading = false;

  Future<void> getItems(BuildContext context, String? type) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'library/items?type=$type',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );
      debugPrint(data.toString());
      if (data != null && data.containsKey('data')) {
        var items = (data['data'] ?? []) as List;

        libItemsList.clear();
        libItemsList.addAll(
          items.map(
            (e) => LibItemModel.fromJson(e as Map<String, dynamic>),
          ),
        );
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: "Library get items error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getItem(BuildContext context, String itemId) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'library/items/$itemId',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );
      debugPrint(data.toString());
      if (data != null && data.containsKey('data')) {
        var item = data['data'];
        if (item != null) {
          libItemModel = LibItemModel.fromJson(item);
          debugPrint(libItemModel?.file?.toJson().toString());
        }
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: "Library get item error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getSubSections(BuildContext context, String? itemType) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'library/sub-sections?item_type=$itemType',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );

      if (data != null && data.containsKey('data')) {
        var subSections = data['data'] ?? [];

        libSubSectionList.clear();
        libSubSectionList.addAll(
          subSections.map(
            (e) => LibSubSectionModel.fromJson(e as Map<String, dynamic>),
          ),
        );
      }
    } catch (e) {
      debugPrint("Library get items error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches education institutes list as LibSubSectionModel[]
  Future<void> getEducationInstitutes(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      Map<String, dynamic>? data = await ApiRequests.getApiRequests(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'library/educations-institutes',
        headers: {
          "Authorization":
              "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
        },
      );

      if (data != null && data.containsKey('data')) {
        final institute = LibSubSectionModel.fromJson(data['data']);
        debugPrint(institute.items.toString());
        if (institute.items != null && institute.items!.isNotEmpty) {
          educationInstitutesList.clear();
          educationInstitutesList.addAll(institute.items!.map((i) => i));
        }
      }
    } catch (e, s) {
      debugPrintStack(
          stackTrace: s, label: "Library get education institutes error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addComment({
    required BuildContext context,
    required String comment,
  }) async {
    try {
      Map<String, dynamic>? data = await ApiRequests.postApiRequest(
          context: context,
          baseUrl: ApiKeys.baseUrl,
          apiUrl: "library/items/${libItemModel?.id.toString()}/comments",
          headers: {
            "Authorization":
                "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}"
          },
          body: {
            "comment": comment,
          });

      if (data != null) {
        if (data.containsKey('message')) {
          if (context.mounted) {
            CommonComponents.showCustomizedSnackBar(
                context: context, title: data['message']);
          }
        }

        if (data.containsKey('status') && data['status'] == 'success') {
          return true;
        }
      }
    } catch (e, stack) {
      debugPrintStack(
          stackTrace: stack, label: "Add comment api error => ${e.toString()}");
    } finally {
      notifyListeners();
    }

    return false;
  }
}
