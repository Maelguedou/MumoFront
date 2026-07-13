import '../domain/entities/agency.dart';

class AgencyCheckStateModel {
  final bool isLoading;
  final bool isChecked;
  final bool hasAgency;
  final Agency? agency;
  final String? errorMessage;
  final int? statusCode;

  AgencyCheckStateModel({
    this.isLoading = false,
    this.isChecked = false,
    this.hasAgency = false,
    this.agency,
    this.errorMessage,
    this.statusCode,
  });

  AgencyCheckStateModel copyWith({
    bool? isLoading,
    bool? isChecked,
    bool? hasAgency,
    Agency? agency,
    String? errorMessage,
    int? statusCode,
  }) {
    return AgencyCheckStateModel(
      isLoading: isLoading ?? this.isLoading,
      isChecked: isChecked ?? this.isChecked,
      hasAgency: hasAgency ?? this.hasAgency,
      agency: agency ?? this.agency,
      errorMessage: errorMessage ?? this.errorMessage,
      statusCode: statusCode ?? this.statusCode,
    );
  }
}
