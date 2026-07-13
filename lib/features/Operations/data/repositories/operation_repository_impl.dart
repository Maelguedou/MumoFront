import '../../domain/repositories/operation_repository.dart';
import '../datasources/operation_remote_datasource.dart';
import '../models/operator_model.dart';
import '../models/execute_operation_model.dart';
import '../models/operation_history_model.dart';

class OperationRepositoryImpl implements OperationRepository {
  final OperationRemoteDataSource _remoteDataSource;

  OperationRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<OperatorModel>> getOperators() {
    return _remoteDataSource.getOperators();
  }

  @override
  Future<List<OperationHistoryItem>> getHistory() {
    return _remoteDataSource.getHistory();
  }

  @override
  Future<ExecuteOperationResponse> executeOperation(
    ExecuteOperationRequest request,
  ) {
    return _remoteDataSource.executeOperation(request);
  }

  @override
  Future<void> confirmOperationDirect({
    required int operationId,
    required String message,
    String? transactionId,
  }) {
    return _remoteDataSource.confirmOperationDirect(
      operationId: operationId,
      message: message,
      transactionId: transactionId,
    );
  }
}
