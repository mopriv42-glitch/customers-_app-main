import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_4t_app/core/analytics/analytics_network_interceptor.dart';
import 'package:private_4t_app/core/services/storage_service.dart';
import 'package:private_4t_app/core/utils/constants.dart';

/// Provides a pre-configured Dio instance with auth header injection
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Constants.baseUrl, // Update Constants.baseUrl when needed
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  final storageService = ref.watch(storageServiceProvider);

  // Add analytics interceptor FIRST to capture all requests
  dio.interceptors.add(AnalyticsNetworkInterceptor());

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // TODO: Optionally handle 401 → token refresh
        return handler.next(e);
      },
    ),
  );

  return dio;
});

/// High-level API abstraction used by repositories
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});

class ApiService {
  final Dio _dio;
  ApiService(this._dio);

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return _dio.delete(path);
  }
}
