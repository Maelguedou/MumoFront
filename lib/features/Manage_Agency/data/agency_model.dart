import '../domain/entities/agency.dart';

class AgencyModel {
  final String? id;
  final String? location;
  final String? name;
  final String? deletedAt;

  AgencyModel({
    this.id,
    this.location,
    this.name,
    this.deletedAt,
  });

  factory AgencyModel.fromJson(Map<String, dynamic> json) {
    return AgencyModel(
      id: json['id']?.toString(),
      location: json['location']?.toString(),
      name: json['name']?.toString(),
      deletedAt: (json['deleted_at'] ?? json['deletedAt'])?.toString(),
    );
  }

  Agency toEntity() {
    return Agency(
      id: id,
      location: location,
      name: name,
      deletedAt: deletedAt,
    );
  }
}