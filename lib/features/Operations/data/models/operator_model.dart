class UssdModel {
  final int id;
  final String operationType;
  final String? label;
  final String pattern;
  final bool requiresNumber;
  final bool requiresAmount;
  final bool requiresPin;
  final bool isActive;
  final int sortOrder;

  UssdModel({
    required this.id,
    required this.operationType,
    this.label,
    required this.pattern,
    required this.requiresNumber,
    required this.requiresAmount,
    required this.requiresPin,
    required this.isActive,
    required this.sortOrder,
  });

  factory UssdModel.fromJson(Map<String, dynamic> json) {
    return UssdModel(
      id: json['id'],
      operationType: json['operation_type'],
      label: json['label'],
      pattern: json['pattern'],
      requiresNumber: _readBool(json['requires_number'], fallback: true),
      requiresAmount: _readBool(json['requires_amount'], fallback: true),
      requiresPin: _readBool(json['requires_pin']),
      isActive: _readBool(json['is_active'], fallback: true),
      sortOrder: _readInt(json['sort_order']),
    );
  }

  String get displayLabel => label?.trim().isNotEmpty == true
      ? label!.trim()
      : operationType.toUpperCase();

  static bool _readBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return fallback;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class OperatorModel {
  final int id;
  final String name;
  final List<UssdModel> ussds;

  OperatorModel({
    required this.id,
    required this.name,
    required this.ussds,
  });

  factory OperatorModel.fromJson(Map<String, dynamic> json) {
    return OperatorModel(
      id: json['id'],
      name: json['name'],
      ussds: (json['ussd'] as List?)
              ?.map((i) => UssdModel.fromJson(i))
              .toList() ??
          [],
    );
  }
}
