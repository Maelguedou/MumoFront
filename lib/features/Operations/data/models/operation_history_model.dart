class OperationHistoryItem {
  final int id;
  final String type;
  final double amount;
  final String? number;
  final String status;
  final String? reference;
  final String? generatedReference;
  final String? message;
  final String? operatorName;
  final String? serviceName;
  final String? ussdLabel;
  final DateTime? createdAt;
  final String? localDate;
  final String? localTime;

  const OperationHistoryItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    this.number,
    this.reference,
    this.generatedReference,
    this.message,
    this.operatorName,
    this.serviceName,
    this.ussdLabel,
    this.createdAt,
    this.localDate,
    this.localTime,
  });

  factory OperationHistoryItem.fromJson(Map<String, dynamic> json) {
    final operator = json['operator'];
    final service = json['service'];
    final ussd = json['ussd'];
    final createdAt = DateTime.tryParse(
      (json['created_at'] ?? json['date'])?.toString() ?? '',
    )?.toLocal();

    return OperationHistoryItem(
      id: _readInt(json['id']),
      type: json['type']?.toString() ?? '',
      amount: _readDouble(json['amount']),
      number: json['number']?.toString(),
      status: json['status']?.toString() ?? '',
      reference: json['reference']?.toString(),
      generatedReference:
          (json['generated_reference'] ?? json['generatedReference'])
              ?.toString(),
      message: json['message']?.toString(),
      operatorName: operator is Map<String, dynamic>
          ? operator['name']?.toString()
          : null,
      serviceName: service is Map<String, dynamic>
          ? service['name']?.toString()
          : null,
      ussdLabel:
          json['ussd_label']?.toString() ??
          (ussd is Map<String, dynamic> ? ussd['label']?.toString() : null),
      createdAt: createdAt,
      localDate: json['local_date']?.toString() ?? _formatDate(createdAt),
      localTime: json['local_time']?.toString() ?? _formatTime(createdAt),
    );
  }

  static String? _formatDate(DateTime? value) {
    if (value == null) return null;
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  static String? _formatTime(DateTime? value) {
    if (value == null) return null;
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
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
