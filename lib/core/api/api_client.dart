import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_config.dart';
import 'api_interceptor.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
  }) {
    return _dio.get<T>(path, queryParameters: query, options: options);
  }

  Future<Response<T>> post<T>(String path, {dynamic data, Options? options}) {
    return _dio.post<T>(path, data: data, options: options);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path, {dynamic data}) {
    return _dio.delete<T>(path, data: data);
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 3. LE PROVIDER — c'est lui que login_controller.dart importe
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
final apiClientProvider = Provider<ApiClient>((ref) {
  // On récupère le tokenStorage depuis son provider
  final tokenStorage = ref.read(tokenStorageProvider);
  // On configure Dio
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // On retourne un ApiClient avec ce Dio configuré
  dio.interceptors.add(ApiInterceptor(tokenStorage));

  // Intercepteur de logs pour le développement
  dio.interceptors.add(
    LogInterceptor(
      requestBody: false, // évite d'exposer un PIN dans les logs
      responseBody: false, // évite d'exposer un code USSD composé
      error: true, // affiche les erreurs
    ),
  );

  return ApiClient(dio);
});
