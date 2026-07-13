class RegisterDraft {
	final String firstName;
	final String lastName;
	final String email;
	final String phone;
	final String npi;
	final String password;
	final String confirmPassword;

	const RegisterDraft({
		this.firstName = '',
		this.lastName = '',
		this.email = '',
		this.phone = '',
		this.npi = '',
		this.password = '',
		this.confirmPassword = '',
	});

	RegisterDraft copyWith({
		String? firstName,
		String? lastName,
		String? email,
		String? phone,
		String? npi,
		String? password,
		String? confirmPassword,
	}) {
		return RegisterDraft(
			firstName: firstName ?? this.firstName,
			lastName: lastName ?? this.lastName,
			email: email ?? this.email,
			phone: phone ?? this.phone,
			npi: npi ?? this.npi,
			password: password ?? this.password,
			confirmPassword: confirmPassword ?? this.confirmPassword,
		);
	}
}
