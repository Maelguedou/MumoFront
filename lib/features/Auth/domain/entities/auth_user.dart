class AuthContext {
  final String? role;
  final String? agencyId;
  final String? agencyName;
  final String? servicePointId;
  final String? servicePointName;

  const AuthContext({
    this.role,
    this.agencyId,
    this.agencyName,
    this.servicePointId,
    this.servicePointName,
  });

  bool get isManager => role?.toLowerCase() == 'admin';
  bool get isAgent {
    final normalized = role?.toLowerCase();
    return normalized == 'user' || normalized == 'agent';
  }
}

class AuthUser {
  final String? id;
  final String? npi;
  final String? name;
  final String? firstName;
  final String? phone;
  final String? lastname;
  final String? role;
  final String? email;
  final bool? mustChangePassword;
  final List<AuthContext> contexts;

  const AuthUser({
    this.id,
    this.npi,
    this.name,
    this.firstName,
    this.phone,
    this.lastname,
    this.role,
    this.email,
    this.mustChangePassword,
    this.contexts = const [],
  });
}
