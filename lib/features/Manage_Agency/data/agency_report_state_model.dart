import 'dart:typed_data';

import '../domain/entities/agency_report_operation.dart';
import '../domain/entities/agency_report_summary.dart';

class AgencyReportStateModel {
  final bool isLoading;
  final bool isPdfPreviewLoading;
  final bool isDownloading;
  final String? errorMessage;
  final String? downloadMessage;
  final Uint8List? pdfPreviewBytes;
  final AgencyReportSummary? summary;
  final AgencyReportOperationsPage? operationsPage;

  const AgencyReportStateModel({
    this.isLoading = false,
    this.isPdfPreviewLoading = false,
    this.isDownloading = false,
    this.errorMessage,
    this.downloadMessage,
    this.pdfPreviewBytes,
    this.summary,
    this.operationsPage,
  });

  AgencyReportStateModel copyWith({
    bool? isLoading,
    bool? isPdfPreviewLoading,
    bool? isDownloading,
    Object? errorMessage = _unset,
    Object? downloadMessage = _unset,
    Object? pdfPreviewBytes = _unset,
    AgencyReportSummary? summary,
    AgencyReportOperationsPage? operationsPage,
  }) {
    return AgencyReportStateModel(
      isLoading: isLoading ?? this.isLoading,
      isPdfPreviewLoading: isPdfPreviewLoading ?? this.isPdfPreviewLoading,
      isDownloading: isDownloading ?? this.isDownloading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      downloadMessage: identical(downloadMessage, _unset)
          ? this.downloadMessage
          : downloadMessage as String?,
      pdfPreviewBytes: identical(pdfPreviewBytes, _unset)
          ? this.pdfPreviewBytes
          : pdfPreviewBytes as Uint8List?,
      summary: summary ?? this.summary,
      operationsPage: operationsPage ?? this.operationsPage,
    );
  }

  static const Object _unset = Object();
}
