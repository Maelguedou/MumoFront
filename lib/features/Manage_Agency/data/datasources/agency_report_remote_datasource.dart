import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/agency_report_operation_model.dart';
import '../models/agency_report_summary_model.dart';

class AgencyReportRemoteDataSource {
  AgencyReportRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<AgencyReportSummaryModel> getSummary(
    Map<String, dynamic> query,
  ) async {
    final response = await _apiClient.post(
      '/agency/reports/summary',
      data: query,
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return AgencyReportSummaryModel.fromJson(data);
    }
    return AgencyReportSummaryModel.fromJson(<String, dynamic>{});
  }

  Future<AgencyReportOperationsPageModel> getOperations(
    Map<String, dynamic> query,
  ) async {
    final response = await _apiClient.post(
      '/agency/reports/operations',
      data: query,
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return AgencyReportOperationsPageModel.fromJson(data);
    }
    return AgencyReportOperationsPageModel.fromJson(<String, dynamic>{});
  }

  Future<Uint8List> fetchCsvBytes(Map<String, dynamic> query) async {
    return _fetchReportBytes('/agency/reports/operations/export.csv', query);
  }

  Future<Uint8List> fetchPdfBytes(Map<String, dynamic> query) {
    return _fetchReportBytes('/agency/reports/operations/export.pdf', query);
  }

  Future<Uint8List> _fetchReportBytes(
    String path,
    Map<String, dynamic> query,
  ) async {
    final response = await _apiClient.post<List<int>>(
      path,
      data: query,
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(response.data ?? <int>[]);
  }
}
