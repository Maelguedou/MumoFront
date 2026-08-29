import '../repositories/agency_insight_repository.dart';
import '../../../../core/utils/result.dart';
import '../entities/agency_insight.dart';


class GenerateAgencyInsightUseCase{
  const GenerateAgencyInsightUseCase(this._repository);
  final AgencyInsightRepository _repository;

  Future<Result<AgencyInsight>> call({
    required String startDate,
    required String endDate,
    required String granularity,
  }) {
    return _repository.generateInsight(
      startDate: startDate,
      endDate: endDate,
      granularity: granularity,
    );
  }
}