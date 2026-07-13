import 'service_point.dart';

class ServicePointCreationResult {
  final ServicePoint servicePoint;
  final String? generatedPassword;

  const ServicePointCreationResult({
    required this.servicePoint,
    this.generatedPassword,
  });
}
