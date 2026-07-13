import '../domain/entities/auth_user.dart';

class UserModel {
  final String? id;
  final String? npi;
  final String? name;
  final String? phone;
  final String? lastname;
  final String? role;
  final String? email;
  final bool? mustChangePassword;
  final List<AuthContext> contexts;

  UserModel({
    this.id,
    this.npi,
    this.name,
    this.phone,
    this.lastname,
    this.role,
    this.email,
    this.mustChangePassword,
    this.contexts = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var roleData = json['role'] ?? json['type_agent'] ?? json['user_type'];
    String? roleStr;
    if (roleData is Map) {
      roleStr = roleData['title']?.toString();
    } else {
      roleStr = roleData?.toString();
    }

    final lastname = json['last_name'] ?? json['lastname'];
    final contextsJson = json['contexts'];
    final contexts = contextsJson is List
        ? contextsJson
              .whereType<Map>()
              .map(
                (item) => AuthContext(
                  role: item['role']?.toString(),
                  agencyId: item['agency_id']?.toString(),
                  agencyName: item['agency_name']?.toString(),
                  servicePointId: item['service_point_id']?.toString(),
                  servicePointName: item['service_point_name']?.toString(),
                ),
              )
              .toList()
        : const <AuthContext>[];
    return UserModel(
      id: json['id']?.toString(),
      npi: json['npi']?.toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      lastname: lastname?.toString(),
      role: roleStr,
      email: json['email']?.toString(),
      mustChangePassword: json['must_change_password'] as bool?,
      contexts: contexts,
    );
  }

  factory UserModel.fromEntity(AuthUser user) {
    return UserModel(
      id: user.id,
      npi: user.npi,
      name: user.name,
      phone: user.phone,
      lastname: user.lastname,
      role: user.role,
      email: user.email,
      mustChangePassword: user.mustChangePassword,
      contexts: user.contexts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'npi': npi,
      'name': name,
      'phone': phone,
      'last_name': lastname,
      'role': role,
      'email': email,
      'must_change_password': mustChangePassword,
      'contexts': contexts
          .map(
            (context) => {
              'role': context.role,
              'agency_id': context.agencyId,
              'agency_name': context.agencyName,
              'service_point_id': context.servicePointId,
              'service_point_name': context.servicePointName,
            },
          )
          .toList(),
    };
  }

  AuthUser toEntity() {
    return AuthUser(
      id: id,
      npi: npi,
      name: name,
      phone: phone,
      lastname: lastname,
      role: role,
      email: email,
      mustChangePassword: mustChangePassword,
      contexts: contexts,
    );
  }
}
