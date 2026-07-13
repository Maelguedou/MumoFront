import '../../../../core/utils/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String npi,
    required String password,
    required String passwordConfirmation,
  }) {
    return _repository.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      npi: npi,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }
}
