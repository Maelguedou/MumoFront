class Agency {
  final String? id;
  final String? location;
  final String? name;
  final String? deletedAt;

  bool get isDeleted => deletedAt != null && deletedAt!.isNotEmpty;

  const Agency({
    this.id,
    this.location,
    this.name,
    this.deletedAt,
  });
}
