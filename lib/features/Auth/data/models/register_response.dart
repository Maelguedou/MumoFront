import '../user_model.dart';

class RegisterResponse {
  final String token;
  final UserModel user;

  RegisterResponse({required this.token, required this.user});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return RegisterResponse(
      token: (json['token'] as String?) ?? '',
      user: UserModel.fromJson(
        userJson is Map<String, dynamic> ? userJson : <String, dynamic>{},
      ),
    );
  }
}
