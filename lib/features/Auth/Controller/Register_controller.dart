import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/login_state_model.dart';
import '../di/auth_providers.dart';

final registerControllerProvider = NotifierProvider<RegisterController, AuthStateModel>(() {
	return RegisterController();
});

class RegisterController extends Notifier<AuthStateModel> {
	@override
	AuthStateModel build() {
		return AuthStateModel();
	}

	Future<void> register({
		required String firstName,
		required String lastName,
		required String email,
		required String phone,
		required String npi,
		required String password,
		required String passwordConfirmation,
	}) async {
		state = state.copyWith(isLoading: true, errorMessage: null);

		final result = await ref.read(registerUseCaseProvider).call(
			firstName: firstName,
			lastName: lastName,
			email: email,
			phone: phone,
			npi: npi,
			password: password,
			passwordConfirmation: passwordConfirmation,
		);

		if (result.isSuccess) {
			state = state.copyWith(
				isLoading: false,
				isSuccess: true,
				user: result.data,
			);
		} else {
			state = state.copyWith(
				isLoading: false,
				errorMessage: result.error?.message ?? 'Erreur lors de l\'inscription',
			);
		}
	}
}
