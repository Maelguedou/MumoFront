import '../../../../core/api/api_client.dart';
import '../models/agency_stats_model.dart';

class AgencyStatsRemoteDataSource {
  AgencyStatsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<AgencyStatsOverviewModel> getOverview(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.post(
      '/agency/stats/overview',
      data: data,
    );
    return AgencyStatsOverviewModel.fromJson(_json(response.data));
  }

  Future<AgencyStatsEvolutionModel> getEvolution(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.post(
      '/agency/stats/evolution',
      data: data,
    );
    return AgencyStatsEvolutionModel.fromJson(_json(response.data));
  }

  Future<AgencyStatsBreakdownModel> getBreakdown(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.post(
      '/agency/stats/breakdown',
      data: data,
    );
    return AgencyStatsBreakdownModel.fromJson(_json(response.data));
  }

  Future<AgencyStatsServicePointsModel> getServicePoints(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.post(
      '/agency/stats/service-points',
      data: data,
    );
    return AgencyStatsServicePointsModel.fromJson(_json(response.data));
  }

  Future<AgencyStatsActivityHoursModel> getActivityHours(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.post(
      '/agency/stats/activity-hours',
      data: data,
    );
    return AgencyStatsActivityHoursModel.fromJson(_json(response.data));
  }

  Future<AgencyStatsInsightsModel> getInsights(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.post(
      '/agency/stats/insights',
      data: data,
    );
    return AgencyStatsInsightsModel.fromJson(_json(response.data));
  }

  Map<String, dynamic> _json(dynamic data) {
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}
