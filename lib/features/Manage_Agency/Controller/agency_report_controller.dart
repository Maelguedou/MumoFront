import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/download_service.dart';
import '../data/agency_report_state_model.dart';
import '../di/agency_report_provider.dart';

final agencyReportControllerProvider =
    NotifierProvider<AgencyReportController, AgencyReportStateModel>(() {
      return AgencyReportController();
    });

class AgencyReportController extends Notifier<AgencyReportStateModel> {
  @override
  AgencyReportStateModel build() => const AgencyReportStateModel();

  Future<void> loadPreview({
    required DateTime startDate,
    required DateTime endDate,
    String? status,
    String? type,
    String? servicePointId,
    String? operatorId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      isPdfPreviewLoading: true,
      errorMessage: null,
      downloadMessage: null,
      pdfPreviewBytes: null,
    );

    final reportQuery = _query(
      startDate: startDate,
      endDate: endDate,
      status: status,
      type: type,
      servicePointId: servicePointId,
      operatorId: operatorId,
    );
    final repository = ref.read(agencyReportRepositoryProvider);
    final summaryResult = await repository.getSummary(reportQuery);

    if (summaryResult.isSuccess) {
      state = state.copyWith(isLoading: false, summary: summaryResult.data);
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            summaryResult.error?.message ??
            'Erreur lors du chargement du rapport',
      );
    }

    final pdfResult = await repository.fetchPdfBytes(reportQuery);
    if (pdfResult.isSuccess && pdfResult.data != null) {
      state = state.copyWith(
        isPdfPreviewLoading: false,
        pdfPreviewBytes: pdfResult.data,
      );
    } else {
      state = state.copyWith(
        isPdfPreviewLoading: false,
        errorMessage:
            state.errorMessage ??
            pdfResult.error?.message ??
            'Erreur lors du chargement de l’aperçu PDF',
      );
    }
  }

  Future<void> downloadCsv({
    required DateTime startDate,
    required DateTime endDate,
    String? status,
    String? type,
    String? servicePointId,
    String? operatorId,
  }) {
    return _download(
      isPdf: false,
      startDate: startDate,
      endDate: endDate,
      status: status,
      type: type,
      servicePointId: servicePointId,
      operatorId: operatorId,
    );
  }

  Future<void> downloadPdf({
    required DateTime startDate,
    required DateTime endDate,
    String? status,
    String? type,
    String? servicePointId,
    String? operatorId,
  }) {
    return _download(
      isPdf: true,
      startDate: startDate,
      endDate: endDate,
      status: status,
      type: type,
      servicePointId: servicePointId,
      operatorId: operatorId,
    );
  }

Future<void> _download({
    required bool isPdf,
    required DateTime startDate,
    required DateTime endDate,
    String? status,
    String? type,
    String? servicePointId,
    String? operatorId,
  }) async {
    state = state.copyWith(
      isDownloading: true,
      errorMessage: null,
      downloadMessage: null,
    );
    final query = _query(
      startDate: startDate,
      endDate: endDate,
      status: status,
      type: type,
      servicePointId: servicePointId,
      operatorId: operatorId,
    );
    final repository = ref.read(agencyReportRepositoryProvider);
    final extension = isPdf ? 'pdf' : 'csv';
    final fileName =
        'mumo_rapport_${query['start_date']}_${query['end_date']}.$extension';

    try {
      if (isPdf) {
        final result = await repository.fetchPdfBytes(query);
        if (result.isSuccess && result.data != null) {
          final savedPath = await DownloadService.saveToDownloads(
            bytes: result.data!,
            fileName: fileName,
            mimeType: 'application/pdf',
          );

          if (savedPath != null) {
            state = state.copyWith(
              isDownloading: false,
              downloadMessage: 'PDF enregistré avec succès',
            );
          } else {
            // L'utilisateur a annulé — pas une erreur, juste un non-événement
            state = state.copyWith(isDownloading: false);
          }
        } else {
          state = state.copyWith(
            isDownloading: false,
            errorMessage:
                result.error?.message ?? 'Erreur lors du téléchargement du PDF',
          );
        }
      } else {
        final result = await repository.fetchCsvBytes(query);
        if (result.isSuccess && result.data != null) {
          final savedPath = await DownloadService.saveToDownloads(
            bytes: result.data!,
            fileName: fileName,
            mimeType: 'text/csv',
          );

          if (savedPath != null) {
            state = state.copyWith(
              isDownloading: false,
              downloadMessage: 'CSV enregistré avec succès',
            );
          } else {
            // L'utilisateur a annulé — pas une erreur, juste un non-événement
            state = state.copyWith(isDownloading: false);
          }
        } else {
          state = state.copyWith(
            isDownloading: false,
            errorMessage:
                result.error?.message ??
                'Erreur lors du téléchargement du fichier',
          );
        }
      }
    } catch (_) {
      state = state.copyWith(
        isDownloading: false,
        errorMessage:
            'Impossible d’enregistrer le fichier dans les téléchargements.',
      );
    }
  }

  Map<String, dynamic> _query({
    required DateTime startDate,
    required DateTime endDate,
    String? status,
    String? type,
    String? servicePointId,
    String? operatorId,
    int? perPage,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final query = <String, dynamic>{
      'start_date': dateFormat.format(startDate),
      'end_date': dateFormat.format(endDate),
    };
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (type != null && type.isNotEmpty) query['type'] = type;
    if (servicePointId != null && servicePointId.isNotEmpty) {
      query['service_point_id'] = servicePointId;
    }
    if (operatorId != null && operatorId.isNotEmpty) {
      query['operator_id'] = operatorId;
    }
    if (perPage != null) query['per_page'] = perPage;
    return query;
  }
}
