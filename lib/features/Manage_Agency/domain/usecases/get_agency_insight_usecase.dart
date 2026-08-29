import '../../../../core/utils/result.dart';
import '../entities/agency_insight.dart';
import '../repositories/agency_insight_repository.dart';

class GetAgencyInsightUseCase {
  const GetAgencyInsightUseCase(this._repository);
  final AgencyInsightRepository _repository;

  Future<Result<AgencyInsight>> call(int id) {
    return _repository.getInsightById(id);
  }
}