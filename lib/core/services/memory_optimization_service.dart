import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// Comprehensive memory optimization service
class MemoryOptimizationService {
  static MemoryOptimizationService? _instance;
  static MemoryOptimizationService get instance =>
      _instance ??= MemoryOptimizationService._();

  MemoryOptimizationService._();

  // Memory monitoring
  Timer? _memoryMonitorTimer;
  Timer? _autoCleanupTimer;
  final List<WeakReference> _trackedObjects = [];

  // Memory thresholds
  static const int _criticalMemoryThreshold = 100; // MB
  static const int _warningMemoryThreshold = 80; // MB
  static const Duration _monitorInterval = Duration(seconds: 30);
  static const Duration _cleanupInterval = Duration(minutes: 2);

  /// Initialize memory optimization
  void initialize() {
    if (kDebugMode) {
      developer.log('Initializing Memory Optimization Service', name: 'Memory');
    }

    _startMemoryMonitoring();
    _startAutoCleanup();
    _optimizeImageCache();
    _optimizeForDevice();
  }

  /// Start memory monitoring
  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(_monitorInterval, (timer) {
      _checkMemoryUsage();
    });
  }

  /// Start automatic cleanup
  void _startAutoCleanup() {
    _autoCleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      _performAutoCleanup();
    });
  }

  /// Check current memory usage
  void _checkMemoryUsage() {
    final imageCacheSize = PaintingBinding.instance.imageCache.currentSize;
    final imageCacheBytes =
        PaintingBinding.instance.imageCache.currentSizeBytes;
    final imageCacheBytesMB = imageCacheBytes / (1024 * 1024);

    if (kDebugMode) {
      developer.log(
        'Memory Status:\n'
        'Image Cache Items: $imageCacheSize\n'
        'Image Cache Size: ${imageCacheBytesMB.toStringAsFixed(2)} MB',
        name: 'Memory',
      );
    }

    // Check thresholds
    if (imageCacheBytesMB > _criticalMemoryThreshold) {
      _performCriticalCleanup();
    } else if (imageCacheBytesMB > _warningMemoryThreshold) {
      _performWarningCleanup();
    }
  }

  /// Perform automatic cleanup
  void _performAutoCleanup() {
    if (kDebugMode) {
      developer.log('Performing automatic memory cleanup', name: 'Memory');
    }

    // Clear old images
    PaintingBinding.instance.imageCache.clearLiveImages();

    // Clear unused images
    PaintingBinding.instance.imageCache.clear();

    // Force garbage collection
    _forceGarbageCollection();

    // Clean tracked objects
    _cleanTrackedObjects();
  }

  /// Perform critical cleanup
  void _performCriticalCleanup() {
    if (kDebugMode) {
      developer.log('CRITICAL: Performing emergency memory cleanup',
          name: 'Memory');
    }

    // Aggressive cleanup
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // Clear all caches
    _clearAllCaches();

    // Force multiple garbage collections
    for (int i = 0; i < 3; i++) {
      _forceGarbageCollection();
    }
  }

  /// Perform warning cleanup
  void _performWarningCleanup() {
    if (kDebugMode) {
      developer.log('WARNING: Performing memory cleanup', name: 'Memory');
    }

    // Moderate cleanup
    PaintingBinding.instance.imageCache.clearLiveImages();
    _forceGarbageCollection();
  }

  /// Clear all available caches
  void _clearAllCaches() {
    try {
      // Clear image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Clear network image cache
      PaintingBinding.instance.imageCache.maximumSize = 0;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 0;

      // Reset cache limits
      _optimizeImageCache();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error clearing caches: $e', name: 'Memory');
      }
    }
  }

  /// Force garbage collection
  void _forceGarbageCollection() {
    try {
      SystemChannels.platform.invokeMethod('System.gc');
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error forcing garbage collection: $e', name: 'Memory');
      }
    }
  }

  /// Optimize image cache settings
  void _optimizeImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;

    // Set reasonable limits
    imageCache.maximumSize = 100; // Max 100 images
    imageCache.maximumSizeBytes = 100 << 20; // Max 100MB

    if (kDebugMode) {
      developer.log(
          'Image cache optimized: ${imageCache.maximumSize} items, ${imageCache.maximumSizeBytes ~/ (1024 * 1024)} MB',
          name: 'Memory');
    }
  }

  /// Optimize for device type
  void _optimizeForDevice() {
    // Detect device capabilities (simplified)
    final isLowEndDevice = _isLowEndDevice();

    if (isLowEndDevice) {
      _optimizeForLowEndDevice();
    } else {
      _optimizeForHighEndDevice();
    }
  }

  /// Check if device is low-end
  bool _isLowEndDevice() {
    // Simple heuristic based on available memory
    // In a real app, you'd use device_info_plus to get actual specs
    return false; // Assume high-end for now
  }

  /// Optimize for low-end devices
  void _optimizeForLowEndDevice() {
    final imageCache = PaintingBinding.instance.imageCache;

    // Very conservative settings
    imageCache.maximumSize = 25;
    imageCache.maximumSizeBytes = 25 << 20; // 25MB

    if (kDebugMode) {
      developer.log('Optimized for low-end device', name: 'Memory');
    }
  }

  /// Optimize for high-end devices
  void _optimizeForHighEndDevice() {
    final imageCache = PaintingBinding.instance.imageCache;

    // Generous settings
    imageCache.maximumSize = 200;
    imageCache.maximumSizeBytes = 200 << 20; // 200MB

    if (kDebugMode) {
      developer.log('Optimized for high-end device', name: 'Memory');
    }
  }

  /// Track object for cleanup
  void trackObject(Object object) {
    _trackedObjects.add(WeakReference(object));
  }

  /// Clean tracked objects
  void _cleanTrackedObjects() {
    _trackedObjects.removeWhere((ref) => ref.target == null);
  }

  /// Manual cleanup trigger
  void triggerCleanup() {
    if (kDebugMode) {
      developer.log('Manual cleanup triggered', name: 'Memory');
    }

    _performAutoCleanup();
  }

  /// Get memory statistics
  Map<String, dynamic> getMemoryStats() {
    final imageCache = PaintingBinding.instance.imageCache;

    return {
      'imageCacheSize': imageCache.currentSize,
      'imageCacheMaxSize': imageCache.maximumSize,
      'imageCacheBytes': imageCache.currentSizeBytes,
      'imageCacheMaxBytes': imageCache.maximumSizeBytes,
      'trackedObjects': _trackedObjects.length,
    };
  }

  /// Dispose service
  void dispose() {
    _memoryMonitorTimer?.cancel();
    _autoCleanupTimer?.cancel();
    _trackedObjects.clear();

    if (kDebugMode) {
      developer.log('Memory Optimization Service disposed', name: 'Memory');
    }
  }
}

/// Mixin for memory-optimized widgets
mixin MemoryOptimizedWidget {
  /// Track this widget for memory management
  void trackForMemory() {
    MemoryOptimizationService.instance.trackObject(this);
  }

  /// Trigger cleanup when widget is disposed
  void disposeWithCleanup() {
    MemoryOptimizationService.instance.triggerCleanup();
  }
}

/// Memory-optimized image cache manager
class OptimizedImageCache {
  static final OptimizedImageCache _instance = OptimizedImageCache._();
  static OptimizedImageCache get instance => _instance;

  OptimizedImageCache._();

  /// Preload image with memory management
  Future<void> preloadImage(String url, {int? width, int? height}) async {
    try {
      // Check memory before preloading
      final memoryStats = MemoryOptimizationService.instance.getMemoryStats();
      final currentUsage = memoryStats['imageCacheBytes'] as int;
      final maxUsage = memoryStats['imageCacheMaxBytes'] as int;

      if (currentUsage > maxUsage * 0.8) {
        // Memory is getting high, trigger cleanup
        MemoryOptimizationService.instance.triggerCleanup();
      }

      // Preload image
      final imageProvider = NetworkImage(url);
      imageProvider.resolve(ImageConfiguration.empty);
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error preloading image: $e', name: 'ImageCache');
      }
    }
  }

  /// Clear specific image from cache
  void clearImage(String url) {
    try {
      // This is a simplified approach
      // In a real implementation, you'd need to track specific images
      MemoryOptimizationService.instance.triggerCleanup();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error clearing image: $e', name: 'ImageCache');
      }
    }
  }
}
