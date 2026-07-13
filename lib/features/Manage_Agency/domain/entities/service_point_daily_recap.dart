class ServicePointDailyRecap {
  final String servicePointId;
  final String servicePointName;
  final String? agentName;
  final bool isActive;
  final int depots;
  final int retraits;
  final int transferts;
  final int totalOperations;
  final double totalAmount;
  final double totalCommission;

  const ServicePointDailyRecap({
    required this.servicePointId,
    required this.servicePointName,
    this.agentName,
    required this.isActive,
    required this.depots,
    required this.retraits,
    required this.transferts,
    required this.totalOperations,
    required this.totalAmount,
    required this.totalCommission,
  });
}
