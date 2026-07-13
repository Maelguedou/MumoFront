import '../agency_model.dart';

class AgencyResponse {
  final AgencyModel agency;

  AgencyResponse({required this.agency});

  factory AgencyResponse.fromJson(Map<String, dynamic> json) {
    final agencyJson = json['agency'] is Map<String, dynamic>
        ? json['agency'] as Map<String, dynamic>
        : json;
    return AgencyResponse(
      agency: AgencyModel.fromJson(agencyJson),
    );
  }
}
