import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:private_4t_app/core/services/notification_permissions_service.dart';

class PermissionsProvider extends StateNotifier<PermissionsState> {
  PermissionsProvider() : super(PermissionsState()) {
    // لا نطلب الأذونات تلقائياً عند الإنشاء — نتركها للاستدعاء الصريح
    // _initialize() كانت تسبب شاشة سوداء بسبب فقدان FlutterActivity للتركيز
    // _initialize();
  }

  /// Check all permissions status
  Future<void> _checkAllPermissions() async {
    try {
      final permissions = await NotificationPermissionsService.requestAllPermissions();
      
      state = state.copyWith(
        notificationPermission: permissions[Permission.notification] ?? PermissionStatus.denied,
        microphonePermission: permissions[Permission.microphone] ?? PermissionStatus.denied,
        cameraPermission: permissions[Permission.camera] ?? PermissionStatus.denied,
        locationPermission: permissions[Permission.location] ?? PermissionStatus.denied,
        phonePermission: permissions[Permission.phone] ?? PermissionStatus.denied,
        photosPermission: permissions[Permission.photos] ?? PermissionStatus.denied,
        storagePermission: permissions[Permission.storage] ?? PermissionStatus.denied,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Request all permissions
  Future<void> requestAllPermissions() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final permissions = await NotificationPermissionsService.requestAllPermissions();
      
      state = state.copyWith(
        notificationPermission: permissions[Permission.notification] ?? PermissionStatus.denied,
        microphonePermission: permissions[Permission.microphone] ?? PermissionStatus.denied,
        cameraPermission: permissions[Permission.camera] ?? PermissionStatus.denied,
        locationPermission: permissions[Permission.location] ?? PermissionStatus.denied,
        phonePermission: permissions[Permission.phone] ?? PermissionStatus.denied,
        photosPermission: permissions[Permission.photos] ?? PermissionStatus.denied,
        storagePermission: permissions[Permission.storage] ?? PermissionStatus.denied,
        ignoreBatteryOptimizationsPermission: permissions[Permission.ignoreBatteryOptimizations] ?? PermissionStatus.denied,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Request specific permission
  Future<void> requestPermission(Permission permission) async {
    try {
      final status = await NotificationPermissionsService.requestPermission(permission);
      
      state = state.copyWith(
        notificationPermission: permission == Permission.notification ? status : state.notificationPermission,
        microphonePermission: permission == Permission.microphone ? status : state.microphonePermission,
        cameraPermission: permission == Permission.camera ? status : state.cameraPermission,
        locationPermission: permission == Permission.location ? status : state.locationPermission,
        phonePermission: permission == Permission.phone ? status : state.phonePermission,
        photosPermission: permission == Permission.photos ? status : state.photosPermission,
        storagePermission: permission == Permission.storage ? status : state.storagePermission,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Request notification permissions
  Future<void> requestNotificationPermissions() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final isGranted = await NotificationPermissionsService.requestNotificationPermissions();
      
      if (isGranted) {
        state = state.copyWith(
          notificationPermission: PermissionStatus.granted,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          notificationPermission: PermissionStatus.denied,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Request call permissions
  Future<void> requestCallPermissions() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final isGranted = await NotificationPermissionsService.requestCallPermissions();
      
      if (isGranted) {
        state = state.copyWith(
          microphonePermission: PermissionStatus.granted,
          cameraPermission: PermissionStatus.granted,
          phonePermission: PermissionStatus.granted,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Check if all required permissions are granted
  bool get areAllPermissionsGranted {
    return state.notificationPermission.isGranted &&
           state.microphonePermission.isGranted &&
           state.cameraPermission.isGranted &&
           state.locationPermission.isGranted &&
           state.phonePermission.isGranted &&
           state.photosPermission.isGranted;
  }

  /// Check if notification permissions are granted
  bool get areNotificationPermissionsGranted {
    return state.notificationPermission.isGranted;
  }

  /// Check if call permissions are granted
  bool get areCallPermissionsGranted {
    return state.microphonePermission.isGranted &&
           state.cameraPermission.isGranted &&
           state.phonePermission.isGranted;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh permissions
  Future<void> refreshPermissions() async {
    await _checkAllPermissions();
  }
}

class PermissionsState {
  final PermissionStatus notificationPermission;
  final PermissionStatus microphonePermission;
  final PermissionStatus cameraPermission;
  final PermissionStatus locationPermission;
  final PermissionStatus phonePermission;
  final PermissionStatus photosPermission;
  final PermissionStatus storagePermission;
  final PermissionStatus ignoreBatteryOptimizationsPermission;
  final bool isLoading;
  final String? error;

  PermissionsState({
    this.notificationPermission = PermissionStatus.denied,
    this.microphonePermission = PermissionStatus.denied,
    this.cameraPermission = PermissionStatus.denied,
    this.locationPermission = PermissionStatus.denied,
    this.phonePermission = PermissionStatus.denied,
    this.photosPermission = PermissionStatus.denied,
    this.storagePermission = PermissionStatus.denied,
    this.ignoreBatteryOptimizationsPermission = PermissionStatus.denied,
    this.isLoading = true,
    this.error,
  });

  PermissionsState copyWith({
    PermissionStatus? notificationPermission,
    PermissionStatus? microphonePermission,
    PermissionStatus? cameraPermission,
    PermissionStatus? locationPermission,
    PermissionStatus? phonePermission,
    PermissionStatus? photosPermission,
    PermissionStatus? storagePermission,
    PermissionStatus? ignoreBatteryOptimizationsPermission,
    bool? isLoading,
    String? error,
  }) {
    return PermissionsState(
      notificationPermission: notificationPermission ?? this.notificationPermission,
      microphonePermission: microphonePermission ?? this.microphonePermission,
      cameraPermission: cameraPermission ?? this.cameraPermission,
      locationPermission: locationPermission ?? this.locationPermission,
      phonePermission: phonePermission ?? this.phonePermission,
      photosPermission: photosPermission ?? this.photosPermission,
      storagePermission: storagePermission ?? this.storagePermission,
      ignoreBatteryOptimizationsPermission: ignoreBatteryOptimizationsPermission ?? this.ignoreBatteryOptimizationsPermission,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final permissionsProvider = StateNotifierProvider<PermissionsProvider, PermissionsState>(
  (ref) => PermissionsProvider(),
);
