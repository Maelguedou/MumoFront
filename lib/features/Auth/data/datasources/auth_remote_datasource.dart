import '../../../../core/api/api_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _apiClient.post('/login', data: request.toJson());
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      return LoginResponse.fromJson(payload);
    }
    return LoginResponse.fromJson(<String, dynamic>{});
  }

  Future<RegisterResponse> register(RegisterRequest request) async {
    final response = await _apiClient.post('/register', data: request.toJson());
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      return RegisterResponse.fromJson(payload);
    }
    return RegisterResponse.fromJson(<String, dynamic>{});
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get('/user');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      return UserModel.fromJson(payload);
    }
    return UserModel();
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/update', data: data);
    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      final payload = responseData['data'] is Map<String, dynamic>
          ? responseData['data'] as Map<String, dynamic>
          : responseData;
      
      // If the API returns the user nested in 'user' key (based on Laravel controller: $data['user'] = ...)
      final userJson = payload['user'] is Map<String, dynamic>
          ? payload['user'] as Map<String, dynamic>
          : payload;
          
      return UserModel.fromJson(userJson);
    }
    return UserModel();
  }

  Future<void> logout() async {
    await _apiClient.post('/logout');
  }
}
