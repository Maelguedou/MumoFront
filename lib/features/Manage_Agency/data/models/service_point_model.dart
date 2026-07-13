import '../../domain/entities/service_point.dart';

class ServicePointModel {
  final String? id;
  final String? name;
  final String? userId;
  final String? agencyId;
  final String? agencyName;
  final bool status;
  final String? username;

  ServicePointModel({
    this.id,
    this.name,
    this.userId,
    this.agencyId,
    this.agencyName,
    this.status = false,
    this.username,
  });

  factory ServicePointModel.fromJson(Map<String, dynamic> json) {
    final member = json['member'];
    final memberJson = member is Map<String, dynamic> ? member : null;
    final user = memberJson?['user'] ?? json['user'];
    String? username;
    String? userId;
    if (user is Map<String, dynamic>) {
      userId = user['id']?.toString();
      final firstName = user['name']?.toString();
      final lastName = (user['lastname'] ?? user['last_name'])?.toString();
      final fullName = [
        firstName,
        lastName,
      ].where((value) => value != null && value.trim().isNotEmpty).join(' ');
      username = fullName.isNotEmpty ? fullName : user['full_name']?.toString();
    }
    final agency = json['agency'];
    String? agencyName;
    if (agency is Map<String, dynamic>) {
      agencyName = agency['name']?.toString();
    }
    final statusValue = json['status'];
    final status = statusValue is bool
        ? statusValue
        : statusValue == 1 ||
              statusValue == '1' ||
              statusValue?.toString().toLowerCase() == 'true';
    return ServicePointModel(
      id: json['id']?.toString(),
      name: (json['name_service'] ?? json['name'])?.toString(),
      userId: userId ?? json['user_id']?.toString(),
      agencyId: json['agency_id']?.toString(),
      agencyName: agencyName ?? json['agency_name']?.toString(),
      status: status,
      username: username ?? json['username']?.toString(),
    );
  }

  ServicePoint toEntity() {
    return ServicePoint(
      id: id,
      name: name,
      userId: userId,
      agencyId: agencyId,
      agencyName: agencyName,
      status: status,
      username: username,
    );
  }
}
