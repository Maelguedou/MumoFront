import '../../../../core/utils/result.dart';
import '../entities/agency_insight.dart';

abstract class AgencyInsightRepository {
  Future<Result<AgencyInsight>> generateInsight({
    required String startDate,
    required String endDate,
    required String granularity,
  });

  /// Récupère un insight spécifique par son identifiant
  Future<Result<AgencyInsight>> getInsightById(int id);

  /// Récupère l'historique des insights de l'agence
  Future<Result<List<AgencyInsight>>> getInsightHistory({
    String? granularity,
    int limit = 30,
  });
}