class ExecuteOperationRequest {
  final int ussdId;
  final String? number;
  final double amount;
  final String? pin;
  final String servicePointId;

  ExecuteOperationRequest({
    required this.ussdId,
    this.number,
    required this.amount,
    this.pin,
    required this.servicePointId,
  });

  Map<String, dynamic> toJson() {
    return {
      'ussd_id': ussdId,
      if (number != null) 'number': number,
      'amount': amount,
      if (pin != null) 'pin': pin,
      'service_point_id': int.parse(servicePointId),
    };
  }
}

class ExecuteOperationResponse {
  final int operationId;
  final String ussdCode;

  ExecuteOperationResponse({required this.operationId, required this.ussdCode});

  factory ExecuteOperationResponse.fromJson(Map<String, dynamic> json) {
    return ExecuteOperationResponse(
      operationId: json['operation_id'],
      ussdCode: json['ussd_code'],
    );
  }
}
