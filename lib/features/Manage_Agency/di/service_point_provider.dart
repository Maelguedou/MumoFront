import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/datasources/service_point_remote_datasource.dart';
import '../data/repositories/service_point_repository_impl.dart';
import '../domain/repositories/service_point_repository.dart';
import '../domain/usecases/create_service_point_usecase.dart';
import '../domain/usecases/get_service_points_usecase.dart';

final servicePointRemoteDataSourceProvider =
    Provider<ServicePointRemoteDataSource>((ref) {
  return ServicePointRemoteDataSource(ref.read(apiClientProvider));
});

final servicePointRepositoryProvider = Provider<ServicePointRepository>((ref) {
  return ServicePointRepositoryImpl(ref.read(servicePointRemoteDataSourceProvider));
});

final createServicePointUseCaseProvider = Provider<CreateServicePointUseCase>((ref) {
  return CreateServicePointUseCase(ref.read(servicePointRepositoryProvider));
});

final getServicePointsUseCaseProvider = Provider<GetServicePointsUseCase>((ref) {
  return GetServicePointsUseCase(ref.read(servicePointRepositoryProvider));
});
