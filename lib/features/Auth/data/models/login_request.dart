class LoginRequest {
  final String npi;
  final String password;

  LoginRequest({required this.npi, required this.password});

  Map<String, dynamic> toJson() => {
    'npi': npi,
    'password': password,
  };
}
