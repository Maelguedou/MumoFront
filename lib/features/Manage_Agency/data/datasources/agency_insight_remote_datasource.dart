import '../../../../core/api/api_client.dart';
import '../models/agency_insight_model.dart';

class AgencyInsightRemoteDataSource {
  AgencyInsightRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  ///Appelle l'endpoint de génération d'insight
  Future<AgencyInsightModel> generateInsight({
    required String startDate,
    required String endDate,
    required String granularity,
  }) async {
    final response = await _apiClient.post(
      '/agency/insights/generate',
      data: {
        'start_date': startDate,
        'end_date': endDate,
        'granularity': granularity,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return AgencyInsightModel.fromJson(data);
  }

  /// Appelle l'endpoint de récupération par ID
  Future<AgencyInsightModel> getInsightById(int id) async {
    final response = await _apiClient.get('/agency/insights/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return AgencyInsightModel.fromJson(data);
  }

  /// Appelle l'endpoint de l'historique
  Future<List<AgencyInsightModel>> getInsightHistory({
    String? granularity,
    int limit = 30,
  }) async {
    final payload = <String, dynamic>{'limit': limit};
    if (granularity != null) {
      payload['granularity'] = granularity;
    }
    final response = await _apiClient.post(
      '/agency/insights/history',
      data: payload,
    );

    final responseData = response.data['data'] as Map<String, dynamic>;
    final items = responseData['items'] as List<dynamic>;
    return items
        .map(
          (item) => AgencyInsightModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
