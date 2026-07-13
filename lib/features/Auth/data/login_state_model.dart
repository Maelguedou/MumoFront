import '../domain/entities/auth_user.dart';

class AuthStateModel {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final AuthUser? user;

  AuthStateModel({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.user,
  });

  // Pour mettre à jour l'état sans perdre les autres données
  AuthStateModel copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    AuthUser? user,
  }) {
    return AuthStateModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      user: user ?? this.user,
    );
  }
}