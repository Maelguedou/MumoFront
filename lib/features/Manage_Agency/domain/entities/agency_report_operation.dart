class AgencyReportOperation {
  final String id;
  final String datetime;
  final String? servicePointId;
  final String? servicePointName;
  final String? agentId;
  final String? agentName;
  final String type;
  final String? ussdLabel;
  final String? operatorId;
  final String? operatorName;
  final String? number;
  final double amount;
  final String status;
  final String? reference;
  final String? message;

  const AgencyReportOperation({
    required this.id,
    required this.datetime,
    this.servicePointId,
    this.servicePointName,
    this.agentId,
    this.agentName,
    required this.type,
    this.ussdLabel,
    this.operatorId,
    this.operatorName,
    this.number,
    required this.amount,
    required this.status,
    this.reference,
    this.message,
  });
}

class AgencyReportOperationsPage {
  final List<AgencyReportOperation> items;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const AgencyReportOperationsPage({
    required this.items,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });
}
