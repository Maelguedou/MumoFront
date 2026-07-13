class AgencyReportSummary {
  final ReportPeriod period;
  final ReportTotals totals;
  final List<ServicePointReportSummary> byServicePoint;
  final List<OperatorReportSummary> byOperator;
  final ReportStatusSummary byStatus;

  const AgencyReportSummary({
    required this.period,
    required this.totals,
    required this.byServicePoint,
    required this.byOperator,
    required this.byStatus,
  });
}

class ReportPeriod {
  final String startDate;
  final String endDate;
  final String timezone;

  const ReportPeriod({
    required this.startDate,
    required this.endDate,
    required this.timezone,
  });
}

class ReportTotals {
  final int operations;
  final int depots;
  final int retraits;
  final int transferts;
  final double amount;

  const ReportTotals({
    required this.operations,
    required this.depots,
    required this.retraits,
    required this.transferts,
    required this.amount,
  });
}

class ServicePointReportSummary {
  final String servicePointId;
  final String servicePointName;
  final String? agentName;
  final bool isActive;
  final int operations;
  final int depots;
  final int retraits;
  final int transferts;
  final double amount;

  const ServicePointReportSummary({
    required this.servicePointId,
    required this.servicePointName,
    this.agentName,
    required this.isActive,
    required this.operations,
    required this.depots,
    required this.retraits,
    required this.transferts,
    required this.amount,
  });
}

class OperatorReportSummary {
  final String operatorId;
  final String operatorName;
  final int operations;
  final double amount;

  const OperatorReportSummary({
    required this.operatorId,
    required this.operatorName,
    required this.operations,
    required this.amount,
  });
}

class ReportStatusSummary {
  final int paid;
  final int pending;
  final int failed;

  const ReportStatusSummary({
    required this.paid,
    required this.pending,
    required this.failed,
  });
}
