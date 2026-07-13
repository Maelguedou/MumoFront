import '../domain/entities/service_point.dart';
import '../domain/entities/service_point_daily_recap.dart';
import '../domain/entities/service_point_operation_stats.dart';

class ServicePointStateModel {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final ServicePoint? servicePoint;
  final String? generatedPassword;
  final bool isLoadingList;
  final String? listErrorMessage;
  final List<ServicePoint> servicePoints;
  final ServicePoint? myServicePoint;
  final ServicePointOperationStats? operationStats;
  final bool isLoadingOperationStats;
  final String? operationStatsErrorMessage;
  final List<ServicePointDailyRecap> dailyRecap;
  final bool isLoadingDailyRecap;
  final String? dailyRecapErrorMessage;

  static const Object _unset = Object();

  ServicePointStateModel({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.servicePoint,
    this.generatedPassword,
    this.isLoadingList = false,
    this.listErrorMessage,
    this.servicePoints = const [],
    this.myServicePoint,
    this.operationStats,
    this.isLoadingOperationStats = false,
    this.operationStatsErrorMessage,
    this.dailyRecap = const [],
    this.isLoadingDailyRecap = false,
    this.dailyRecapErrorMessage,
  });

  ServicePointStateModel copyWith({
    bool? isLoading,
    Object? errorMessage = _unset,
    bool? isSuccess,
    ServicePoint? servicePoint,
    Object? generatedPassword = _unset,
    bool? isLoadingList,
    Object? listErrorMessage = _unset,
    List<ServicePoint>? servicePoints,
    ServicePoint? myServicePoint,
    ServicePointOperationStats? operationStats,
    bool? isLoadingOperationStats,
    Object? operationStatsErrorMessage = _unset,
    List<ServicePointDailyRecap>? dailyRecap,
    bool? isLoadingDailyRecap,
    Object? dailyRecapErrorMessage = _unset,
  }) {
    return ServicePointStateModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      isSuccess: isSuccess ?? this.isSuccess,
      servicePoint: servicePoint ?? this.servicePoint,
      generatedPassword: identical(generatedPassword, _unset)
          ? this.generatedPassword
          : generatedPassword as String?,
      isLoadingList: isLoadingList ?? this.isLoadingList,
      listErrorMessage: identical(listErrorMessage, _unset)
          ? this.listErrorMessage
          : listErrorMessage as String?,
      servicePoints: servicePoints ?? this.servicePoints,
      myServicePoint: myServicePoint ?? this.myServicePoint,
      operationStats: operationStats ?? this.operationStats,
      isLoadingOperationStats:
          isLoadingOperationStats ?? this.isLoadingOperationStats,
      operationStatsErrorMessage: identical(operationStatsErrorMessage, _unset)
          ? this.operationStatsErrorMessage
          : operationStatsErrorMessage as String?,
      dailyRecap: dailyRecap ?? this.dailyRecap,
      isLoadingDailyRecap: isLoadingDailyRecap ?? this.isLoadingDailyRecap,
      dailyRecapErrorMessage: identical(dailyRecapErrorMessage, _unset)
          ? this.dailyRecapErrorMessage
          : dailyRecapErrorMessage as String?,
    );
  }
}
