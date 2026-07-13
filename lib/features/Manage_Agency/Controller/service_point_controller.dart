import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/service_point_state_model.dart';
import '../di/service_point_provider.dart';
import '../domain/entities/agent_lookup_result.dart';

final servicePointControllerProvider =
    NotifierProvider<ServicePointController, ServicePointStateModel>(() {
      return ServicePointController();
    });

class ServicePointController extends Notifier<ServicePointStateModel> {
  @override
  ServicePointStateModel build() {
    return ServicePointStateModel();
  }

  Future<void> createServicePoint({
    required String nameService,
    required String typeAgent,
    String? name,
    String? lastname,
    String? email,
    String? phone,
    String? npi,
    String? userId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
      generatedPassword: null,
    );

    final result = await ref
        .read(createServicePointUseCaseProvider)
        .call(
          nameService: nameService,
          typeAgent: typeAgent,
          name: name,
          lastname: lastname,
          email: email,
          phone: phone,
          npi: npi,
          userId: userId,
        );

    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        servicePoint: result.data!.servicePoint,
        generatedPassword: result.data!.generatedPassword,
      );
      await fetchServicePoints();
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            result.error?.message ??
            'Erreur lors de la creation du point de service',
      );
    }
  }

  Future<void> fetchServicePoints() async {
    state = state.copyWith(isLoadingList: true, listErrorMessage: null);
    final result = await ref.read(getServicePointsUseCaseProvider).call();
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(isLoadingList: false, servicePoints: result.data!);
    } else {
      state = state.copyWith(
        isLoadingList: false,
        listErrorMessage:
            result.error?.message ?? 'Erreur lors du chargement des cabines',
      );
    }
  }

  Future<void> fetchDailyRecap({bool showLoading = true}) async {
    state = state.copyWith(
      isLoadingDailyRecap: showLoading,
      dailyRecapErrorMessage: null,
    );

    final result = await ref
        .read(servicePointRepositoryProvider)
        .getDailyRecap();

    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        isLoadingDailyRecap: false,
        dailyRecap: result.data!,
      );
    } else {
      state = state.copyWith(
        isLoadingDailyRecap: false,
        dailyRecapErrorMessage:
            result.error?.message ??
            'Erreur lors du chargement du recap journalier',
      );
    }
  }

  Future<void> toggleServicePointStatus({
    required String id,
    required bool currentStatus,
  }) async {
    state = state.copyWith(listErrorMessage: null);
    final newStatus = !currentStatus;
    final result = await ref
        .read(servicePointRepositoryProvider)
        .updateServicePointStatus(id: id, status: newStatus);
    if (result.isSuccess) {
      await fetchServicePoints();
    } else {
      state = state.copyWith(
        listErrorMessage:
            result.error?.message ?? 'Erreur lors de la mise a jour du statut',
      );
    }
  }

  Future<void> updateServicePoint({
    required String id,
    String? nameService,
    String? typeAgent,
    String? userId,
    String? name,
    String? lastname,
    String? email,
    String? phone,
    String? npi,
  }) async {
    state = state.copyWith(
      isLoading: true,
      listErrorMessage: null,
      isSuccess: false,
      generatedPassword: null,
    );
    final result = await ref
        .read(servicePointRepositoryProvider)
        .updateServicePoint(
          id: id,
          nameService: nameService,
          typeAgent: typeAgent,
          userId: userId,
          name: name,
          lastname: lastname,
          email: email,
          phone: phone,
          npi: npi,
        );
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        generatedPassword: result.data!.generatedPassword,
      );
      await fetchServicePoints();
    } else {
      state = state.copyWith(
        isLoading: false,
        listErrorMessage:
            result.error?.message ??
            'Erreur lors de la mise a jour du point de service',
      );
    }
  }

  Future<AgentLookupResult?> findAgent({String? phone, String? npi}) async {
    final result = await ref
        .read(servicePointRepositoryProvider)
        .findAgent(phone: phone, npi: npi);

    if (result.isSuccess) {
      return result.data;
    }

    state = state.copyWith(
      errorMessage: result.error?.message ?? 'Erreur lors de la recherche',
    );
    return null;
  }

  void resetStatus() {
    state = state.copyWith(
      isLoading: false,
      isSuccess: false,
      errorMessage: null,
      generatedPassword: null,
    );
  }

  Future<void> fetchMyServicePoint() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final model = await ref
          .read(servicePointRemoteDataSourceProvider)
          .getMyServicePoint();
      if (model != null) {
        final servicePoint = model.toEntity();
        state = state.copyWith(isLoading: false, myServicePoint: servicePoint);
        final id = servicePoint.id;
        if (id != null && id.isNotEmpty) {
          await fetchOperationStats(id);
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Point de service non trouvé',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur lors du chargement de vos informations',
      );
    }
  }

  Future<void> fetchOperationStats(String servicePointId) async {
    state = state.copyWith(
      isLoadingOperationStats: true,
      operationStatsErrorMessage: null,
    );

    final result = await ref
        .read(servicePointRepositoryProvider)
        .getOperationStats(servicePointId);

    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        isLoadingOperationStats: false,
        operationStats: result.data,
      );
    } else {
      state = state.copyWith(
        isLoadingOperationStats: false,
        operationStatsErrorMessage:
            result.error?.message ??
            'Erreur lors du chargement des statistiques',
      );
    }
  }
}
