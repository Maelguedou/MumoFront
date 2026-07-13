import '../../../../core/utils/result.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<Result<AuthUser>> login(String npi, String password);

  Future<Result<AuthUser>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String npi,
    required String password,
    required String passwordConfirmation,
  });

  Future<Result<AuthUser>> getCurrentUser();

  Future<Result<AuthUser>> updateProfile({
    String? name,
    String? lastname,
    String? email,
    String? phone,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  });

  Future<Result<void>> logout();
}
