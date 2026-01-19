import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class OfflineModeNotifier extends StateNotifier<OfflineModeState> {
  OfflineModeNotifier() : super(const OfflineModeState()) {
    _loadSettings();
    _initConnectivityListener();
  }

  static const String _offlineModeKey = 'offline_mode_enabled';
  static const String _syncOnWifiKey = 'sync_on_wifi_only';
  static const String _autoDownloadKey = 'auto_download_enabled';

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isOfflineModeEnabled = prefs.getBool(_offlineModeKey) ?? false;
      final syncOnWifiOnly = prefs.getBool(_syncOnWifiKey) ?? true;
      final autoDownloadEnabled = prefs.getBool(_autoDownloadKey) ?? false;

      state = state.copyWith(
        isOfflineModeEnabled: isOfflineModeEnabled,
        syncOnWifiOnly: syncOnWifiOnly,
        autoDownloadEnabled: autoDownloadEnabled,
      );
    } catch (e) {
      debugPrint('Error loading offline settings: $e');
    }
  }

  void _initConnectivityListener() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final isConnected = !results.contains(ConnectivityResult.none);
      final isWifi = results.contains(ConnectivityResult.wifi);

      state = state.copyWith(
        isConnected: isConnected,
        isWifiConnected: isWifi,
      );

      // Auto-sync when conditions are met
      if (isConnected &&
          (!state.syncOnWifiOnly || isWifi) &&
          !state.isOfflineModeEnabled) {
        _triggerAutoSync();
      }
    });
  }

  Future<void> setOfflineMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineModeKey, enabled);

      state = state.copyWith(isOfflineModeEnabled: enabled);

      if (!enabled && state.isConnected) {
        _triggerAutoSync();
      }
    } catch (e) {
      debugPrint('Error saving offline mode: $e');
    }
  }

  Future<void> setSyncOnWifiOnly(bool wifiOnly) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_syncOnWifiKey, wifiOnly);

      state = state.copyWith(syncOnWifiOnly: wifiOnly);
    } catch (e) {
      debugPrint('Error saving wifi sync setting: $e');
    }
  }

  Future<void> setAutoDownload(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoDownloadKey, enabled);

      state = state.copyWith(autoDownloadEnabled: enabled);
    } catch (e) {
      debugPrint('Error saving auto download setting: $e');
    }
  }

  void _triggerAutoSync() {
    // Trigger background sync of cached data
    debugPrint('🔄 Auto-sync triggered');
    // This would typically sync with your API
  }

  void manualSync() {
    if (state.isConnected && (!state.syncOnWifiOnly || state.isWifiConnected)) {
      _triggerAutoSync();
    }
  }

  bool get canPerformNetworkOperations {
    if (state.isOfflineModeEnabled) return false;
    if (!state.isConnected) return false;
    if (state.syncOnWifiOnly && !state.isWifiConnected) return false;
    return true;
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}

class OfflineModeState {
  final bool isOfflineModeEnabled;
  final bool isConnected;
  final bool isWifiConnected;
  final bool syncOnWifiOnly;
  final bool autoDownloadEnabled;
  final DateTime? lastSyncTime;

  const OfflineModeState({
    this.isOfflineModeEnabled = false,
    this.isConnected = true,
    this.isWifiConnected = false,
    this.syncOnWifiOnly = true,
    this.autoDownloadEnabled = false,
    this.lastSyncTime,
  });

  OfflineModeState copyWith({
    bool? isOfflineModeEnabled,
    bool? isConnected,
    bool? isWifiConnected,
    bool? syncOnWifiOnly,
    bool? autoDownloadEnabled,
    DateTime? lastSyncTime,
  }) {
    return OfflineModeState(
      isOfflineModeEnabled: isOfflineModeEnabled ?? this.isOfflineModeEnabled,
      isConnected: isConnected ?? this.isConnected,
      isWifiConnected: isWifiConnected ?? this.isWifiConnected,
      syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
      autoDownloadEnabled: autoDownloadEnabled ?? this.autoDownloadEnabled,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  String get connectionStatus {
    if (!isConnected) return 'غير متصل';
    if (isWifiConnected) return 'متصل عبر WiFi';
    return 'متصل عبر البيانات الخلوية';
  }

  Color get connectionStatusColor {
    if (!isConnected) return Colors.red;
    if (isWifiConnected) return Colors.green;
    return Colors.white;
  }
}

// Provider for offline mode management
final offlineModeProvider =
    StateNotifierProvider<OfflineModeNotifier, OfflineModeState>((ref) {
  return OfflineModeNotifier();
});
