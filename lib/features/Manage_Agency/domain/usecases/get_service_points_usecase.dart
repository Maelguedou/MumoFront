import '../../../../core/utils/result.dart';
import '../entities/service_point.dart';
import '../repositories/service_point_repository.dart';

class GetServicePointsUseCase {
  const GetServicePointsUseCase(this._repository);

  final ServicePointRepository _repository;

  Future<Result<List<ServicePoint>>> call() {
    return _repository.getServicePoints();
  }
}
