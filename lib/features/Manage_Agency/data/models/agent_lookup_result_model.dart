import '../../domain/entities/agent_lookup_result.dart';

class AgentLookupResultModel {
  final bool exists;
  final String? userId;
  final String? name;
  final String? lastname;
  final String? phone;
  final String? npi;
  final bool canBeAssigned;
  final String? reason;

  const AgentLookupResultModel({
    required this.exists,
    this.userId,
    this.name,
    this.lastname,
    this.phone,
    this.npi,
    required this.canBeAssigned,
    this.reason,
  });

  factory AgentLookupResultModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userJson = user is Map<String, dynamic> ? user : null;
    final availability = json['availability'];
    final availabilityJson = availability is Map<String, dynamic>
        ? availability
        : const <String, dynamic>{};

    return AgentLookupResultModel(
      exists: json['exists'] == true,
      userId: userJson?['id']?.toString(),
      name: userJson?['name']?.toString(),
      lastname: (userJson?['lastname'] ?? userJson?['last_name'])?.toString(),
      phone: userJson?['phone']?.toString(),
      npi: userJson?['npi']?.toString(),
      canBeAssigned: availabilityJson['can_be_assigned'] == true,
      reason: availabilityJson['reason']?.toString(),
    );
  }

  AgentLookupResult toEntity() {
    return AgentLookupResult(
      exists: exists,
      userId: userId,
      name: name,
      lastname: lastname,
      phone: phone,
      npi: npi,
      canBeAssigned: canBeAssigned,
      reason: reason,
    );
  }
}
