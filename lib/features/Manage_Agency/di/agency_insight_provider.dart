import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../Controller/agency_insight_controller.dart';
import '../data/agency_insight_state_model.dart';
import '../data/datasources/agency_insight_remote_datasource.dart';
import '../data/repositories/agency_insight_repository_impl.dart';
import '../domain/repositories/agency_insight_repository.dart';
import '../domain/usecases/generate_agency_insight_usecase.dart';
import '../domain/usecases/get_agency_insight_history_usecase.dart';
import '../domain/usecases/get_agency_insight_usecase.dart';

// 1. Remote Data Source
final agencyInsightRemoteDataSourceProvider =
    Provider<AgencyInsightRemoteDataSource>((ref) {
  return AgencyInsightRemoteDataSource(ref.read(apiClientProvider));
});

// 2. Repository
final agencyInsightRepositoryProvider =
    Provider<AgencyInsightRepository>((ref) {
  return AgencyInsightRepositoryImpl(
    ref.read(agencyInsightRemoteDataSourceProvider),
  );
});

// 3. Use Cases
final generateAgencyInsightUseCaseProvider =
    Provider<GenerateAgencyInsightUseCase>((ref) {
  return GenerateAgencyInsightUseCase(
    ref.read(agencyInsightRepositoryProvider),
  );
});

final getAgencyInsightHistoryUseCaseProvider =
    Provider<GetAgencyInsightHistoryUseCase>((ref) {
  return GetAgencyInsightHistoryUseCase(
    ref.read(agencyInsightRepositoryProvider),
  );
});

final getAgencyInsightUseCaseProvider =
    Provider<GetAgencyInsightUseCase>((ref) {
  return GetAgencyInsightUseCase(
    ref.read(agencyInsightRepositoryProvider),
  );
});

// 4. Controller
final agencyInsightControllerProvider =
    NotifierProvider<AgencyInsightController, AgencyInsightState>(() {
  return AgencyInsightController();
});