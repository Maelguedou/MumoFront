import '../../domain/entities/agency_stats.dart';

class AgencyStatsOverviewModel extends AgencyStatsOverview {
  const AgencyStatsOverviewModel({
    required super.operations,
    required super.amount,
    required super.commission,
    required super.averagePerDay,
    required super.successRate,
    super.operationsChangePercent,
    super.amountChangePercent,
    super.commissionChangePercent,
  });

  factory AgencyStatsOverviewModel.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final totals = data['totals'] is Map<String, dynamic>
        ? data['totals'] as Map<String, dynamic>
        : <String, dynamic>{};
    final comparison = data['comparison'] is Map<String, dynamic>
        ? data['comparison'] as Map<String, dynamic>
        : <String, dynamic>{};

    return AgencyStatsOverviewModel(
      operations: _int(totals['operations']),
      amount: _double(totals['amount']),
      commission: _double(totals['commission']),
      averagePerDay: _double(totals['average_per_day']),
      successRate: _double(totals['success_rate']),
      operationsChangePercent: _nullableDouble(
        comparison['operations_change_percent'],
      ),
      amountChangePercent: _nullableDouble(comparison['amount_change_percent']),
      commissionChangePercent: _nullableDouble(
        comparison['commission_change_percent'],
      ),
    );
  }
}

class AgencyStatsEvolutionModel {
  const AgencyStatsEvolutionModel(this.items);

  final List<AgencyStatsEvolutionItem> items;

  factory AgencyStatsEvolutionModel.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return AgencyStatsEvolutionModel(
      _list(data['items'])
          .map(
            (item) => AgencyStatsEvolutionItem(
              date: item['date']?.toString() ?? '',
              operations: _int(item['operations']),
              amount: _double(item['amount']),
              commission: _double(item['commission']),
              depots: _int(item['depots']),
              retraits: _int(item['retraits']),
              transferts: _int(item['transferts']),
            ),
          )
          .toList(),
    );
  }
}

class AgencyStatsBreakdownModel {
  const AgencyStatsBreakdownModel({
    required this.byType,
    required this.byOperator,
  });

  final List<AgencyStatsBreakdownItem> byType;
  final List<AgencyStatsBreakdownItem> byOperator;

  factory AgencyStatsBreakdownModel.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return AgencyStatsBreakdownModel(
      byType: _list(data['by_type'])
          .map(
            (item) => AgencyStatsBreakdownItem(
              label:
                  item['label']?.toString() ?? item['type']?.toString() ?? '',
              type: item['type']?.toString(),
              operations: _int(item['operations']),
              amount: _double(item['amount']),
              commission: _double(item['commission']),
              percent: _double(item['percent']),
            ),
          )
          .toList(),
      byOperator: _list(data['by_operator'])
          .map(
            (item) => AgencyStatsBreakdownItem(
              label: item['operator_name']?.toString() ?? 'Opérateur',
              operatorName: item['operator_name']?.toString(),
              operations: _int(item['operations']),
              amount: _double(item['amount']),
              commission: _double(item['commission']),
              percent: _double(item['percent']),
            ),
          )
          .toList(),
    );
  }
}

class AgencyStatsServicePointsModel {
  const AgencyStatsServicePointsModel(this.items);

  final List<AgencyStatsServicePointItem> items;

  factory AgencyStatsServicePointsModel.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return AgencyStatsServicePointsModel(
      _list(data['items'])
          .map(
            (item) => AgencyStatsServicePointItem(
              rank: _int(item['rank']),
              name: item['name']?.toString() ?? 'Cabine',
              agent: item['agent']?.toString(),
              isActive: _bool(item['is_active']),
              operations: _int(item['operations']),
              amount: _double(item['amount']),
              commission: _double(item['commission']),
              successRate: _double(item['success_rate']),
            ),
          )
          .toList(),
    );
  }
}

class AgencyStatsActivityHoursModel {
  const AgencyStatsActivityHoursModel(this.items);

  final List<AgencyStatsActivityHourItem> items;

  factory AgencyStatsActivityHoursModel.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return AgencyStatsActivityHoursModel(
      _list(data['items'])
          .map(
            (item) => AgencyStatsActivityHourItem(
              slot: item['slot']?.toString() ?? '',
              slotStart: _int(item['slot_start']),
              operations: _int(item['operations']),
              amount: _double(item['amount']),
              commission: _double(item['commission']),
            ),
          )
          .toList(),
    );
  }
}

class AgencyStatsInsightsModel {
  const AgencyStatsInsightsModel(this.items);

  final List<AgencyStatsInsightItem> items;

  factory AgencyStatsInsightsModel.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return AgencyStatsInsightsModel(
      _list(data['items'])
          .map(
            (item) => AgencyStatsInsightItem(
              level: item['level']?.toString() ?? 'info',
              title: item['title']?.toString() ?? '',
              message: item['message']?.toString() ?? '',
            ),
          )
          .toList(),
    );
  }
}

Map<String, dynamic> _data(Map<String, dynamic> json) {
  return json['data'] is Map<String, dynamic>
      ? json['data'] as Map<String, dynamic>
      : json;
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList();
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  return _double(value);
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value == 1;
  return value?.toString().toLowerCase() == 'true';
}
