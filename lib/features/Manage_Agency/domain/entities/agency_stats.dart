class AgencyStatsOverview {
  final int operations;
  final double amount;
  final double commission;
  final double averagePerDay;
  final double successRate;
  final double? operationsChangePercent;
  final double? amountChangePercent;
  final double? commissionChangePercent;

  const AgencyStatsOverview({
    required this.operations,
    required this.amount,
    required this.commission,
    required this.averagePerDay,
    required this.successRate,
    this.operationsChangePercent,
    this.amountChangePercent,
    this.commissionChangePercent,
  });
}

class AgencyStatsEvolutionItem {
  final String date;
  final int operations;
  final double amount;
  final double commission;
  final int depots;
  final int retraits;
  final int transferts;

  const AgencyStatsEvolutionItem({
    required this.date,
    required this.operations,
    required this.amount,
    required this.commission,
    required this.depots,
    required this.retraits,
    required this.transferts,
  });
}

class AgencyStatsBreakdownItem {
  final String label;
  final int operations;
  final double amount;
  final double commission;
  final double percent;
  final String? type;
  final String? operatorName;

  const AgencyStatsBreakdownItem({
    required this.label,
    required this.operations,
    required this.amount,
    required this.commission,
    required this.percent,
    this.type,
    this.operatorName,
  });
}

class AgencyStatsServicePointItem {
  final int rank;
  final String name;
  final String? agent;
  final bool isActive;
  final int operations;
  final double amount;
  final double commission;
  final double successRate;

  const AgencyStatsServicePointItem({
    required this.rank,
    required this.name,
    this.agent,
    required this.isActive,
    required this.operations,
    required this.amount,
    required this.commission,
    required this.successRate,
  });
}

class AgencyStatsActivityHourItem {
  final String slot;
  final int slotStart;
  final int operations;
  final double amount;
  final double commission;

  const AgencyStatsActivityHourItem({
    required this.slot,
    required this.slotStart,
    required this.operations,
    required this.amount,
    required this.commission,
  });
}

class AgencyStatsInsightItem {
  final String level;
  final String title;
  final String message;

  const AgencyStatsInsightItem({
    required this.level,
    required this.title,
    required this.message,
  });
}

class AgencyStatsDashboard {
  final AgencyStatsOverview? overview;
  final List<AgencyStatsEvolutionItem> evolution;
  final List<AgencyStatsBreakdownItem> byType;
  final List<AgencyStatsBreakdownItem> byOperator;
  final List<AgencyStatsServicePointItem> servicePoints;
  final List<AgencyStatsActivityHourItem> activityHours;
  final List<AgencyStatsInsightItem> insights;

  const AgencyStatsDashboard({
    this.overview,
    this.evolution = const [],
    this.byType = const [],
    this.byOperator = const [],
    this.servicePoints = const [],
    this.activityHours = const [],
    this.insights = const [],
  });
}
