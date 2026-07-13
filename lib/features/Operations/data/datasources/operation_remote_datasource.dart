import '../../../../core/api/api_client.dart';
import '../models/operator_model.dart';
import '../models/execute_operation_model.dart';
import '../models/operation_history_model.dart';

class OperationRemoteDataSource {
  final ApiClient _apiClient;

  OperationRemoteDataSource(this._apiClient);

  Future<List<OperatorModel>> getOperators() async {
    final response = await _apiClient.get('/operators');
    dynamic data = response.data;

    // Gérer le cas où Laravel enveloppe la réponse dans une clé 'data'
    if (data is Map && data.containsKey('data')) {
      data = data['data'];
    }

    if (data is List) {
      return data.map((json) => OperatorModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<ExecuteOperationResponse> executeOperation(
    ExecuteOperationRequest request,
  ) async {
    final response = await _apiClient.post(
      '/execute-operation',
      data: request.toJson(),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ExecuteOperationResponse.fromJson(data);
    }
    throw Exception('Erreur lors de l\'exécution de l\'opération USSD');
  }

  Future<List<OperationHistoryItem>> getHistory() async {
    final response = await _apiClient.get('/operations');
    final data = response.data;
    final payload = data is Map<String, dynamic> ? data['data'] : data;

    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map(OperationHistoryItem.fromJson)
          .toList();
    }

    return [];
  }

  Future<void> confirmOperationFromSms({
    String? amount,
    String? number,
    required int operatorId,
    String? transactionId,
    required String smsDate,
    String? message,
    String? operationType,
  }) async {
    await _apiClient.post(
      '/operations/confirm-from-sms',
      data: {
        if (amount != null) 'amount': amount,
        if (number != null) 'number': number,
        'operator_id': operatorId,
        'transaction_id': transactionId,
        if (operationType != null) 'operation_type': operationType,
        'sms_date': smsDate,
        'message': message,
      },
    );
  }

  Future<void> confirmOperationDirect({
    required int operationId,
    required String message,
    String? transactionId,
  }) async {
    await _apiClient.post(
      '/operations/$operationId/confirm-direct',
      data: {'message': message, 'transaction_id': transactionId},
    );
  }
}
