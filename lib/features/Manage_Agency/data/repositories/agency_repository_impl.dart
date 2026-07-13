import 'package:dio/dio.dart';

import '../../../../core/utils/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/user_friendly_error.dart';
import '../../domain/entities/agency.dart';
import '../../domain/repositories/agency_repository.dart';
import '../datasources/agency_remote_datasource.dart';
import '../models/agency_request.dart';

class AgencyRepositoryImpl implements AgencyRepository {
  AgencyRepositoryImpl(this._remote);

  final AgencyRemoteDataSource _remote;

  @override
  Future<Result<Agency>> createAgency({
    required String name,
    required String location,
  }) async {
    try {
      final response = await _remote.createAgency(
        AgencyRequest(name: name, location: location),
      );
      return Result.success(response.agency.toEntity());
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _mapDioError(e);
      return Result.failure(Failure(message, statusCode: statusCode));
    } catch (_) {
      return const Result.failure(
        Failure('Erreur inconnue lors de la creation de l\'agence'),
      );
    }
  }

  @override
  Future<Result<Agency>> updateAgency({
    required String id,
    required String name,
    required String location,
  }) async {
    try {
      final response = await _remote.updateAgency(
        id,
        AgencyRequest(name: name, location: location),
      );
      return Result.success(response.agency.toEntity());
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _mapDioError(e);
      return Result.failure(Failure(message, statusCode: statusCode));
    } catch (_) {
      return const Result.failure(
        Failure('Erreur inconnue lors de la mise a jour de l\'agence'),
      );
    }
  }

  @override
  Future<Result<Agency>> hasAgency() async {
    try {
      final response = await _remote.hasAgency();
      return Result.success(response.agency.toEntity());
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _mapDioError(e);
      return Result.failure(Failure(message, statusCode: statusCode));
    } catch (_) {
      return const Result.failure(
        Failure('Erreur inconnue lors de la verification de l\'agence'),
      );
    }
  }

  String _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return 'Votre session a expiré. Reconnectez-vous pour continuer.';
    }
    if (statusCode == 404) {
      return 'Aucune agence pour cet utilisateur';
    }
    if (statusCode == 403) {
      return 'Vous avez deja une agence';
    }
    return userFriendlyDioMessage(
      error,
      fallback:
          'Impossible de charger les informations de l’agence. Réessayez.',
    );
  }
}
