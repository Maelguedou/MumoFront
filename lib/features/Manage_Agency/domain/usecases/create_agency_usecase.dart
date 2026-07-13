import '../../../../core/utils/result.dart';
import '../entities/agency.dart';
import '../repositories/agency_repository.dart';

class CreateAgencyUseCase {
  const CreateAgencyUseCase(this._repository);

  final AgencyRepository _repository;

  Future<Result<Agency>> call({
    required String name,
    required String location,
  }) {
    return _repository.createAgency(
      name: name,
      location: location,
    );
  }
}
