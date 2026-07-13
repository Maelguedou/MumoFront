import '../../../../core/utils/result.dart';
import '../entities/service_point_creation_result.dart';
import '../repositories/service_point_repository.dart';

class CreateServicePointUseCase {
  const CreateServicePointUseCase(this._repository);

  final ServicePointRepository _repository;

  Future<Result<ServicePointCreationResult>> call({
    required String nameService,
    required String typeAgent,
    String? name,
    String? lastname,
    String? email,
    String? phone,
    String? npi,
    String? userId,
  }) {
    return _repository.createServicePoint(
      nameService: nameService,
      typeAgent: typeAgent,
      name: name,
      lastname: lastname,
      email: email,
      phone: phone,
      npi: npi,
      userId: userId,
    );
  }
}
