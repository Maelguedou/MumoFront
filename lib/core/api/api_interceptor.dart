import 'package:dio/dio.dart';
import '../storage/token_storage.dart'; // ← pour TokenStorage

class ApiInterceptor extends Interceptor {
  ApiInterceptor(this._tokenStorage);
  final TokenStorage _tokenStorage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}