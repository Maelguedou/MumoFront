import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/datasources/agency_remote_datasource.dart';
import '../data/repositories/agency_repository_impl.dart';
import '../domain/repositories/agency_repository.dart';
import '../domain/usecases/create_agency_usecase.dart';
import '../domain/usecases/has_agency_usecase.dart';
import '../domain/usecases/update_agency_usecase.dart';

final agencyRemoteDataSourceProvider = Provider<AgencyRemoteDataSource>((ref) {
	return AgencyRemoteDataSource(ref.read(apiClientProvider));
});

final agencyRepositoryProvider = Provider<AgencyRepository>((ref) {
	return AgencyRepositoryImpl(ref.read(agencyRemoteDataSourceProvider));
});

final createAgencyUseCaseProvider = Provider<CreateAgencyUseCase>((ref) {
	return CreateAgencyUseCase(ref.read(agencyRepositoryProvider));
});

final updateAgencyUseCaseProvider = Provider<UpdateAgencyUseCase>((ref) {
	return UpdateAgencyUseCase(ref.read(agencyRepositoryProvider));
});

final hasAgencyUseCaseProvider = Provider<HasAgencyUseCase>((ref) {
  return HasAgencyUseCase(ref.read(agencyRepositoryProvider));
});
