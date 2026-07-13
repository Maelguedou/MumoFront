import '../domain/entities/agency_stats.dart';

enum AgencyStatsPeriodPreset { today, sevenDays, thirtyDays, custom }

class AgencyStatsStateModel {
  final bool isLoading;
  final String? errorMessage;
  final AgencyStatsPeriodPreset preset;
  final DateTime startDate;
  final DateTime endDate;
  final AgencyStatsDashboard dashboard;

  const AgencyStatsStateModel({
    this.isLoading = false,
    this.errorMessage,
    required this.preset,
    required this.startDate,
    required this.endDate,
    this.dashboard = const AgencyStatsDashboard(),
  });

  AgencyStatsStateModel copyWith({
    bool? isLoading,
    Object? errorMessage = _unset,
    AgencyStatsPeriodPreset? preset,
    DateTime? startDate,
    DateTime? endDate,
    AgencyStatsDashboard? dashboard,
  }) {
    return AgencyStatsStateModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      preset: preset ?? this.preset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dashboard: dashboard ?? this.dashboard,
    );
  }

  static const Object _unset = Object();
}
