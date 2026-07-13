import '../domain/entities/agency.dart';

class AgencyRegisterStateModel {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final Agency? agency;

  static const Object _unset = Object();

  AgencyRegisterStateModel({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.agency,
  });

  AgencyRegisterStateModel copyWith({
    bool? isLoading,
    Object? errorMessage = _unset,
    bool? isSuccess,
    Agency? agency,
  }) {
    return AgencyRegisterStateModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          identical(errorMessage, _unset) ? this.errorMessage : errorMessage as String?,
      isSuccess: isSuccess ?? this.isSuccess,
      agency: agency ?? this.agency,
    );
  }
}
