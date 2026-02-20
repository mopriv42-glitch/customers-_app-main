import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:private_4t_app/app_config/api_keys.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/app_config/api_requests.dart';
import 'package:private_4t_app/app_config/common_components.dart';
import 'package:private_4t_app/app_config/device_info_controller.dart';
import 'package:private_4t_app/core/analytics/analytics_service.dart';
import 'package:private_4t_app/core/models/customer_role_model.dart';
import 'package:private_4t_app/core/models/governorate_model.dart';
import 'package:private_4t_app/core/models/grade_model.dart';
import 'package:private_4t_app/core/models/region_model.dart';
import 'package:private_4t_app/core/models/subject_model.dart';
import 'package:private_4t_app/core/models/user_model.dart';
import 'package:private_4t_app/core/providers/app_container.dart';
import 'package:private_4t_app/core/providers/matrix_chat_provider.dart';
import 'package:riverpod_context/riverpod_context.dart';

import '../../models/platform_model.dart';

class LoginProvider extends ChangeNotifier {
  UserModel? loggedUser;
  final List<SubjectModel> subjectsList = [];
  final List<GradeModel> gradesList = [];
  final List<CustomerRoleModel> customerRolesList = [];
  final List<PlatformModel> platformsList = [];
  final List<GovernorateModel> governoratesList = [];
  final List<RegionModel> regionsList = [];

  bool isLoading = false;
  bool _isGotLoggedUser = false;

  bool get isGotLoggedUser => _isGotLoggedUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final List<String> scopes = <String>[
    'https://www.googleapis.com/auth/contacts.readonly',
  ];

  Future<bool> loginWithEmail({
    required BuildContext context,
    required String email,
    required String password,
    String? userPassword,
  }) async {
    String? fcmToken, apnToken;

    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
      apnToken = await FirebaseMessaging.instance.getAPNSToken();
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace, label: e.toString());
      fcmToken = '';
      apnToken = '';
    }

    Map<String, dynamic>? data = await ApiRequests.postApiRequest(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: "login",
      headers: {},
      body: {
        'email': email,
        'password': password,
        'fcmToken': fcmToken ?? "",
        'apn_token': apnToken ?? "",
        'platform': Platform.isIOS
            ? 'ios'
            : Platform.isAndroid
                ? "android"
                : "",
        'device_info': await DeviceInfoController.getDeviceInfo(),
      },
    );

    if (data != null && data.containsKey('token')) {
      if (context.mounted) {
        await _implementAfterSuccessLogin(context, data);
      }
      return true;
    } else {
      if (context.mounted) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: data?['message'] ?? 'Something wrong',
        );
      }
      return false;
    }
  }

  Future<bool> userConfirmOTP({
    required BuildContext context,
    required String userPhone,
    required String userCode,
    required String userGrade,
  }) async {
    String? fcmToken, apnToken;

    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
      apnToken = await FirebaseMessaging.instance.getAPNSToken();
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace, label: e.toString());
      fcmToken = '';
      apnToken = '';
    }

    Map<String, dynamic>? data = await ApiRequests.postApiRequest(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: "confirm-otp",
      headers: {},
      body: {
        "phone": userPhone,
        'code': userCode,
        'grade_id': userGrade,
        'fcmToken': fcmToken ?? "",
        'apn_token': apnToken ?? "",
        'platform': Platform.isIOS
            ? 'ios'
            : Platform.isAndroid
                ? "android"
                : "",
        'device_info': await DeviceInfoController.getDeviceInfo(),
      },
    );

    if (data != null && data.containsKey('token')) {
      if (context.mounted) {
        await _implementAfterSuccessLogin(context, data);
      }

      if (data.containsKey('is_new') && data['is_new']) {
        await CommonComponents.saveData(key: 'is_new', value: true);
      }

      return true;
    } else {
      if (context.mounted) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: data?['message'],
        );
      }
      return false;
    }
  }

  Future<bool> userLogin({
    required BuildContext context,
    required String userPhone,
  }) async {
    Map<String, dynamic>? data = await ApiRequests.postApiRequest(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: "login-phone",
      headers: {},
      body: {"phone": userPhone},
    );

    if (data != null) {
      if (context.mounted && data.containsKey('message')) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: "${data['message']}",
        );
      }

      if (data.containsKey('success')) {
        return true;
      }
    }
    return false;
  }

  Future<bool> userRegister({
    required BuildContext context,
    required String userName,
    required String userEmail,
  }) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    final apnToken = await FirebaseMessaging.instance.getAPNSToken();

    final data = await ApiRequests.postApiRequest(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: 'login/google',
      headers: {},
      body: {
        'email': userEmail,
        'name': userName,
        'fcmToken': fcmToken ?? '',
        'apn_token': apnToken ?? '',
        'platform': Platform.isIOS
            ? 'ios'
            : Platform.isAndroid
                ? "android"
                : "",
        'device_info': await DeviceInfoController.getDeviceInfo(),
      },
    );

    if (data != null && data.containsKey('token')) {
      if (context.mounted) {
        await _implementAfterSuccessLogin(context, data);
      }
      isLoading = false;
      notifyListeners();

      return true;
    }

    if (context.mounted) {
      CommonComponents.showCustomizedSnackBar(
        context: context,
        title: (data?['message'] ?? 'فشل تسجيل الدخول عبر جوجل').toString(),
      );
    }
    return false;
  }

  Future<GoogleSignInAccount?> googleAuthentication() async {
    GoogleSignInAccount? userData;
    await _googleSignIn.initialize(
      // clientId: Platform.isIOS
      //     ? ApiKeys.googleIOSClientId
      //     : Platform.isAndroid
      //         ? ApiKeys.googleAndroidClientId
      //         : null,
      serverClientId: ApiKeys.googleAndroidServerId,
    );

    _googleSignIn.authenticationEvents
        .listen((GoogleSignInAuthenticationEvent event) async {
      debugPrint(event.toString());
      userData = switch (event) {
        GoogleSignInAuthenticationEventSignIn() => event.user,
        GoogleSignInAuthenticationEventSignOut() => null,
      };

      final GoogleSignInClientAuthorization? authorization =
          await userData?.authorizationClient.authorizationForScopes(scopes);

      if (userData != null && authorization != null) {
        unawaited(_handleGetContact(userData!));
      }
    }).onError((Object e) async {
      debugPrint(
        e is GoogleSignInException
            ? _errorMessageFromSignInException(e)
            : 'Unknown error: $e',
      );
    });

    if (_googleSignIn.supportsAuthenticate()) {
      userData = await _googleSignIn.authenticate();
    }

    return userData;
  }

  Future<bool> signInWithGoogle({required BuildContext context}) async {
    isLoading = true;
    notifyListeners();
    try {
      // // Ensure plugin is initialized (provide serverClientId on Android)
      // serverClientId: Platform.isIOS
      //     ? ApiKeys.googleIOSClientId
      //     : Platform.isAndroid
      //         ? ApiKeys.googleAndroidServerClientId
      //         : null,
      GoogleSignInAccount? userData = await googleAuthentication();

      final idToken = (() {
        try {
          return userData?.authentication.idToken;
        } catch (_) {}
        return null;
      })();

      final email = (() {
        try {
          return userData?.email;
        } catch (_) {}

        return null;
      })();

      final displayName = (() {
        try {
          return userData?.displayName;
        } catch (_) {}
        return null;
      })();

      final photoUrl = (() {
        try {
          return userData?.photoUrl;
        } catch (_) {}
        return null;
      })();

      if (idToken == null) {
        isLoading = false;
        notifyListeners();

        if (context.mounted) {
          CommonComponents.showCustomizedSnackBar(
            context: context,
            title: 'لا يوجد رمز من جوجل (idToken)',
          );
        }

        return false;
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();
      final apnToken = await FirebaseMessaging.instance.getAPNSToken();

      final data = await ApiRequests.postApiRequest(
        context: context,
        baseUrl: ApiKeys.baseUrl,
        apiUrl: 'login/google',
        headers: {},
        body: {
          'id_token': idToken,
          'email': email,
          'name': displayName,
          'avatar': photoUrl,
          'fcmToken': fcmToken ?? '',
          'apn_token': apnToken ?? '',
          'platform': Platform.isIOS
              ? 'ios'
              : Platform.isAndroid
                  ? "android"
                  : "",
          'device_info': await DeviceInfoController.getDeviceInfo(),
        },
      );

      if (data != null && data.containsKey('token')) {
        if (context.mounted) {
          await _implementAfterSuccessLogin(context, data);
        }
        isLoading = false;
        notifyListeners();

        return true;
      }

      if (context.mounted) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: (data?['message'] ?? 'فشل تسجيل الدخول عبر جوجل').toString(),
        );
      }

      isLoading = false;
      notifyListeners();

      return false;
    } catch (e, stackTrace) {
      isLoading = false;
      notifyListeners();

      if (context.mounted) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: 'حدث خطأ أثناء تسجيل الدخول عبر جوجل',
        );
      }

      debugPrintStack(stackTrace: stackTrace, label: e.toString());

      return false;
    }
  }

  Future<void> _implementAfterSuccessLogin(
    BuildContext context,
    Map data,
  ) async {
    if (data.containsKey('token')) {
      await CommonComponents.saveData(
        key: ApiKeys.userToken,
        value: data['token'],
      );
    }

    if (data.containsKey('user')) {
      await CommonComponents.saveData(
        key: ApiKeys.userName,
        value: data['user']['name'],
      );

      await CommonComponents.saveData(
        key: ApiKeys.userID,
        value: data['user']['id'],
      );

      await CommonComponents.saveData(
        key: ApiKeys.userImage,
        value: data['user']['photo_url'],
      );

      await CommonComponents.saveData(
        key: ApiKeys.userPhone,
        value: data['user']['phone'],
      );

      loggedUser = UserModel.fromJson(data['user']);

      // Update analytics userId
      AnalyticsService.instance.userId = loggedUser?.id?.toString();
      AnalyticsService.instance.logEvent(
        'user_login',
        properties: {
          'user_id': loggedUser?.id?.toString(),
          'user_name': loggedUser?.name?.toString(),
          'user_phone': loggedUser?.phone.toString(),
          'user_email': loggedUser?.email?.toString(),
        },
      );

      _applyThemeFromUserPlatform();

      notifyListeners();
      final matrix = context.read(ApiProviders.matrixChatProvider);

      if (!matrix.isInitialized) {
        matrix.init().then((_) async {
          // Check if server provided Matrix credentials directly
          if (data.containsKey('matrix') && data['matrix'] != null) {
            final matrixData = data['matrix'] as Map<String, dynamic>;
            final userId = matrixData['user_id'] as String?;
            final accessToken = matrixData['access_token'] as String?;
            final homeserver = matrixData['homeserver'] as String? ??
                'https://matrix.private-4t.com';

            if (userId != null &&
                userId.isNotEmpty &&
                accessToken != null &&
                accessToken.isNotEmpty) {
              // Use token-based authentication (new server flow)
              try {
                final success = await matrix.loginWithAccessToken(
                  userId: userId,
                  accessToken: accessToken,
                  homeserver: homeserver,
                );
                if (success) {
                  debugPrint(
                    'Matrix token login successful for user: $userId',
                  );
                } else {
                  debugPrint(
                    'Matrix token login failed, will try auto-provisioning fallback',
                  );
                  // Fallback to old method if token login fails
                  _fallbackToAutoProvisioning(matrix, loggedUser);
                }
              } catch (e, s) {
                debugPrintStack(
                  label: 'Error during Matrix token login: ${e.toString()}',
                  stackTrace: s,
                );
                // Fallback to old method on error
                _fallbackToAutoProvisioning(matrix, loggedUser);
              }
            } else {
              debugPrint('Matrix credentials incomplete, using fallback');
              _fallbackToAutoProvisioning(matrix, loggedUser);
            }
          } else if (!matrix.isLoggedIn && loggedUser != null) {
            // Fallback: Auto-provision user if server didn't provide Matrix token
            _fallbackToAutoProvisioning(matrix, loggedUser);
          }
        });
      } else if (data.containsKey('matrix') && data['matrix'] != null) {
        // Matrix already initialized, try token login directly
        final matrixData = data['matrix'] as Map<String, dynamic>;
        final userId = matrixData['user_id'] as String?;
        final accessToken = matrixData['access_token'] as String?;
        final homeserver = matrixData['homeserver'] as String? ??
            'https://matrix.private-4t.com';

        if (userId != null &&
            userId.isNotEmpty &&
            accessToken != null &&
            accessToken.isNotEmpty &&
            !matrix.isLoggedIn) {
          matrix.loginWithAccessToken(
            userId: userId,
            accessToken: accessToken,
            homeserver: homeserver,
          ).then((success) {
            if (success) {
              debugPrint('Matrix token login successful for user: $userId');
            } else {
              debugPrint('Matrix token login failed');
              _fallbackToAutoProvisioning(matrix, loggedUser);
            }
          }).catchError((e, s) {
            debugPrintStack(
              label: 'Error during Matrix token login: ${e.toString()}',
              stackTrace: s,
            );
            _fallbackToAutoProvisioning(matrix, loggedUser);
          });
        }
      }
    }


    notifyListeners();
  }

  /// Fallback to auto-provisioning when token-based Matrix auth fails
  void _fallbackToAutoProvisioning(
    MatrixChatProvider matrix,
    UserModel? user,
  ) {
    if (user == null) {
      debugPrint('Cannot fallback to auto-provisioning: user is null');
      return;
    }

    try {
      if (matrix.canAutoProvision(user)) {
        matrix.autoProvisionUser(appUser: user).then((result) {
          if (result.success) {
            debugPrint('Auto-provisioning successful: ${result.message}');
          } else {
            debugPrint('Auto-provisioning failed: ${result.message}');
          }
        }).catchError((e, s) {
          debugPrintStack(
            label: 'Error during auto-provisioning: ${e.toString()}',
            stackTrace: s,
          );
        });
      } else {
        debugPrint('User cannot be auto-provisioned (missing phone number)');
      }
    } catch (e) {
      debugPrint('Error during auto-provisioning fallback: $e');
    }
  }

  Future<void> userLogout({required BuildContext context}) async {
    Map<String, dynamic>? data = await ApiRequests.postApiRequest(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: "logout",
      headers: {
        'Authorization':
            "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
      },
      body: {'token': await FirebaseMessaging.instance.getToken() ?? ''},
      showLoadingWidget: true,
    );

    if (data != null) {
      if (!data.containsKey('errors')) {
        await CommonComponents.deleteSavedData(ApiKeys.userName);
        await CommonComponents.deleteSavedData(ApiKeys.userCartToken);
        await CommonComponents.deleteSavedData(ApiKeys.userPhone);
        await CommonComponents.deleteSavedData(ApiKeys.userID);
        await CommonComponents.deleteSavedData(ApiKeys.userToken);
        loggedUser = null;
        // await ?awaitPusherController.disconnect();
        await FirebaseMessaging.instance.deleteToken();
        if (context.mounted) {
          try {
            await context.read(ApiProviders.matrixChatProvider).logout();
          } catch (_) {}
          // AppNavigator.toRouteAndReplaceAll(PATHS.onBoardingScreen);
        }
      }

      if (context.mounted) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: data['message'] ?? 'تم تسجيل الخروج',
        );
      }
    }

    notifyListeners();
  }

  Future<void> deleteAccount({
    required BuildContext context,
    required String notes,
  }) async {
    Map<String, dynamic>? data = await ApiRequests.postApiRequest(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: "delete-account",
      headers: {
        'Authorization':
            "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
      },
      body: {
        'token': await FirebaseMessaging.instance.getToken(),
        'notes': notes,
      },
      showLoadingWidget: true,
    );

    if (data != null) {
      if (!data.containsKey('errors')) {
        await CommonComponents.deleteSavedData(ApiKeys.userToken);
        // await PusherControlle?r.disconnect();
        // AppNavigator.toRouteAndReplaceAll(PATHS.onBoardingScreen);
        if (context.mounted) {
          try {
            await context.read(ApiProviders.matrixChatProvider).logout();
          } catch (_) {}
        }
      }

      if (context.mounted) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: data['message'],
        );
      }
    }
  }

  Future<bool> getLoggedUser({BuildContext? context}) async {
    final token = await CommonComponents.getSavedData(ApiKeys.userToken);

    if (token == null) return false;

    Map<String, dynamic>? data = await ApiRequests.getApiRequests(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: "user",
      headers: {'Authorization': "Bearer $token"},
    );

    if (data != null) {
      if (data.containsKey('user')) {
        loggedUser = UserModel.fromJson(data['user']);
        _isGotLoggedUser = true;

        await CommonComponents.saveData(
          key: ApiKeys.userID,
          value: loggedUser?.id?.toString(),
        );

        // Update analytics userId
        AnalyticsService.instance.userId = loggedUser?.id?.toString();

        // Apply theme based on user platform
        _applyThemeFromUserPlatform();

        notifyListeners();
        return true;
      } else if (data.containsKey('message')) {
        await CommonComponents.deleteSavedData(ApiKeys.userToken);
      }
    }
    _isGotLoggedUser = true;
    notifyListeners();
    return false;
  }

  /// Apply theme based on user platform
  void _applyThemeFromUserPlatform() {
    try {
      final platform = loggedUser?.profile?.platform;
      if (platform != null) {
        // Get the theme provider from the global container
        final themeProvider = providerAppContainer.read(
          ApiProviders.themeProvider.notifier,
        );

        themeProvider.setBrandFromPlatform(platform);

        debugPrint('🎨 Applied theme based on platform: $platform');
      }
    } catch (e) {
      debugPrint('❌ Error applying theme from platform: $e');
    }
  }

  /// Update user platform and apply theme
  Future<void> updateUserPlatform(PlatformModel platform) async {
    try {
      if (loggedUser?.profile != null) {
        loggedUser!.profile!.platform = platform.code.toString();
        _applyThemeFromUserPlatform();
        notifyListeners();
        debugPrint('✅ Updated user platform to: $platform');
      }
    } catch (e) {
      debugPrint('❌ Error updating user platform: $e');
    }
  }

  Future<void> profile(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    Map<String, dynamic>? data = await ApiRequests.getApiRequests(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: "profile",
      headers: {
        'Authorization':
            "Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}",
      },
    );

    if (data != null) {
      if (data.containsKey('data')) {
        var dataMap = data['data'];
        loggedUser = UserModel.fromJson(dataMap['user']);
        var grades = (dataMap['grades'] ?? []) as List;
        var subjects = (dataMap['subjects'] ?? []) as List;
        var governorates = (dataMap['governorates'] ?? []) as List;
        var regions = (dataMap['regions'] ?? []) as List;

        if (subjects.isNotEmpty) {
          subjectsList.clear();
          subjectsList.addAll(
            subjects
                .map((e) => SubjectModel.fromJson(e as Map<String, dynamic>)),
          );
        }

        if (grades.isNotEmpty) {
          gradesList.clear();
          gradesList.addAll(
            grades.map((e) => GradeModel.fromJson(e as Map<String, dynamic>)),
          );
        }

        if (governorates.isNotEmpty) {
          governoratesList.clear();
          governoratesList.addAll(
            governorates.map(
                (e) => GovernorateModel.fromJson(e as Map<String, dynamic>)),
          );
        }

        if (regions.isNotEmpty) {
          regionsList.clear();
          regionsList.addAll(
            regions.map((e) => RegionModel.fromJson(e as Map<String, dynamic>)),
          );
        }
      } else if (data.containsKey('message')) {
        await CommonComponents.deleteSavedData(ApiKeys.userToken);
      }
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> updateName({
    required BuildContext context,
    required String name,
    required String? customerRoleId,
    required String? platformId,
  }) async {
    isLoading = true;
    notifyListeners();

    Map<String, dynamic>? data = await ApiRequests.putRequests(
      context: context,
      apiUrl: "me/update-name",
      body: {
        "name": name,
        "customer_role": customerRoleId ?? '',
        "platform": platformId ?? '',
      },
    );

    if (data != null) {
      if (data.containsKey('message')) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: data['message'],
        );
      }

      if (data.containsKey('data')) {
        var dataMap = data['data'];
        loggedUser = UserModel.fromJson(dataMap['user']);
        CommonComponents.deleteSavedData('is_new');
        return true;
      }
    }
    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> initAuth(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    Map<String, dynamic>? data = await ApiRequests.getApiRequests(
      context: context,
      baseUrl: ApiKeys.baseUrl,
      apiUrl: "auth",
      headers: {},
    );

    if (data != null) {
      if (data.containsKey('data')) {
        var dataMap = data['data'];
        var grades = (dataMap['grades'] ?? []) as List;
        var customerRoles = (dataMap['customer_roles'] ?? []) as List;
        var platforms = (dataMap['platforms'] ?? []) as List;

        if (grades.isNotEmpty) {
          gradesList.clear();
          gradesList.addAll(
            grades.map((e) => GradeModel.fromJson(e as Map<String, dynamic>)),
          );
        }

        if (customerRoles.isNotEmpty) {
          customerRolesList.clear();
          customerRolesList.addAll(
            customerRoles.map(
              (e) => CustomerRoleModel.fromJson(e as Map<String, dynamic>),
            ),
          );
        }

        if (platforms.isNotEmpty) {
          platformsList.clear();
          platformsList.addAll(
            platforms.map(
              (e) => PlatformModel.fromJson(e as Map<String, dynamic>),
            ),
          );
        }
      }
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required BuildContext context,
    required String name,
    required String email,
    required String phone,
    required String address,
    required int gradeId,
    String? avatarFilePath,
    int? governorateId,
    int? regionId,
    String? blockNumber,
    String? streetNumber,
    String? houseNumber,
  }) async {
    try {
      if (!context.mounted) return false;
      final uri = Uri.parse('${ApiKeys.baseUrl}profile');
      if (avatarFilePath != null && avatarFilePath.isNotEmpty) {
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll({
          'Accept': 'application/json',
          'Accept-Language': 'ar',
          'Authorization':
              'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
        });
        request.fields.addAll({
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          'grade': gradeId.toString(),
          if (governorateId != null) 'governorate': governorateId.toString(),
          if (regionId != null) 'region': regionId.toString(),
          if (blockNumber != null && blockNumber.isNotEmpty)
            'block_number': blockNumber,
          if (streetNumber != null && streetNumber.isNotEmpty)
            'street_number': streetNumber,
          if (houseNumber != null && houseNumber.isNotEmpty)
            'building_number': houseNumber,
        });
        request.files.add(
          await http.MultipartFile.fromPath('avatar', avatarFilePath),
        );
        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);
        if (context.mounted) Navigator.pop(context);
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (context.mounted) {
            CommonComponents.showCustomizedSnackBar(
              context: context,
              title: decoded['message'] ?? 'تم الحفظ',
            );
            // await profile(context);
          }
          return true;
        } else {
          if (context.mounted) {
            CommonComponents.showCustomizedSnackBar(
              context: context,
              title: decoded['message'] ?? 'فشل تحديث الملف',
            );
          }
          return false;
        }
      } else {
        final data = await ApiRequests.postApiRequest(
          context: context,
          baseUrl: ApiKeys.baseUrl,
          apiUrl: 'profile',
          headers: {
            'Authorization':
                'Bearer ${await CommonComponents.getSavedData(ApiKeys.userToken)}',
          },
          body: {
            'name': name,
            'email': email,
            'phone': phone,
            'address': address,
            'grade': gradeId.toString(),
            if (governorateId != null) 'governorate': governorateId.toString(),
            if (regionId != null) 'region': regionId.toString(),
            if (blockNumber != null && blockNumber.isNotEmpty)
              'block_number': blockNumber,
            if (streetNumber != null && streetNumber.isNotEmpty)
              'street_number': streetNumber,
            if (houseNumber != null && houseNumber.isNotEmpty)
              'building_number': houseNumber,
          },
          showLoadingWidget: true,
        ) as Map?;

        if (data != null && !(data.containsKey('errors'))) {
          if (context.mounted) {
            CommonComponents.showCustomizedSnackBar(
              context: context,
              title: data['message'] ?? 'تم الحفظ',
            );
            await profile(context);
          }
          return true;
        } else {
          if (context.mounted) {
            CommonComponents.showCustomizedSnackBar(
              context: context,
              title: (data?['message'] ?? 'فشل تحديث الملف').toString(),
            );
          }
          return false;
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        CommonComponents.showCustomizedSnackBar(
          context: context,
          title: 'حدث خطأ غير متوقع',
        );
      }
      return false;
    }
  }

  Future<void> _handleGetContact(GoogleSignInAccount user) async {
    debugPrint('Loading contact info...');
    final Map<String, String>? headers =
        await user.authorizationClient.authorizationHeaders(scopes);
    if (headers == null) {
      return;
    }
    final http.Response response = await http.get(
      Uri.parse(
        'https://people.googleapis.com/v1/people/me/connections'
        '?requestMask.includeField=person.names',
      ),
      headers: headers,
    );
    if (response.statusCode != 200) {
      if (response.statusCode == 401 || response.statusCode == 403) {
      } else {
        debugPrint(
          'People API ${response.statusCode} response: ${response.body}',
        );
      }
      return;
    }
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    debugPrint("data: ${data.toString()}");
    final String? namedContact = _pickFirstNamedContact(data);
    if (namedContact != null) {
      debugPrint('I see you know $namedContact!');
    } else {
      debugPrint('No contacts to display.');
    }
  }

  String? _pickFirstNamedContact(Map<String, dynamic> data) {
    final List<dynamic>? connections = data['connections'] as List<dynamic>?;
    final Map<String, dynamic>? contact = connections?.firstWhere(
      (dynamic contact) => (contact as Map<Object?, dynamic>)['names'] != null,
      orElse: () => null,
    ) as Map<String, dynamic>?;
    if (contact != null) {
      final List<dynamic> names = contact['names'] as List<dynamic>;
      final Map<String, dynamic>? name = names.firstWhere(
        (dynamic name) =>
            (name as Map<Object?, dynamic>)['displayName'] != null,
        orElse: () => null,
      ) as Map<String, dynamic>?;
      if (name != null) {
        return name['displayName'] as String?;
      }
    }
    return null;
  }

  String _errorMessageFromSignInException(GoogleSignInException e) {
    // In practice, an application should likely have specific handling for most
    // or all of the, but for simplicity this just handles cancel, and reports
    // the rest as generic errors.
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'Sign in canceled',
      _ => 'GoogleSignInException ${e.code}: ${e.description}',
    };
  }
}
