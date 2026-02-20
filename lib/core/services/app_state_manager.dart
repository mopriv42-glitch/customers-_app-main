import 'dart:async';
import 'package:flutter/material.dart';

/// Manages app state transitions and ensures proper WebRTC initialization
@pragma('vm:entry-point')
class AppStateManager {
  // Singleton
  @pragma('vm:entry-point')
  static final AppStateManager _instance = AppStateManager._internal();

  @pragma('vm:entry-point')
  factory AppStateManager() => _instance;

  @pragma('vm:entry-point')
  AppStateManager._internal();

  // Current app lifecycle state
  @pragma('vm:entry-point')
  AppLifecycleState _currentState = AppLifecycleState.resumed;

  // Stream for listening to app state changes
  @pragma('vm:entry-point')
  final StreamController<AppLifecycleState> _stateController =
  StreamController<AppLifecycleState>.broadcast();

  @pragma('vm:entry-point')
  AppLifecycleState get currentState => _currentState;

  @pragma('vm:entry-point')
  Stream<AppLifecycleState> get stateStream => _stateController.stream;

  /// Indicates if the app is in background
  @pragma('vm:entry-point')
  bool get inBackground =>
      _currentState == AppLifecycleState.paused ||
          _currentState == AppLifecycleState.inactive;

  /// Indicates if the app is in foreground
  @pragma('vm:entry-point')
  bool get inForeground => _currentState == AppLifecycleState.resumed;

  /// Initialize lifecycle observer
  @pragma('vm:entry-point')
  void initialize() {
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  /// Update state internally
  @pragma('vm:entry-point')
  void _updateState(AppLifecycleState newState) {
    if (_currentState != newState) {
      debugPrint('App state changed: $_currentState -> $newState');
      _currentState = newState;
      _stateController.add(newState);

      // Handle state-specific logic
      _handleStateChange(newState);
    }
  }

  @pragma('vm:entry-point')
  void _handleStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed - ensuring WebRTC is ready');
        _ensureWebRTCReady();
        break;
      case AppLifecycleState.paused:
        debugPrint('App paused - maintaining call connections');
        break;
      case AppLifecycleState.detached:
        debugPrint('App detached - cleaning up resources');
        break;
      case AppLifecycleState.inactive:
        debugPrint('App inactive - maintaining state');
        break;
      case AppLifecycleState.hidden:
        debugPrint('App hidden - maintaining call connections');
        break;
    }
  }

  @pragma('vm:entry-point')
  void _ensureWebRTCReady() {
    debugPrint('Ensuring WebRTC readiness for foreground state');
    // هنا تقدر تحط أي كود لضمان جاهزية المكالمات
  }

  @pragma('vm:entry-point')
  void dispose() {
    _stateController.close();
  }
}

@pragma('vm:entry-point')
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final AppStateManager _manager;

  _AppLifecycleObserver(this._manager);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _manager._updateState(state);
  }
}