import 'dart:typed_data';

import '../../../../core/utils/result.dart';
import '../entities/agency_report_operation.dart';
import '../entities/agency_report_summary.dart';

abstract class AgencyReportRepository {
  Future<Result<AgencyReportSummary>> getSummary(Map<String, dynamic> query);

  Future<Result<AgencyReportOperationsPage>> getOperations(
    Map<String, dynamic> query,
  );

  Future<Result<Uint8List>> fetchCsvBytes(Map<String, dynamic> query);

  Future<Result<Uint8List>> fetchPdfBytes(Map<String, dynamic> query);
}
