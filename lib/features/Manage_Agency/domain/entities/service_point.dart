class ServicePoint {
  final String? id;
  final String? name;
  final String? userId;
  final String? agencyId;
  final String? agencyName;
  final bool status;
  final String? username;

  const ServicePoint({
    this.id,
    this.name,
    this.userId,
    this.agencyId,
    this.agencyName,
    this.status = false,
    this.username,
  });
}
