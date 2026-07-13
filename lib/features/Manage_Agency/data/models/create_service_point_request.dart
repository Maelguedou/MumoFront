class CreateServicePointRequest {
  final String nameService;
  final String typeAgent;
  final String? name;
  final String? lastname;
  final String? email;
  final String? phone;
  final String? npi;
  final String? userId;

  CreateServicePointRequest({
    required this.nameService,
    required this.typeAgent,
    this.name,
    this.lastname,
    this.email,
    this.phone,
    this.npi,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'name_service': nameService,
      'type_agent': typeAgent,
    };

    if (typeAgent == 'existing' && userId != null && userId!.isNotEmpty) {
      payload['user_id'] = userId;
    }

    if (typeAgent == 'new') {
      if (name != null && name!.isNotEmpty) {
        payload['name'] = name;
      }
      if (lastname != null && lastname!.isNotEmpty) {
        payload['lastname'] = lastname;
      }
      if (email != null && email!.isNotEmpty) {
        payload['email'] = email;
      }
      if (phone != null && phone!.isNotEmpty) {
        payload['phone'] = phone;
      }
      if (npi != null && npi!.isNotEmpty) {
        payload['npi'] = npi;
      }
    }

    return payload;
  }
}
