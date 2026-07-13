import '../../../../core/api/api_client.dart';
import '../models/agent_lookup_result_model.dart';
import '../models/create_service_point_request.dart';
import '../models/create_service_point_response.dart';
import '../models/service_point_operation_stats_model.dart';
import '../models/service_point_daily_recap_model.dart';
import '../models/service_point_model.dart';

class ServicePointRemoteDataSource {
  ServicePointRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<CreateServicePointResponse> createServicePoint(
    CreateServicePointRequest request,
  ) async {
    final response = await _apiClient.post(
      '/create-service-point',
      data: request.toJson(),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      return CreateServicePointResponse.fromJson(payload);
    }
    return CreateServicePointResponse.fromJson(<String, dynamic>{});
  }

  Future<List<ServicePointModel>> getServicePoints() async {
    final response = await _apiClient.get('/index-service-points');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is List ? data['data'] as List : [];
      return payload
          .whereType<Map<String, dynamic>>()
          .map(ServicePointModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<AgentLookupResultModel> findAgent({String? phone, String? npi}) async {
    final requestData = <String, dynamic>{};
    if (phone != null && phone.trim().isNotEmpty) {
      requestData['phone'] = phone.trim();
    }
    if (npi != null && npi.trim().isNotEmpty) {
      requestData['npi'] = npi.trim();
    }

    final response = await _apiClient.post(
      '/agency/agents/find',
      data: requestData,
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      return AgentLookupResultModel.fromJson(payload);
    }
    return const AgentLookupResultModel(
      exists: false,
      canBeAssigned: false,
      reason: 'Reponse invalide',
    );
  }

  Future<ServicePointModel?> getMyServicePoint() async {
    final response = await _apiClient.get('/my-service-point');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      return ServicePointModel.fromJson(payload);
    }
    return null;
  }

  Future<ServicePointOperationStatsModel> getOperationStats(String id) async {
    final response = await _apiClient.get(
      '/service-points/$id/operation-stats',
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      return ServicePointOperationStatsModel.fromJson(payload);
    }
    return const ServicePointOperationStatsModel(
      retraits: 0,
      depots: 0,
      transferts: 0,
      commission: 0,
    );
  }

  Future<List<ServicePointDailyRecapModel>> getDailyRecap() async {
    final response = await _apiClient.get('/agency/service-points/daily-recap');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;
      final items = payload['items'] is List ? payload['items'] as List : [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(ServicePointDailyRecapModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<void> lockServicePoint(String id) async {
    await _apiClient.post('/lock-service-point/$id');
  }

  Future<void> unlockServicePoint(String id) async {
    await _apiClient.post('/unlock-service-point/$id');
  }

  /// Returns a map with keys 'service' (ServicePointModel) and optionally
  /// 'generatedPassword' (String) when a new agent was created.
  Future<Map<String, dynamic>> updateServicePoint(
    String id, {
    String? nameService,
    String? typeAgent,
    String? userId,
    String? name,
    String? lastname,
    String? email,
    String? phone,
    String? npi,
  }) async {
    final data = <String, dynamic>{};
    if (nameService != null) data['name_service'] = nameService;
    if (typeAgent != null) data['type_agent'] = typeAgent;
    if (userId != null) data['user_id'] = userId;
    if (name != null) data['name'] = name;
    if (lastname != null) data['lastname'] = lastname;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (npi != null) data['npi'] = npi;
    final response = await _apiClient.put(
      '/update-service-point/$id',
      data: data,
    );
    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      final payloadData = responseData['data'] is Map<String, dynamic>
          ? responseData['data'] as Map<String, dynamic>
          : responseData;
      final payload = payloadData['service'] is Map<String, dynamic>
          ? payloadData['service'] as Map<String, dynamic>
          : payloadData;
      final generatedPassword = payloadData['generated_password'] as String?;
      return {
        'service': ServicePointModel.fromJson(payload),
        'generatedPassword': generatedPassword,
      };
    }
    throw Exception('Invalid update response');
  }
}
