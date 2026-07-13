import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/agency_register_state_model.dart';
import '../di/agency_provider.dart';

final agencyRegisterControllerProvider =
		NotifierProvider<AgencyRegisterController, AgencyRegisterStateModel>(() {
	return AgencyRegisterController();
});

class AgencyRegisterController extends Notifier<AgencyRegisterStateModel> {
	@override
	AgencyRegisterStateModel build() {
		return AgencyRegisterStateModel();
	}

	Future<void> createAgency({
		required String location,
		required String name,
	}) async {
		state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

		final result = await ref.read(createAgencyUseCaseProvider).call(
					location: location,
					name: name,
				);

		if (result.isSuccess) {
			state = state.copyWith(
				isLoading: false,
				isSuccess: true,
				agency: result.data,
			);
		} else {
			state = state.copyWith(
				isLoading: false,
				errorMessage: result.error?.message ??
						'Erreur lors de la creation de l\'agence',
			);
		}
	}

	void resetStatus() {
		state = state.copyWith(
			isLoading: false,
			isSuccess: false,
			errorMessage: null,
		);
	}
}
