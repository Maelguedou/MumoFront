import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/agency_stats_state_model.dart';
import '../di/agency_stats_provider.dart';

final agencyStatsControllerProvider =
    NotifierProvider<AgencyStatsController, AgencyStatsStateModel>(() {
      return AgencyStatsController();
    });

class AgencyStatsController extends Notifier<AgencyStatsStateModel> {
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  AgencyStatsStateModel build() {
    final today = _day(DateTime.now());
    return AgencyStatsStateModel(
      preset: AgencyStatsPeriodPreset.sevenDays,
      startDate: today.subtract(const Duration(days: 6)),
      endDate: today,
    );
  }

  Future<void> load() async {
    final query = _query(state.startDate, state.endDate);
    debugPrint('[STATS] Controller load query=$query preset=${state.preset}');
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await ref
        .read(agencyStatsRepositoryProvider)
        .getDashboard(query);

    if (result.isSuccess && result.data != null) {
      debugPrint('[STATS] Controller load success');
      state = state.copyWith(isLoading: false, dashboard: result.data);
    } else {
      debugPrint('[STATS] Controller load failure=${result.error?.message}');
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            result.error?.message ??
            'Erreur lors du chargement des statistiques',
      );
    }
  }

  Future<void> setPreset(AgencyStatsPeriodPreset preset) async {
    final today = _day(DateTime.now());
    final start = switch (preset) {
      AgencyStatsPeriodPreset.today => today,
      AgencyStatsPeriodPreset.sevenDays => today.subtract(
        const Duration(days: 6),
      ),
      AgencyStatsPeriodPreset.thirtyDays => today.subtract(
        const Duration(days: 29),
      ),
      AgencyStatsPeriodPreset.custom => state.startDate,
    };

    state = state.copyWith(preset: preset, startDate: start, endDate: today);
    await load();
  }

  Future<void> setCustomRange(DateTime startDate, DateTime endDate) async {
    state = state.copyWith(
      preset: AgencyStatsPeriodPreset.custom,
      startDate: _day(startDate),
      endDate: _day(endDate),
    );
    await load();
  }

  Map<String, dynamic> _query(DateTime startDate, DateTime endDate) {
    return {
      'start_date': _dateFormat.format(startDate),
      'end_date': _dateFormat.format(endDate),
    };
  }

  DateTime _day(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
