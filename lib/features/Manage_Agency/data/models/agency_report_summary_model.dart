import '../../domain/entities/agency_report_summary.dart';

class AgencyReportSummaryModel {
  const AgencyReportSummaryModel({
    required this.period,
    required this.totals,
    required this.byServicePoint,
    required this.byOperator,
    required this.byStatus,
  });

  final ReportPeriod period;
  final ReportTotals totals;
  final List<ServicePointReportSummary> byServicePoint;
  final List<OperatorReportSummary> byOperator;
  final ReportStatusSummary byStatus;

  factory AgencyReportSummaryModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final period = data['period'] is Map<String, dynamic>
        ? data['period'] as Map<String, dynamic>
        : <String, dynamic>{};
    final totals = data['totals'] is Map<String, dynamic>
        ? data['totals'] as Map<String, dynamic>
        : <String, dynamic>{};
    final status = data['by_status'] is Map<String, dynamic>
        ? data['by_status'] as Map<String, dynamic>
        : <String, dynamic>{};

    return AgencyReportSummaryModel(
      period: ReportPeriod(
        startDate: period['start_date']?.toString() ?? '',
        endDate: period['end_date']?.toString() ?? '',
        timezone: period['timezone']?.toString() ?? '',
      ),
      totals: ReportTotals(
        operations: _int(totals['operations']),
        depots: _int(totals['depots']),
        retraits: _int(totals['retraits']),
        transferts: _int(totals['transferts']),
        amount: _double(totals['amount']),
      ),
      byServicePoint:
          (data['by_service_point'] is List
                  ? data['by_service_point'] as List
                  : const [])
              .whereType<Map<String, dynamic>>()
              .map(
                (item) => ServicePointReportSummary(
                  servicePointId: item['service_point_id']?.toString() ?? '',
                  servicePointName:
                      item['service_point_name']?.toString() ?? 'Cabine',
                  agentName: item['agent_name']?.toString(),
                  isActive: _bool(item['is_active']),
                  operations: _int(item['operations']),
                  depots: _int(item['depots']),
                  retraits: _int(item['retraits']),
                  transferts: _int(item['transferts']),
                  amount: _double(item['amount']),
                ),
              )
              .toList(),
      byOperator:
          (data['by_operator'] is List ? data['by_operator'] as List : const [])
              .whereType<Map<String, dynamic>>()
              .map(
                (item) => OperatorReportSummary(
                  operatorId: item['operator_id']?.toString() ?? '',
                  operatorName:
                      item['operator_name']?.toString() ?? 'Operateur',
                  operations: _int(item['operations']),
                  amount: _double(item['amount']),
                ),
              )
              .toList(),
      byStatus: ReportStatusSummary(
        paid: _int(status['paid']),
        pending: _int(status['pending']),
        failed: _int(status['failed']),
      ),
    );
  }

  AgencyReportSummary toEntity() {
    return AgencyReportSummary(
      period: period,
      totals: totals,
      byServicePoint: byServicePoint,
      byOperator: byOperator,
      byStatus: byStatus,
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _double(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    return value?.toString().toLowerCase() == 'true';
  }
}
