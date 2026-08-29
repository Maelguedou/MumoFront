import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/agency_insight_state_model.dart';
import '../di/agency_insight_provider.dart';
import '../domain/entities/agency_insight.dart';

class AgencyInsightController extends Notifier<AgencyInsightState> {
  @override
  AgencyInsightState build() {
    return const AgencyInsightState();
  }

  /// Génère ou récupère l'analyse de la période courante, puis charge son historique.
  Future<void> loadCurrentPeriod({String? granularity}) async {
    final targetGranularity = granularity ?? state.selectedGranularity;
    final dates = _currentPeriod(targetGranularity);

    await generateInsight(
      startDate: dates.start,
      endDate: dates.end,
      granularity: targetGranularity,
    );

    // L'historique est rechargé pour refléter la source persistée du backend.
    if (state.errorMessage == null) {
      await loadHistory(granularity: targetGranularity);
    }
  }

  ({String start, String end}) _currentPeriod(String granularity) {
    final today = DateTime.now();
    final currentDay = DateTime(today.year, today.month, today.day);
    final formatter = DateFormat('yyyy-MM-dd');

    if (granularity == 'daily') {
      final yesterday = currentDay.subtract(const Duration(days: 1));
      return (
        start: formatter.format(yesterday),
        end: formatter.format(yesterday),
      );
    }

    final firstDayOfCurrentMonth = DateTime(today.year, today.month, 1);
    final lastDayOfPreviousMonth = firstDayOfCurrentMonth.subtract(
      const Duration(days: 1),
    );
    final firstDayOfPreviousMonth = DateTime(
      lastDayOfPreviousMonth.year,
      lastDayOfPreviousMonth.month,
      1,
    );

    return (
      start: formatter.format(firstDayOfPreviousMonth),
      end: formatter.format(lastDayOfPreviousMonth),
    );
  }

  /// Charge l'historique des insights pour la granularité sélectionnée
  Future<void> loadHistory({String? granularity}) async {
    final targetGranularity = granularity ?? state.selectedGranularity;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      selectedGranularity: targetGranularity,
    );

    final usecase = ref.read(getAgencyInsightHistoryUseCaseProvider);
    final result = await usecase(
      granularity: targetGranularity,
      limit: state.historyLimit,
    );

    if (result.isSuccess) {
      final historyList = result.data ?? [];
      state = state.copyWith(
        isLoading: false,
        history: historyList,
        selectedInsight: historyList.isNotEmpty ? historyList.first : null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            result.error?.message ??
            'Erreur lors du chargement de l\'historique.',
      );
    }
  }

  /// Demande la génération d'un nouvel insight par l'IA
  Future<void> generateInsight({
    required String startDate,
    required String endDate,
    String? granularity,
  }) async {
    final targetGranularity = granularity ?? state.selectedGranularity;

    state = state.copyWith(
      isGenerating: true,
      errorMessage: null,
      successMessage: null,
    );

    final usecase = ref.read(generateAgencyInsightUseCaseProvider);
    final result = await usecase(
      startDate: startDate,
      endDate: endDate,
      granularity: targetGranularity,
    );

    if (result.isSuccess && result.data != null) {
      final newInsight = result.data!;

      // Le backend peut retourner un insight deja existant pour la meme
      // periode. On retire son ancienne occurrence avant de le placer en tete.
      final updatedHistory = [
        newInsight,
        ...state.history.where((insight) => insight.id != newInsight.id),
      ];

      state = state.copyWith(
        isGenerating: false,
        selectedInsight: newInsight,
        history: updatedHistory,
        successMessage: 'Nouvel insight généré avec succès !',
      );
    } else {
      state = state.copyWith(
        isGenerating: false,
        errorMessage:
            result.error?.message ?? 'Impossible de générer l\'insight.',
      );
    }
  }

  /// Sélectionne un insight précis dans l'historique
  void selectInsight(AgencyInsight insight) {
    state = state.copyWith(selectedInsight: insight);
  }

  /// Réinitialise les messages d'erreur ou de succès
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}
