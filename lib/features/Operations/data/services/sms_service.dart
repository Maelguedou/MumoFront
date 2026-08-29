import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:another_telephony/telephony.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import '../../../../../core/logging/app_logger.dart';
import '../../di/operation_providers.dart';
import 'sms_parser.dart';
import 'sms_confirmation_service.dart';
import 'sms_local_queue.dart';
import 'background_retry_service.dart';
import 'operator_matcher.dart';
import 'sms/incoming_sms_message.dart';
import 'sms/sms_listener.dart';

/// Handler pour les messages reçus en arrière-plan.
/// DOIT être une fonction de haut niveau (top-level).
@pragma('vm:entry-point')
void backGroundMessageHandler(SmsMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  try {
    final body = message.body;
    final sender = message.address ?? '';
    if (body == null) {
      await AppLogger.warning(
        'BG SMS ignored because body is null',
        tag: 'SMS',
      );
      return;
    }

    dev.log('[BG SMS] Reçu de $sender');
    await AppLogger.info('BG SMS received sender=$sender', tag: 'SMS');

    final parsed = SmsParser.parse(sender, body);
    if (parsed == null) {
      dev.log('[BG SMS] Aucun match');
      await AppLogger.info(
        'BG SMS no parser match sender=$sender body=${_smsPreview(body)}',
        tag: 'SMS',
      );
      return;
    }

    dev.log('[BG SMS] Match : $parsed');
    await AppLogger.info('BG SMS parsed=$parsed', tag: 'SMS');

    // Résoudre l'operatorId
    final operatorId = await SmsConfirmationService.resolveOperatorId(
      parsed.operator,
    );

    final smsDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(
      DateTime.fromMillisecondsSinceEpoch(
        message.date ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );

    if (operatorId == null) {
      // Stocker avec le nom pour résoudre plus tard
      await SmsLocalQueue.add({
        'amount': parsed.amount,
        'number': parsed.number,
        'operator_name': parsed.operator, // sera résolu au retry
        'operation_type': parsed.operationType,
        'sms_date': smsDate,
        'transaction_id': parsed.transactionId,
        'message': body,
      });
      await AppLogger.warning(
        'BG SMS queued because operator could not be resolved operator=${parsed.operator}',
        tag: 'SMS',
      );
      return;
    }

    final success = await SmsConfirmationService.confirmFromSms(
      amount: parsed.amount,
      number: parsed.number,
      operatorId: operatorId,
      smsDate: smsDate,
      transactionId: parsed.transactionId,
      message: body,
      operationType: parsed.operationType,
    );

    if (success) {
      dev.log('[BG SMS] Confirmation réussie');
      await AppLogger.info(
        'BG SMS confirm-from-sms success tx=${parsed.transactionId}',
        tag: 'SMS',
      );
    } else {
      dev.log('[BG SMS]  Échec réseau → queue locale');
      await SmsLocalQueue.add({
        'amount': parsed.amount,
        'number': parsed.number,
        'operator_id': operatorId, // déjà résolu
        'operation_type': parsed.operationType,
        'sms_date': smsDate,
        'transaction_id': parsed.transactionId,
        'message': body,
      });
      await AppLogger.warning(
        'BG SMS confirm failed and queued tx=${parsed.transactionId}',
        tag: 'SMS',
      );
    }
  } catch (e, stackTrace) {
    await AppLogger.error(
      'BG SMS handler crashed',
      tag: 'SMS',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

String _smsPreview(String value) {
  const maxLength = 180;
  final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= maxLength) return compact;
  return '${compact.substring(0, maxLength)}...';
}

class SmsService {
  final Ref _ref;
  final SmsListener _smsListener;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isRetrying = false;

  SmsService(this._ref, this._smsListener);

  Future<void> init() async {
    await AppLogger.info('SMS service init start', tag: 'SMS');

    // Retenter les confirmations échouées au démarrage
    await _retryPendingQueue();
    _startConnectivityRetry();

    try {
      final permissionsGranted = await _smsListener.requestPermissions();
      await AppLogger.info(
        'SMS permissions granted=$permissionsGranted',
        tag: 'SMS',
      );

      if (permissionsGranted != true) {
        await AppLogger.warning(
          'SMS listener not registered because permissions are missing',
          tag: 'SMS',
        );
        return;
      }

      _smsListener.listenIncomingSms(
        onNewMessage: (IncomingSmsMessage message) {
          dev.log("SMS reçu au premier plan de: ${message.sender}");
          AppLogger.info(
            'FG SMS received sender=${message.sender}',
            tag: 'SMS',
          );
          _processMessage(message);
        },
        listenInBackground: true,
      );

      await AppLogger.info('SMS listener registered', tag: 'SMS');
    } catch (e, stackTrace) {
      await AppLogger.error(
        'SMS service init failed',
        tag: 'SMS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  void _startConnectivityRetry() {
    if (_connectivitySubscription != null) return;

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      if (_hasNetwork(results)) {
        dev.log('[Retry] Connectivité détectée → retry queue locale');
        _retryPendingQueue();
      }
    });
  }

  Future<void> _retryPendingQueue() async {
    if (_isRetrying) return;

    _isRetrying = true;
    try {
      await BackgroundRetryService.retryPending();
    } finally {
      _isRetrying = false;
    }
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  @visibleForTesting
  Future<void> processIncomingMessageForTest(IncomingSmsMessage message) {
    return _processMessage(message);
  }

  Future<void> _processMessage(IncomingSmsMessage message) async {
    final body = message.body;
    if (body == null) {
      await AppLogger.warning(
        'FG SMS ignored because body is null',
        tag: 'SMS',
      );
      return;
    }

    final parsedData = SmsParser.parse(message.sender, body);
    if (parsedData != null) {
      dev.log("MATCH TROUVÉ ! $parsedData");
      await AppLogger.info('FG SMS parsed=$parsedData', tag: 'SMS');

      final smsDate = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(message.receivedAt);

      final queuePayload = <String, dynamic>{
        'amount': parsedData.amount,
        'number': parsedData.number,
        'operator_name': parsedData.operator,
        'operation_type': parsedData.operationType,
        'sms_date': smsDate,
        'transaction_id': parsedData.transactionId,
        'message': body,
      };

      try {
        final dataSource = _ref.read(operationRemoteDataSourceProvider);
        final operators = await dataSource.getOperators();

        var operatorId = 0;
        for (final operator in operators) {
          if (OperatorMatcher.matches(operator.name, parsedData.operator)) {
            operatorId = operator.id;
            break;
          }
        }

        if (operatorId == 0) {
          throw Exception(
            "Opérateur ${parsedData.operator} non trouvé aux archives API",
          );
        }

        queuePayload['operator_id'] = operatorId;
        queuePayload.remove('operator_name');

        await AppLogger.info(
          'FG SMS confirm payload amount=${parsedData.amount} number=${parsedData.number} '
          'operatorId=$operatorId type=${parsedData.operationType} '
          'tx=${parsedData.transactionId} smsDate=$smsDate '
          'message=${_preview(body)}',
          tag: 'SMS_API',
        );

        await dataSource.confirmOperationFromSms(
          amount: parsedData.amount,
          number: parsedData.number,
          operatorId: operatorId,
          transactionId: parsedData.transactionId,
          smsDate: smsDate,
          message: body,
          operationType: parsedData.operationType,
        );

        dev.log("Opération confirmée avec succès côté API !");
        await AppLogger.info(
          'FG SMS confirm-from-sms success tx=${parsedData.transactionId}',
          tag: 'SMS',
        );
      } catch (e) {
        dev.log("Erreur lors de la confirmation SMS: $e");
        await SmsLocalQueue.add(queuePayload);
        await _logConfirmFailure(e, queuePayload);
        await AppLogger.error(
          'FG SMS confirm failed and queued',
          tag: 'SMS',
          error: e,
        );
      }
    } else {
      await AppLogger.info(
        'FG SMS no parser match sender=${message.sender} body=${_preview(body)}',
        tag: 'SMS',
      );
    }
  }

  String _preview(String value) {
    const maxLength = 180;
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= maxLength) return compact;
    return '${compact.substring(0, maxLength)}...';
  }

  Future<void> _logConfirmFailure(
    Object error,
    Map<String, dynamic> queuedPayload,
  ) async {
    if (error is DioException) {
      await AppLogger.error(
        'FG SMS confirm failed details '
        'statusCode=${error.response?.statusCode} '
        'responseData=${_logValue(error.response?.data)} '
        'requestData=${_logValue(error.requestOptions.data)} '
        'queuedPayload=${_logValue(_safeQueuedPayload(queuedPayload))}',
        tag: 'SMS_API',
        error: error.message,
      );
      return;
    }

    await AppLogger.error(
      'FG SMS confirm failed details queuedPayload=${_logValue(_safeQueuedPayload(queuedPayload))}',
      tag: 'SMS_API',
      error: error,
    );
  }

  Map<String, dynamic> _safeQueuedPayload(Map<String, dynamic> payload) {
    return {
      'amount': payload['amount'],
      'number': payload['number'],
      'operator_id': payload['operator_id'],
      'operator_name': payload['operator_name'],
      'operation_type': payload['operation_type'],
      'sms_date': payload['sms_date'],
      'transaction_id': payload['transaction_id'],
      'message': payload['message'] == null
          ? null
          : _preview(payload['message'].toString()),
    };
  }

  String _logValue(Object? value) {
    final text = value?.toString() ?? 'null';
    const maxLength = 600;
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
