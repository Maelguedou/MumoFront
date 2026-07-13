import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/api/api_config.dart';
import '../../../../core/logging/app_logger.dart';
import 'operator_matcher.dart';
import 'dart:developer' as dev;

class SmsConfirmationService {
  static const _storage = FlutterSecureStorage();

  /// Crée un Dio autonome avec le token stocké
  static Future<Dio?> _buildDio() async {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      dev.log('[SmsConfirmationService] ⚠️ Token introuvable');
      await AppLogger.warning('token missing', tag: 'SMS_API');
      return null;
    }
    return Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  /// Résout le nom de l'opérateur en ID via l'API
  static Future<int?> resolveOperatorId(String operatorName) async {
    final dio = await _buildDio();
    if (dio == null) return null;
    try {
      final response = await dio.get('/operators');
      dynamic data = response.data;
      if (data is Map && data.containsKey('data')) data = data['data'];
      if (data is List) {
        return OperatorMatcher.findOperatorIdFromMaps(data, operatorName);
      }
    } catch (e) {
      dev.log('[SmsConfirmationService] Erreur resolveOperatorId: $e');
      await AppLogger.error(
        'resolveOperatorId failed operator=$operatorName',
        tag: 'SMS_API',
        error: e,
      );
    }
    return null;
  }

  /// Envoie la confirmation SMS à l'API
  static Future<bool> confirmFromSms({
    String? amount,
    String? number,
    required int operatorId,
    required String smsDate,
    String? transactionId,
    String? message,
    String? operationType,
  }) async {
    final dio = await _buildDio();
    if (dio == null) return false;
    final payload = {
      if (amount != null) 'amount': amount,
      if (number != null) 'number': number,
      'operator_id': operatorId,
      'sms_date': smsDate,
      if (operationType != null) 'operation_type': operationType,
      if (transactionId != null) 'transaction_id': transactionId,
      if (message != null) 'message': message,
    };

    try {
      await AppLogger.info(
        'confirmFromSms payload amount=$amount number=$number operatorId=$operatorId '
        'type=$operationType tx=$transactionId smsDate=$smsDate '
        'message=${_preview(message)}',
        tag: 'SMS_API',
      );

      await dio.post('/operations/confirm-from-sms', data: payload);
      await AppLogger.info(
        'confirmFromSms success amount=$amount number=$number operatorId=$operatorId tx=$transactionId',
        tag: 'SMS_API',
      );
      return true;
    } catch (e) {
      dev.log('[SmsConfirmationService] Erreur confirmFromSms: $e');
      if (e is DioException) {
        await AppLogger.error(
          'confirmFromSms failed details '
          'statusCode=${e.response?.statusCode} '
          'responseData=${_logValue(e.response?.data)} '
          'requestData=${_logValue(e.requestOptions.data)}',
          tag: 'SMS_API',
          error: e.message,
        );
      }
      await AppLogger.error(
        'confirmFromSms failed amount=$amount number=$number operatorId=$operatorId tx=$transactionId',
        tag: 'SMS_API',
        error: e,
      );
      return false;
    }
  }

  static String _preview(String? value) {
    if (value == null) return 'null';
    const maxLength = 180;
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= maxLength) return compact;
    return '${compact.substring(0, maxLength)}...';
  }

  static String _logValue(Object? value) {
    final text = value?.toString() ?? 'null';
    const maxLength = 600;
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
