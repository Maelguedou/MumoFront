import '../../domain/entities/agency_report_operation.dart';

class AgencyReportOperationsPageModel {
  const AgencyReportOperationsPageModel({
    required this.items,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  final List<AgencyReportOperation> items;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  factory AgencyReportOperationsPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final pagination = data['pagination'] is Map<String, dynamic>
        ? data['pagination'] as Map<String, dynamic>
        : <String, dynamic>{};

    return AgencyReportOperationsPageModel(
      items: (data['items'] is List ? data['items'] as List : const [])
          .whereType<Map<String, dynamic>>()
          .map(_operationFromJson)
          .toList(),
      currentPage: _int(pagination['current_page']),
      perPage: _int(pagination['per_page']),
      total: _int(pagination['total']),
      lastPage: _int(pagination['last_page']),
    );
  }

  AgencyReportOperationsPage toEntity() {
    return AgencyReportOperationsPage(
      items: items,
      currentPage: currentPage,
      perPage: perPage,
      total: total,
      lastPage: lastPage,
    );
  }

  static AgencyReportOperation _operationFromJson(Map<String, dynamic> json) {
    final servicePoint = json['service_point'] is Map<String, dynamic>
        ? json['service_point'] as Map<String, dynamic>
        : <String, dynamic>{};
    final agent = json['agent'] is Map<String, dynamic>
        ? json['agent'] as Map<String, dynamic>
        : <String, dynamic>{};
    final operator = json['operator'] is Map<String, dynamic>
        ? json['operator'] as Map<String, dynamic>
        : <String, dynamic>{};

    return AgencyReportOperation(
      id: json['id']?.toString() ?? '',
      datetime: json['datetime']?.toString() ?? '',
      servicePointId: servicePoint['id']?.toString(),
      servicePointName: servicePoint['name']?.toString(),
      agentId: agent['id']?.toString(),
      agentName: agent['name']?.toString(),
      type: json['type']?.toString() ?? '',
      ussdLabel: json['ussd_label']?.toString(),
      operatorId: operator['id']?.toString(),
      operatorName: operator['name']?.toString(),
      number: json['number']?.toString(),
      amount: _double(json['amount']),
      status: json['status']?.toString() ?? '',
      reference: json['reference']?.toString(),
      message: json['message']?.toString(),
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
}
