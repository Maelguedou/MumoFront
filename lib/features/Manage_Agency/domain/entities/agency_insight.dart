import 'agency_insight_item.dart';

class AgencyInsight {
  final int id;
  final int agencyId;
  final String granularity;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> digest;
  final List<AgencyInsightItem> insights;
  final String? model;
  final String? digestHash;
  final DateTime generatedAt;

  const AgencyInsight({
    required this.id,
    required this.agencyId,
    required this.granularity,
    required this.startDate,
    required this.endDate,
    required this.digest,
    required this.insights,
    this.model,
    this.digestHash,
    required this.generatedAt,
  });
}
