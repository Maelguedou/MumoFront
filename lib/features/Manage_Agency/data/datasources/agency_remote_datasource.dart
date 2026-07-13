import '../../../../core/api/api_client.dart';
import '../models/agency_request.dart';
import '../models/agency_response.dart';

class AgencyRemoteDataSource {
  AgencyRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<AgencyResponse> createAgency(AgencyRequest request) async {
    final response = await _apiClient.post('/create-agency', data: request.toJson());
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      return AgencyResponse.fromJson(payload);
    }
    return AgencyResponse.fromJson(<String, dynamic>{});
  }

  Future<AgencyResponse> updateAgency(String id, AgencyRequest request) async {
    final response = await _apiClient.put('/update-agency/$id', data: request.toJson());
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      return AgencyResponse.fromJson(payload);
    }
    return AgencyResponse.fromJson(<String, dynamic>{});
  }

  Future<AgencyResponse> hasAgency() async {
    final response = await _apiClient.get('/has-agency');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      return AgencyResponse.fromJson(payload);
    }
    return AgencyResponse.fromJson(<String, dynamic>{});
  }
}
