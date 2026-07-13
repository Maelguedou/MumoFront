import '../../domain/entities/service_point_daily_recap.dart';

class ServicePointDailyRecapModel {
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

  const ServicePointDailyRecapModel({
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

  factory ServicePointDailyRecapModel.fromJson(Map<String, dynamic> json) {
    return ServicePointDailyRecapModel(
      servicePointId: json['service_point_id']?.toString() ?? '',
      servicePointName:
          json['service_point_name']?.toString() ?? 'Cabine inconnue',
      agentName: json['agent_name']?.toString(),
      isActive: _readBool(json['is_active']),
      depots: _readInt(json['depots']),
      retraits: _readInt(json['retraits']),
      transferts: _readInt(json['transferts']),
      totalOperations: _readInt(json['total_operations']),
      totalAmount: _readDouble(json['total_amount']),
      totalCommission: _readDouble(json['total_commission']),
    );
  }

  ServicePointDailyRecap toEntity() {
    return ServicePointDailyRecap(
      servicePointId: servicePointId,
      servicePointName: servicePointName,
      agentName: agentName,
      isActive: isActive,
      depots: depots,
      retraits: retraits,
      transferts: transferts,
      totalOperations: totalOperations,
      totalAmount: totalAmount,
      totalCommission: totalCommission,
    );
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
