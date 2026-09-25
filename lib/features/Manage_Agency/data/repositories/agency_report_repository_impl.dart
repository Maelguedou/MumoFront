import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/utils/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/user_friendly_error.dart';
import '../../domain/entities/agency_report_operation.dart';
import '../../domain/entities/agency_report_summary.dart';
import '../../domain/repositories/agency_report_repository.dart';
import '../datasources/agency_report_remote_datasource.dart';

class AgencyReportRepositoryImpl implements AgencyReportRepository {
  AgencyReportRepositoryImpl(this._remote);

  final AgencyReportRemoteDataSource _remote;

  @override
  Future<Result<AgencyReportSummary>> getSummary(
    Map<String, dynamic> query,
  ) async {
    try {
      final model = await _remote.getSummary(query);
      return Result.success(model.toEntity());
    } on DioException catch (e) {
      return Result.failure(
        _failure(e, 'Erreur lors du chargement du rapport'),
      );
    } catch (_) {
      return const Result.failure(
        Failure('Erreur lors du chargement du rapport'),
      );
    }
  }

  @override
  Future<Result<AgencyReportOperationsPage>> getOperations(
    Map<String, dynamic> query,
  ) async {
    try {
      final model = await _remote.getOperations(query);
      return Result.success(model.toEntity());
    } on DioException catch (e) {
      return Result.failure(_failure(e, 'Erreur lors du chargement du relevé'));
    } catch (_) {
      return const Result.failure(
        Failure('Erreur lors du chargement du relevé'),
      );
    }
  }

  @override
  Future<Result<Uint8List>> fetchCsvBytes(Map<String, dynamic> query) async {
    try {
      return Result.success(await _remote.fetchCsvBytes(query));
    } on DioException catch (e) {
      await AppLogger.error(
        'Export CSV failed',
        tag: 'REPORT_API',
        error: _technicalDetails(e),
      );
      return Result.failure(_failure(e, 'Erreur lors du téléchargement CSV'));
    } catch (_) {
      return const Result.failure(Failure('Erreur lors du téléchargement CSV'));
    }
  }

  @override
  Future<Result<Uint8List>> fetchPdfBytes(Map<String, dynamic> query) async {
    try {
      return Result.success(await _remote.fetchPdfBytes(query));
    } on DioException catch (e) {
      await AppLogger.error(
        'Export PDF failed',
        tag: 'REPORT_API',
        error: _technicalDetails(e),
      );
      return Result.failure(
        _failure(e, 'Erreur lors du chargement de l’aperçu PDF'),
      );
    } catch (_) {
      return const Result.failure(
        Failure('Erreur lors du chargement de l’aperçu PDF'),
      );
    }
  }

  Failure _failure(DioException e, String fallback) {
    return Failure(
      userFriendlyDioMessage(e, fallback: fallback),
      statusCode: e.response?.statusCode,
    );
  }

  /// Rend la réponse serveur lisible même lorsque Dio l'a reçue en octets.
  /// Les en-têtes, notamment le token d'authentification, ne sont jamais loggés.
  String _technicalDetails(DioException error) {
    final responseData = error.response?.data;
    final readableData = responseData is List<int>
        ? utf8.decode(responseData, allowMalformed: true)
        : responseData?.toString();
    final details = [
      'status=${error.response?.statusCode ?? 'none'}',
      'type=${error.type.name}',
      if (readableData != null && readableData.isNotEmpty)
        'response=${readableData.substring(0, readableData.length > 2000 ? 2000 : readableData.length)}',
    ];

    return details.join(' ');
  }
}
