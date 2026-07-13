import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/agency_register_state_model.dart';
import '../di/agency_provider.dart';

final agencyEditControllerProvider =
    NotifierProvider<AgencyEditController, AgencyRegisterStateModel>(() {
  return AgencyEditController();
});

class AgencyEditController extends Notifier<AgencyRegisterStateModel> {
  @override
  AgencyRegisterStateModel build() {
    return AgencyRegisterStateModel();
  }

  Future<void> updateAgency({
    required String id,
    required String location,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    final result = await ref.read(updateAgencyUseCaseProvider).call(
          id: id,
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
        errorMessage: result.error?.message ?? 'Erreur lors de la mise a jour de l\'agence',
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