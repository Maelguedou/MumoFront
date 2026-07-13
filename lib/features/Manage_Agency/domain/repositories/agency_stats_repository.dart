import '../../../../core/utils/result.dart';
import '../entities/agency_stats.dart';

abstract class AgencyStatsRepository {
  Future<Result<AgencyStatsDashboard>> getDashboard(Map<String, dynamic> data);
}
