
import 'package:dio/dio.dart';

import '../../../../core/utils/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/agency_insight.dart';
import '../../domain/repositories/agency_insight_repository.dart';
import '../datasources/agency_insight_remote_datasource.dart';

class AgencyInsightRepositoryImpl implements AgencyInsightRepository{
  AgencyInsightRepositoryImpl(this._remoteDataSource);
  final AgencyInsightRemoteDataSource _remoteDataSource;

  @override
  Future<Result<AgencyInsight>> generateInsight({
    required String startDate,
    required String endDate,
    required String granularity,
  }) async {
    try {
      final model = await _remoteDataSource.generateInsight(
        startDate: startDate,
        endDate: endDate,
        granularity: granularity,
      );
      return Result.success(model.toEntity());
    } on DioException catch (e) {
      return Result.failure(_mapDioErrorToFailure(e));
    } catch (e) {
      return const Result.failure(
        Failure('Une erreur inattendue est survenue lors de la génération.'),
      );
    }
  }

  @override
  Future<Result<AgencyInsight>> getInsightById(int id) async {
    try {
      final model = await _remoteDataSource.getInsightById(id);
      return Result.success(model.toEntity());
    } on DioException catch (e) {
      return Result.failure(_mapDioErrorToFailure(e));
    } catch (e) {
      return const Result.failure(
        Failure('Impossible de récupérer le détail de l\'insight.'),
      );
    }
  }

  @override
  Future<Result<List<AgencyInsight>>> getInsightHistory({
    String? granularity,
    int limit = 30,
  }) async {
    try {
      final models = await _remoteDataSource.getInsightHistory(
        granularity: granularity,
        limit: limit,
      );
      final entities = models.map((model) => model.toEntity()).toList();
      return Result.success(entities);
    } on DioException catch (e) {
      return Result.failure(_mapDioErrorToFailure(e));
    } catch (e) {
      return const Result.failure(
        Failure('Impossible d\'afficher l\'historique des insights.'),
      );
    }
  }

  /// Traitement centralisé des erreurs HTTP retournées par Laravel
  Failure _mapDioErrorToFailure(DioException e) {
    final statusCode = e.response?.statusCode;
    final serverMessage = e.response?.data?['message'] as String?;

    if (serverMessage != null && serverMessage.isNotEmpty) {
      return Failure(serverMessage, statusCode: statusCode);
    }

    switch (statusCode) {
      case 422:
        return Failure(
          'Les paramètres de la période sont invalides.',
          statusCode: 422,
        );
      case 404:
        return Failure(
          'Aucune agence n’est associée à ce compte ou élément introuvable.',
          statusCode: 404,
        );
      case 503:
        return Failure(
          'Les insights sont temporairement indisponibles. Veuillez réessayer plus tard.',
          statusCode: 503,
        );
      default:
        return Failure(
          'Erreur réseau (${statusCode ?? 'inconnue'}). Veuillez vérifier votre connexion.',
          statusCode: statusCode,
        );
    }
  }
}