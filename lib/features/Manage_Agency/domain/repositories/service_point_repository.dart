import '../../../../core/utils/result.dart';
import '../entities/agent_lookup_result.dart';
import '../entities/service_point_creation_result.dart';
import '../entities/service_point.dart';
import '../entities/service_point_daily_recap.dart';
import '../entities/service_point_operation_stats.dart';

abstract class ServicePointRepository {
  Future<Result<ServicePointCreationResult>> createServicePoint({
    required String nameService,
    required String typeAgent,
    String? name,
    String? lastname,
    String? email,
    String? phone,
    String? npi,
    String? userId,
  });

  Future<Result<List<ServicePoint>>> getServicePoints();

  Future<Result<List<ServicePointDailyRecap>>> getDailyRecap();

  Future<Result<ServicePointOperationStats>> getOperationStats(String id);

  Future<Result<void>> updateServicePointStatus({
    required String id,
    required bool status,
  });

  Future<Result<ServicePointCreationResult>> updateServicePoint({
    required String id,
    String? nameService,
    String? typeAgent,
    String? userId,
    String? name,
    String? lastname,
    String? email,
    String? phone,
    String? npi,
  });

  Future<Result<AgentLookupResult>> findAgent({String? phone, String? npi});
}
