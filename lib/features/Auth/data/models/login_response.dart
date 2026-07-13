import '../user_model.dart';

class LoginResponse {
  final String token;
  final UserModel user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final roleJson = json['role'];
    final normalizedUserJson = userJson is Map<String, dynamic>
        ? Map<String, dynamic>.from(userJson)
        : <String, dynamic>{};

    final contexts = json['contexts'];
    if (contexts is List) {
      normalizedUserJson['contexts'] = contexts;
    }
    if (contexts is List && contexts.isNotEmpty) {
      final firstContext = contexts.first;
      if (firstContext is Map &&
          (normalizedUserJson['role'] == null ||
              normalizedUserJson['role'].toString().isEmpty)) {
        normalizedUserJson['role'] = firstContext['role']?.toString();
      }
    }

    normalizedUserJson['role'] ??= roleJson;

    return LoginResponse(
      token: (json['token'] as String?) ?? '',
      user: UserModel.fromJson(normalizedUserJson),
    );
  }
}
