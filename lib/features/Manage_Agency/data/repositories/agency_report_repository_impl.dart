import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/utils/failure.dart';
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
}
