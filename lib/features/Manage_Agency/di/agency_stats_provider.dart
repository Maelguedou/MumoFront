import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/datasources/agency_stats_remote_datasource.dart';
import '../data/repositories/agency_stats_repository_impl.dart';
import '../domain/repositories/agency_stats_repository.dart';

final agencyStatsRemoteDataSourceProvider =
    Provider<AgencyStatsRemoteDataSource>((ref) {
      return AgencyStatsRemoteDataSource(ref.read(apiClientProvider));
    });

final agencyStatsRepositoryProvider = Provider<AgencyStatsRepository>((ref) {
  return AgencyStatsRepositoryImpl(
    ref.read(agencyStatsRemoteDataSourceProvider),
  );
});
