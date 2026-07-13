class AgentLookupResult {
  final bool exists;
  final String? userId;
  final String? name;
  final String? lastname;
  final String? phone;
  final String? npi;
  final bool canBeAssigned;
  final String? reason;

  const AgentLookupResult({
    required this.exists,
    this.userId,
    this.name,
    this.lastname,
    this.phone,
    this.npi,
    required this.canBeAssigned,
    this.reason,
  });

  String get displayName {
    final parts = [
      name,
      lastname,
    ].where((value) => value != null && value.trim().isNotEmpty).join(' ');

    return parts.isNotEmpty ? parts : 'Utilisateur existant';
  }
}
