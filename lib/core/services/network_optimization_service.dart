import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Network optimization service for better API performance
class NetworkOptimizationService {
  static NetworkOptimizationService? _instance;
  static NetworkOptimizationService get instance =>
      _instance ??= NetworkOptimizationService._();

  NetworkOptimizationService._();

  // Network monitoring
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _networkQualityTimer;

  // Network state
  bool _isConnected = true;
  bool _isWifiConnected = false;
  bool _isMobileConnected = false;
  NetworkQuality _currentQuality = NetworkQuality.excellent;

  // Connection quality thresholds
  static const Duration _excellentLatency = Duration(milliseconds: 100);
  static const Duration _goodLatency = Duration(milliseconds: 300);
  static const Duration _poorLatency = Duration(milliseconds: 1000);

  // Cache settings
  static const Duration _wifiCacheTimeout = Duration(minutes: 10);
  static const Duration _mobileCacheTimeout = Duration(minutes: 5);
  static const Duration _offlineCacheTimeout = Duration(hours: 24);

  /// Initialize network optimization
  void initialize() {
    if (kDebugMode) {
      developer.log('Initializing Network Optimization Service',
          name: 'Network');
    }

    _startConnectivityMonitoring();
    _startNetworkQualityMonitoring();
  }

  /// Start connectivity monitoring
  void _startConnectivityMonitoring() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      _isConnected = !results.contains(ConnectivityResult.none);
      _isWifiConnected = results.contains(ConnectivityResult.wifi);
      _isMobileConnected = results.contains(ConnectivityResult.mobile);

      if (kDebugMode) {
        developer.log(
          'Network Status Changed:\n'
          'Connected: $_isConnected\n'
          'WiFi: $_isWifiConnected\n'
          'Mobile: $_isMobileConnected',
          name: 'Network',
        );
      }

      _updateNetworkQuality();
    });
  }

  /// Start network quality monitoring
  void _startNetworkQualityMonitoring() {
    _networkQualityTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _measureNetworkQuality();
    });
  }

  /// Measure current network quality
  void _measureNetworkQuality() {
    // Simulate network quality measurement
    // In a real app, you'd measure actual API response times
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    Duration simulatedLatency;

    if (random < 300) {
      simulatedLatency = _excellentLatency;
      _currentQuality = NetworkQuality.excellent;
    } else if (random < 700) {
      simulatedLatency = _goodLatency;
      _currentQuality = NetworkQuality.good;
    } else {
      simulatedLatency = _poorLatency;
      _currentQuality = NetworkQuality.poor;
    }

    if (kDebugMode) {
      developer.log(
        'Network Quality: ${_currentQuality.name} (${simulatedLatency.inMilliseconds}ms)',
        name: 'Network',
      );
    }
  }

  /// Update network quality based on connection type
  void _updateNetworkQuality() {
    if (!_isConnected) {
      _currentQuality = NetworkQuality.offline;
    } else if (_isWifiConnected) {
      _currentQuality = NetworkQuality.excellent;
    } else if (_isMobileConnected) {
      _currentQuality = NetworkQuality.good;
    }
  }

  /// Get optimal cache timeout for current network
  Duration getOptimalCacheTimeout() {
    switch (_currentQuality) {
      case NetworkQuality.excellent:
        return _wifiCacheTimeout;
      case NetworkQuality.good:
        return _mobileCacheTimeout;
      case NetworkQuality.poor:
        return _mobileCacheTimeout;
      case NetworkQuality.offline:
        return _offlineCacheTimeout;
    }
  }

  /// Get optimal retry count for current network
  int getOptimalRetryCount() {
    switch (_currentQuality) {
      case NetworkQuality.excellent:
        return 1; // Excellent connection, minimal retries
      case NetworkQuality.good:
        return 2; // Good connection, moderate retries
      case NetworkQuality.poor:
        return 3; // Poor connection, more retries
      case NetworkQuality.offline:
        return 0; // Offline, no retries
    }
  }

  /// Get optimal timeout for current network
  Duration getOptimalTimeout() {
    switch (_currentQuality) {
      case NetworkQuality.excellent:
        return const Duration(seconds: 10);
      case NetworkQuality.good:
        return const Duration(seconds: 20);
      case NetworkQuality.poor:
        return const Duration(seconds: 30);
      case NetworkQuality.offline:
        return const Duration(seconds: 60);
    }
  }

  /// Check if should use aggressive caching
  bool shouldUseAggressiveCaching() {
    return _currentQuality == NetworkQuality.poor ||
        _currentQuality == NetworkQuality.offline;
  }

  /// Check if should preload data
  bool shouldPreloadData() {
    return _currentQuality == NetworkQuality.excellent && _isWifiConnected;
  }

  /// Check if should compress requests
  bool shouldCompressRequests() {
    return _currentQuality == NetworkQuality.poor || _isMobileConnected;
  }

  /// Get network statistics
  Map<String, dynamic> getNetworkStats() {
    return {
      'isConnected': _isConnected,
      'isWifiConnected': _isWifiConnected,
      'isMobileConnected': _isMobileConnected,
      'networkQuality': _currentQuality.name,
      'optimalCacheTimeout': getOptimalCacheTimeout().inMinutes,
      'optimalRetryCount': getOptimalRetryCount(),
      'optimalTimeout': getOptimalTimeout().inSeconds,
      'shouldUseAggressiveCaching': shouldUseAggressiveCaching(),
      'shouldPreloadData': shouldPreloadData(),
      'shouldCompressRequests': shouldCompressRequests(),
    };
  }

  /// Dispose service
  void dispose() {
    _connectivitySubscription?.cancel();
    _networkQualityTimer?.cancel();

    if (kDebugMode) {
      developer.log('Network Optimization Service disposed', name: 'Network');
    }
  }
}

/// Network quality levels
enum NetworkQuality {
  excellent,
  good,
  poor,
  offline,
}

/// Network-optimized API client
class OptimizedApiClient {
  static final OptimizedApiClient _instance = OptimizedApiClient._();
  static OptimizedApiClient get instance => _instance;

  OptimizedApiClient._();

  /// Make optimized API request
  Future<Map<String, dynamic>> makeRequest(
    String endpoint, {
    Map<String, dynamic>? data,
    String method = 'GET',
  }) async {
    final networkService = NetworkOptimizationService.instance;
    final timeout = networkService.getOptimalTimeout();
    final retryCount = networkService.getOptimalRetryCount();

    if (kDebugMode) {
      developer.log(
        'Making optimized API request:\n'
        'Endpoint: $endpoint\n'
        'Method: $method\n'
        'Timeout: ${timeout.inSeconds}s\n'
        'Retry Count: $retryCount',
        name: 'ApiClient',
      );
    }

    // Simulate API request
    await Future.delayed(Duration(
        milliseconds: 100 + (DateTime.now().millisecondsSinceEpoch % 200)));

    // Simulate response
    return {
      'success': true,
      'data': {'message': 'Optimized API response'},
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Preload data based on network conditions
  Future<void> preloadData(List<String> endpoints) async {
    final networkService = NetworkOptimizationService.instance;

    if (!networkService.shouldPreloadData()) {
      if (kDebugMode) {
        developer.log('Skipping preload - network conditions not optimal',
            name: 'ApiClient');
      }
      return;
    }

    if (kDebugMode) {
      developer.log('Preloading data for ${endpoints.length} endpoints',
          name: 'ApiClient');
    }

    // Preload data in background
    for (final endpoint in endpoints) {
      try {
        await makeRequest(endpoint);
      } catch (e) {
        if (kDebugMode) {
          developer.log('Error preloading $endpoint: $e', name: 'ApiClient');
        }
      }
    }
  }
}

/// Network-aware caching strategy
class NetworkAwareCache {
  static final NetworkAwareCache _instance = NetworkAwareCache._();
  static NetworkAwareCache get instance => _instance;

  NetworkAwareCache._();

  final Map<String, CacheEntry> _cache = {};

  /// Get cached data with network-aware strategy
  T? getCachedData<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    final networkService = NetworkOptimizationService.instance;
    final optimalTimeout = networkService.getOptimalCacheTimeout();

    if (DateTime.now().difference(entry.timestamp) > optimalTimeout) {
      // Cache expired
      _cache.remove(key);
      return null;
    }

    if (kDebugMode) {
      developer.log('Cache hit for key: $key', name: 'Cache');
    }

    return entry.data as T;
  }

  /// Cache data with network-aware strategy
  void cacheData<T>(String key, T data) {
    final networkService = NetworkOptimizationService.instance;
    final timeout = networkService.getOptimalCacheTimeout();

    _cache[key] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      timeout: timeout,
    );

    if (kDebugMode) {
      developer.log(
          'Cached data for key: $key with timeout: ${timeout.inMinutes} minutes',
          name: 'Cache');
    }
  }

  /// Clear expired cache entries
  void clearExpiredEntries() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _cache.entries) {
      if (now.difference(entry.value.timestamp) > entry.value.timeout) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    if (kDebugMode && keysToRemove.isNotEmpty) {
      developer.log('Cleared ${keysToRemove.length} expired cache entries',
          name: 'Cache');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalEntries': _cache.length,
      'cacheSize': _cache.values
          .fold<int>(0, (sum, entry) => sum + entry.data.toString().length),
    };
  }
}

/// Cache entry model
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration timeout;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.timeout,
  });
}
