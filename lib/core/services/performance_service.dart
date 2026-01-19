import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';

/// Performance monitoring and optimization service
class PerformanceService {
  static PerformanceService? _instance;
  static PerformanceService get instance =>
      _instance ??= PerformanceService._();

  PerformanceService._();

  // Performance metrics
  final List<double> _frameTimes = [];
  final int _maxFrameTimesSamples = 60; // Keep last 60 frame times
  Timer? _performanceTimer;
  int _frameCount = 0;

  // Memory optimization
  Timer? _memoryCleanupTimer;
  static const Duration _memoryCleanupInterval = Duration(minutes: 5);

  /// Initialize performance monitoring
  void initialize() {
    if (kDebugMode) {
      _startPerformanceMonitoring();
    }
    _startMemoryCleanup();
  }

  /// Start monitoring frame performance
  void _startPerformanceMonitoring() {
    SchedulerBinding.instance.addTimingsCallback(_onFrame);

    _performanceTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _logPerformanceMetrics();
    });
  }

  /// Handle frame timing callback
  void _onFrame(List<FrameTiming> timings) {
    if (timings.isEmpty) return;

    for (final timing in timings) {
      final frameTime =
          timing.totalSpan.inMicroseconds / 1000.0; // Convert to milliseconds

      _frameTimes.add(frameTime);
      if (_frameTimes.length > _maxFrameTimesSamples) {
        _frameTimes.removeAt(0);
      }

      _frameCount++;

      // Log severe frame drops (> 33ms for 30fps)
      if (frameTime > 33.0) {
        developer.log(
          'Frame drop detected: ${frameTime.toStringAsFixed(2)}ms',
          name: 'Performance',
        );
      }
    }
  }

  /// Log performance metrics
  void _logPerformanceMetrics() {
    if (_frameTimes.isEmpty) return;

    final avgFrameTime =
        _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    final maxFrameTime = _frameTimes.reduce((a, b) => a > b ? a : b);
    final minFrameTime = _frameTimes.reduce((a, b) => a < b ? a : b);

    final fps = 1000.0 / avgFrameTime;

    developer.log(
      'Performance Metrics:\n'
      'FPS: ${fps.toStringAsFixed(1)}\n'
      'Avg Frame Time: ${avgFrameTime.toStringAsFixed(2)}ms\n'
      'Max Frame Time: ${maxFrameTime.toStringAsFixed(2)}ms\n'
      'Min Frame Time: ${minFrameTime.toStringAsFixed(2)}ms\n'
      'Total Frames: $_frameCount',
      name: 'Performance',
    );
  }

  /// Start automatic memory cleanup
  void _startMemoryCleanup() {
    _memoryCleanupTimer = Timer.periodic(_memoryCleanupInterval, (timer) {
      triggerMemoryCleanup();
    });
  }

  /// Trigger memory cleanup manually
  void triggerMemoryCleanup() {
    // Force garbage collection
    if (kDebugMode) {
      developer.log('Triggering memory cleanup', name: 'Performance');
    }

    // Clear image cache if it's getting too large
    PaintingBinding.instance.imageCache.clear();

    // Clear network image cache
    PaintingBinding.instance.imageCache.clearLiveImages();

    // Force garbage collection
    SystemChannels.platform.invokeMethod('System.gc');
  }

  /// Optimize for low-end devices
  void optimizeForLowEndDevices() {
    // Reduce image cache size
    PaintingBinding.instance.imageCache.maximumSize =
        50; // Reduced from default 1000
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        50 << 20; // 50MB instead of 100MB

    developer.log('Optimized for low-end devices', name: 'Performance');
  }

  /// Optimize for high-end devices
  void optimizeForHighEndDevices() {
    // Increase image cache size
    PaintingBinding.instance.imageCache.maximumSize = 200;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20; // 200MB

    developer.log('Optimized for high-end devices', name: 'Performance');
  }

  /// Get current performance stats
  Map<String, dynamic> getPerformanceStats() {
    if (_frameTimes.isEmpty) {
      return {
        'avgFps': 0,
        'avgFrameTime': 0,
        'maxFrameTime': 0,
        'frameCount': _frameCount,
      };
    }

    final avgFrameTime =
        _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    final maxFrameTime = _frameTimes.reduce((a, b) => a > b ? a : b);
    final fps = 1000.0 / avgFrameTime;

    return {
      'avgFps': fps,
      'avgFrameTime': avgFrameTime,
      'maxFrameTime': maxFrameTime,
      'frameCount': _frameCount,
      'imageCacheSize': PaintingBinding.instance.imageCache.currentSize,
      'imageCacheBytes': PaintingBinding.instance.imageCache.currentSizeBytes,
    };
  }

  /// Check if device is low-end based on performance
  bool isLowEndDevice() {
    if (_frameTimes.isEmpty) return false;

    final avgFrameTime =
        _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    final fps = 1000.0 / avgFrameTime;

    // Consider device low-end if average FPS is below 45
    return fps < 45.0;
  }

  /// Measure execution time of a function
  static Future<T> measureExecutionTime<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();

      if (kDebugMode) {
        developer.log(
          '$operationName took ${stopwatch.elapsedMilliseconds}ms',
          name: 'Performance',
        );
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      developer.log(
        '$operationName failed after ${stopwatch.elapsedMilliseconds}ms: $e',
        name: 'Performance',
      );
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _performanceTimer?.cancel();
    _memoryCleanupTimer?.cancel();

    if (kDebugMode) {
      SchedulerBinding.instance.removeTimingsCallback(_onFrame);
    }
  }
}

/// Mixin for widgets that need performance optimization
mixin PerformanceOptimizedWidget {
  /// Debounce function calls
  Timer? _debounceTimer;

  void debounce(VoidCallback callback,
      {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  void disposeDebouncer() {
    _debounceTimer?.cancel();
  }

  /// Throttle function calls
  DateTime? _lastThrottleTime;

  void throttle(VoidCallback callback,
      {Duration duration = const Duration(milliseconds: 100)}) {
    final now = DateTime.now();
    if (_lastThrottleTime == null ||
        now.difference(_lastThrottleTime!) > duration) {
      _lastThrottleTime = now;
      callback();
    }
  }
}
