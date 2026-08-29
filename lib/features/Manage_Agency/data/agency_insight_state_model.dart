import '../domain/entities/agency_insight.dart';

class AgencyInsightState {
  final bool isLoading;
  final bool isGenerating;
  final String? errorMessage;
  final String? successMessage;
  final List<AgencyInsight> history;
  final AgencyInsight? selectedInsight;
  final String selectedGranularity; // 'daily' ou 'monthly'
  final int historyLimit;

  const AgencyInsightState({
    this.isLoading = false,
    this.isGenerating = false,
    this.errorMessage,
    this.successMessage,
    this.history = const [],
    this.selectedInsight,
    this.selectedGranularity = 'daily',
    this.historyLimit = 30,
  });

  AgencyInsightState copyWith({
    bool? isLoading,
    bool? isGenerating,
    Object? errorMessage = _unset,
    Object? successMessage = _unset,
    List<AgencyInsight>? history,
    Object? selectedInsight = _unset,
    String? selectedGranularity,
    int? historyLimit,
  }) {
    return AgencyInsightState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: identical(successMessage, _unset)
          ? this.successMessage
          : successMessage as String?,
      history: history ?? this.history,
      selectedInsight: identical(selectedInsight, _unset)
          ? this.selectedInsight
          : selectedInsight as AgencyInsight?,
      selectedGranularity: selectedGranularity ?? this.selectedGranularity,
      historyLimit: historyLimit ?? this.historyLimit,
    );
  }

  static const Object _unset = Object();
}
