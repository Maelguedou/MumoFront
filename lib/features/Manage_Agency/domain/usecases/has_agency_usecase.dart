import '../../../../core/utils/result.dart';
import '../entities/agency.dart';
import '../repositories/agency_repository.dart';

class HasAgencyUseCase {
  const HasAgencyUseCase(this._repository);

  final AgencyRepository _repository;

  Future<Result<Agency>> call() {
    return _repository.hasAgency();
  }
}
