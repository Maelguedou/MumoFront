import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Auth/Controller/login_controller.dart';
import '../data/agency_check_state_model.dart';
import '../di/agency_provider.dart';

final agencyCheckControllerProvider =
    NotifierProvider<AgencyCheckController, AgencyCheckStateModel>(() {
  return AgencyCheckController();
});

class AgencyCheckController extends Notifier<AgencyCheckStateModel> {
  static const Set<String> _managerRoles = {'admin'};

  @override
  AgencyCheckStateModel build() {
    return AgencyCheckStateModel();
  }

  void setAgency(dynamic agency) {
    if (agency == null) return;
    state = state.copyWith(
      isLoading: false,
      isChecked: true,
      hasAgency: true,
      agency: agency,
      errorMessage: null,
      statusCode: null,
    );
  }

  Future<void> checkAgency() async {
    final role = ref.read(authControllerProvider).user?.role?.trim().toLowerCase();
    final isManager = role != null && _managerRoles.contains(role);
    if (!isManager) {
      state = state.copyWith(
        isLoading: false,
        isChecked: true,
        hasAgency: false,
        errorMessage: null,
        statusCode: null,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isChecked: false,
      errorMessage: null,
      statusCode: null,
    );

    final result = await ref.read(hasAgencyUseCaseProvider).call();

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        isChecked: true,
        hasAgency: true,
        agency: result.data,
      );
      return;
    }

    final statusCode = result.error?.statusCode;
    if (statusCode == 404) {
      state = state.copyWith(
        isLoading: false,
        isChecked: true,
        hasAgency: false,
        errorMessage: null,
        statusCode: statusCode,
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      isChecked: true,
      hasAgency: false,
      errorMessage: result.error?.message ??
          'Erreur lors de la verification de l\'agence',
      statusCode: statusCode,
    );
  }
}
