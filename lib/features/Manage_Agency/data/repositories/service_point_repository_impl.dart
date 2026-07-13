import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/user_friendly_error.dart';
import '../../domain/entities/agent_lookup_result.dart';
import '../../domain/entities/service_point.dart';
import '../../domain/entities/service_point_creation_result.dart';
import '../../domain/entities/service_point_daily_recap.dart';
import '../../domain/entities/service_point_operation_stats.dart';
import '../../domain/repositories/service_point_repository.dart';
import '../datasources/service_point_remote_datasource.dart';
import '../models/create_service_point_request.dart';
import '../models/service_point_model.dart';

class ServicePointRepositoryImpl implements ServicePointRepository {
  ServicePointRepositoryImpl(this._remote);

  final ServicePointRemoteDataSource _remote;

  @override
  Future<Result<ServicePointCreationResult>> createServicePoint({
    required String nameService,
    required String typeAgent,
    String? name,
    String? lastname,
    String? email,
    String? phone,
    String? npi,
    String? userId,
  }) async {
    try {
      final response = await _remote.createServicePoint(
        CreateServicePointRequest(
          nameService: nameService,
          typeAgent: typeAgent,
          name: name,
          lastname: lastname,
          email: email,
          phone: phone,
          npi: npi,
          userId: userId,
        ),
      );

      return Result.success(
        ServicePointCreationResult(
          servicePoint: response.servicePoint.toEntity(),
          generatedPassword: response.generatedPassword,
        ),
      );
    } on DioException catch (e) {
      // Temporary debug log for backend error details.
      debugPrint(
        'CreateServicePoint error: status=${e.response?.statusCode} data=${e.response?.data}',
      );
      final statusCode = e.response?.statusCode;
      final message = _mapDioError(e);
      return Result.failure(Failure(message, statusCode: statusCode));
    } catch (_) {
      return const Result.failure(
        Failure('Erreur inconnue lors de la creation du point de service'),
      );
    }
  }

  @override
  Future<Result<List<ServicePoint>>> getServicePoints() async {
    try {
      final response = await _remote.getServicePoints();
      final items = response.map((model) => model.toEntity()).toList();
      return Result.success(items);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _mapDioError(e);
      return Result.failure(Failure(message, statusCode: statusCode));
    } catch (_) {
      return const Result.failure(
        Failure('Erreur lors du chargement des cabines'),
      );
    }
  }

  @override
  Future<Result<List<ServicePointDailyRecap>>> getDailyRecap() async {
    try {
      final response = await _remote.getDailyRecap();
      final items = response.map((model) => model.toEntity()).toList();
      return Result.success(items);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _mapDioError(e);
      return Result.failure(Failure(message, statusCode: statusCode));
    } catch (_) {
      return const Result.failure(
        Failure('Erreur lors du chargement du recap journalier'),
      );
    }
  }

  @override
  Future<Result<ServicePointOperationStats>> getOperationStats(
    String id,
  ) async {
    try {
      final response = await _remote.getOperationStats(id);
      return Result.success(response.toEntity());
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _mapDioError(e);
      return Result.failure(Failure(message, statusCode: statusCode));
    } catch (_) {
      return const Result.failure(
        Failure('Erreur lors du chargement des statistiques'),
      );
    }
  }

  @override
  Future<Result<void>> updateServicePointStatus({
    required String id,
    required bool status,
  }) async {
    try {
      if (status) {
        await _remote.unlockServicePoint(id);
      } else {
        await _remote.lockServicePoint(id);
      }
      return const Result.success(null);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _mapDioError(e);
      return Result.failure(Failure(message, statusCode: statusCode));
    } catch (_) {
      return const Result.failure(
        Failure('Erreur lors de la mise a jour du statut'),
      );
    }
  }

  @override
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
  }) async {
    try {
      final result = await _remote.updateServicePoint(
        id,
        nameService: nameService,
        typeAgent: typeAgent,
        userId: userId,
        name: name,
        lastname: lastname,
        email: email,
        phone: phone,
        npi: npi,
      );
      final model = result['service'] as ServicePointModel;
      final generatedPassword = result['generatedPassword'] as String?;
      return Result.success(
        ServicePointCreationResult(
          servicePoint: model.toEntity(),
          generatedPassword: generatedPassword,
        ),
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _mapDioError(e);
      return Result.failure(Failure(message, statusCode: statusCode));
    } catch (_) {
      return const Result.failure(
        Failure('Erreur lors de la mise a jour du point de service'),
      );
    }
  }

  @override
  Future<Result<AgentLookupResult>> findAgent({
    String? phone,
    String? npi,
  }) async {
    try {
      final response = await _remote.findAgent(phone: phone, npi: npi);
      return Result.success(response.toEntity());
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _mapDioError(e);
      return Result.failure(Failure(message, statusCode: statusCode));
    } catch (_) {
      return const Result.failure(
        Failure('Erreur lors de la recherche de l agent'),
      );
    }
  }

  String _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final messageFromApi = data is Map<String, dynamic>
        ? data['message']
        : null;
    if (statusCode == 404) {
      if (messageFromApi is String &&
          messageFromApi.contains(
            'No query results for model [App\\Models\\ServicePoint]',
          )) {
        return 'Cabine inactive, impossible de la modifier';
      }
      return 'Cabine non trouvee';
    }

    return userFriendlyDioMessage(
      error,
      fallback:
          'Impossible de charger les informations des cabines. Réessayez.',
    );
  }
}
