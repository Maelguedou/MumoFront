import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/datasources/agency_report_remote_datasource.dart';
import '../data/repositories/agency_report_repository_impl.dart';
import '../domain/repositories/agency_report_repository.dart';

final agencyReportRemoteDataSourceProvider =
    Provider<AgencyReportRemoteDataSource>((ref) {
      return AgencyReportRemoteDataSource(ref.read(apiClientProvider));
    });

final agencyReportRepositoryProvider = Provider<AgencyReportRepository>((ref) {
  return AgencyReportRepositoryImpl(
    ref.read(agencyReportRemoteDataSourceProvider),
  );
});
