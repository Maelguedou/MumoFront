import '../../domain/entities/service_point_operation_stats.dart';

class ServicePointOperationStatsModel {
  final int retraits;
  final int depots;
  final int transferts;
  final double commission;
  final String? date;
  final String? timezone;

  const ServicePointOperationStatsModel({
    required this.retraits,
    required this.depots,
    required this.transferts,
    required this.commission,
    this.date,
    this.timezone,
  });

  factory ServicePointOperationStatsModel.fromJson(Map<String, dynamic> json) {
    return ServicePointOperationStatsModel(
      retraits: _readInt(json['retraits']),
      depots: _readInt(json['depots']),
      transferts: _readInt(json['transferts']),
      commission: _readDouble(json['total_commission'] ?? json['commission']),
      date: json['date']?.toString(),
      timezone: json['timezone']?.toString(),
    );
  }

  ServicePointOperationStats toEntity() {
    return ServicePointOperationStats(
      retraits: retraits,
      depots: depots,
      transferts: transferts,
      commission: commission,
      date: date,
      timezone: timezone,
    );
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
