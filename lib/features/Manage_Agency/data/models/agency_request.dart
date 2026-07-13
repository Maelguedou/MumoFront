class AgencyRequest {
  final String name;
  final String location;

  AgencyRequest({
    required this.name,
    required this.location,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'location': location,
      };
}
