import '../../../../core/utils/result.dart';
import '../entities/agency_insight.dart';
import '../repositories/agency_insight_repository.dart';

class GetAgencyInsightHistoryUseCase {
  const GetAgencyInsightHistoryUseCase(this._repository);
  final AgencyInsightRepository _repository;

  Future<Result<List<AgencyInsight>>> call({
    String? granularity,
    int limit = 30,
  }) {
    return _repository.getInsightHistory(
      granularity: granularity,
      limit: limit,
    );
  }
}