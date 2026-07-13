class RegisterRequest {
  final String name;
  final String lastName;
  final String email;
  final String phone;
  final String npi;
  final String password;
  final String passwordConfirmation;

  RegisterRequest({
    required this.name,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.npi,
    required this.password,
    required this.passwordConfirmation,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'lastname': lastName,
    'email': email,
    'phone': phone,
    'npi': npi,
    'password': password,
    'password_confirmation': passwordConfirmation,
  };
}
