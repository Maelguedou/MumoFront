import '../../data/models/operator_model.dart';
import '../../data/models/execute_operation_model.dart';
import '../../data/models/operation_history_model.dart';

abstract class OperationRepository {
  Future<List<OperatorModel>> getOperators();
  Future<List<OperationHistoryItem>> getHistory();
  Future<ExecuteOperationResponse> executeOperation(
    ExecuteOperationRequest request,
  );
  Future<void> confirmOperationDirect({
    required int operationId,
    required String message,
    String? transactionId,
  });
}
