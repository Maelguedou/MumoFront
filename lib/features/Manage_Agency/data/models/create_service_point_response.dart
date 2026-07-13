import 'service_point_model.dart';

class CreateServicePointResponse {
  final ServicePointModel servicePoint;
  final String? generatedPassword;

  CreateServicePointResponse({
    required this.servicePoint,
    this.generatedPassword,
  });

  factory CreateServicePointResponse.fromJson(Map<String, dynamic> json) {
    final serviceJson = json['service'] is Map<String, dynamic>
        ? json['service'] as Map<String, dynamic>
        : json;

    return CreateServicePointResponse(
      servicePoint: ServicePointModel.fromJson(serviceJson),
      generatedPassword: json['generated_password']?.toString(),
    );
  }
}
