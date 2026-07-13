import '../../../../core/utils/result.dart';
import '../entities/agency.dart';

abstract class AgencyRepository {
  Future<Result<Agency>> createAgency({
    required String name,
    required String location,
  });

  Future<Result<Agency>> updateAgency({
    required String id,
    required String name,
    required String location,
  });

  Future<Result<Agency>> hasAgency();
}
