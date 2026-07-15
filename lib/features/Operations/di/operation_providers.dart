import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../data/datasources/operation_remote_datasource.dart';
import '../data/repositories/operation_repository_impl.dart';
import '../data/services/ussd/ussd_executor.dart';
import '../data/services/ussd/ussd_launcher_executor.dart';
import '../domain/repositories/operation_repository.dart';

final operationRemoteDataSourceProvider = Provider<OperationRemoteDataSource>((
  ref,
) {
  return OperationRemoteDataSource(ref.read(apiClientProvider));
});

final operationRepositoryProvider = Provider<OperationRepository>((ref) {
  return OperationRepositoryImpl(ref.read(operationRemoteDataSourceProvider));
});

final ussdExecutorProvider = Provider<UssdExecutor>((ref) {
  return const UssdLauncherExecutor();
});
