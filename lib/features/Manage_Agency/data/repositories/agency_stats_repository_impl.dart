import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/user_friendly_error.dart';
import '../../domain/entities/agency_stats.dart';
import '../../domain/repositories/agency_stats_repository.dart';
import '../datasources/agency_stats_remote_datasource.dart';

class AgencyStatsRepositoryImpl implements AgencyStatsRepository {
  AgencyStatsRepositoryImpl(this._remote);

  final AgencyStatsRemoteDataSource _remote;

  @override
  Future<Result<AgencyStatsDashboard>> getDashboard(
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('[STATS] Loading dashboard with filters=$data');
      final results = await Future.wait([
        _guardedCall('overview', () => _remote.getOverview(data)),
        _guardedCall('evolution', () => _remote.getEvolution(data)),
        _guardedCall('breakdown', () => _remote.getBreakdown(data)),
        _guardedCall('service-points', () => _remote.getServicePoints(data)),
        _guardedCall('activity-hours', () => _remote.getActivityHours(data)),
        _guardedCall('insights', () => _remote.getInsights(data)),
      ]);

      final overview = results[0] as AgencyStatsOverview;
      final evolution = results[1] as dynamic;
      final breakdown = results[2] as dynamic;
      final servicePoints = results[3] as dynamic;
      final activityHours = results[4] as dynamic;
      final insights = results[5] as dynamic;

      debugPrint('[STATS] Dashboard loaded successfully');
      return Result.success(
        AgencyStatsDashboard(
          overview: overview,
          evolution: evolution.items,
          byType: breakdown.byType,
          byOperator: breakdown.byOperator,
          servicePoints: servicePoints.items,
          activityHours: activityHours.items,
          insights: insights.items,
        ),
      );
    } on DioException catch (e) {
      _logDioError(e, 'dashboard');
      return Result.failure(_failure(e));
    } catch (e, stackTrace) {
      debugPrint('[STATS] Unexpected dashboard error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return const Result.failure(
        Failure('Impossible de charger les statistiques pour le moment.'),
      );
    }
  }

  Future<T> _guardedCall<T>(String name, Future<T> Function() call) async {
    try {
      debugPrint('[STATS] -> $name');
      final result = await call();
      debugPrint('[STATS] <- $name OK');
      return result;
    } on DioException catch (e) {
      _logDioError(e, name);
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('[STATS] <- $name unexpected error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  void _logDioError(DioException e, String endpointName) {
    debugPrint('[STATS] <- $endpointName DioException');
    debugPrint('[STATS] uri=${e.requestOptions.uri}');
    debugPrint('[STATS] method=${e.requestOptions.method}');
    debugPrint('[STATS] requestData=${e.requestOptions.data}');
    debugPrint('[STATS] statusCode=${e.response?.statusCode}');
    debugPrint('[STATS] responseData=${e.response?.data}');
    debugPrint('[STATS] message=${e.message}');
  }

  Failure _failure(DioException e) {
    return Failure(
      userFriendlyDioMessage(
        e,
        fallback:
            'Impossible de charger les statistiques pour le moment. Réessayez.',
      ),
      statusCode: e.response?.statusCode,
    );
  }
}
