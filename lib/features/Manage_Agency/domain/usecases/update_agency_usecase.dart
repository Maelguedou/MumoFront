import '../../../../core/utils/result.dart';
import '../entities/agency.dart';
import '../repositories/agency_repository.dart';

class UpdateAgencyUseCase {
  const UpdateAgencyUseCase(this._repository);

  final AgencyRepository _repository;

  Future<Result<Agency>> call({
    required String id,
    required String name,
    required String location,
  }) {
    return _repository.updateAgency(
      id: id,
      name: name,
      location: location,
    );
  }
}