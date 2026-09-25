import 'dart:developer' as dev;
import 'package:meta/meta.dart';

import '../../../../../core/logging/app_logger.dart';
import 'sms_confirmation_service.dart';
import 'sms_local_queue.dart';

class BackgroundRetryService {
  static const int maxRetryAttempts = 10;

  @visibleForTesting
  static Future<int?> Function(String operatorName)?
  resolveOperatorIdForTesting;

  @visibleForTesting
  static Future<bool> Function({
    String? amount,
    String? number,
    required int operatorId,
    required String smsDate,
    String? transactionId,
    String? message,
    String? operationType,
  })?
  confirmFromSmsForTesting;

  @visibleForTesting
  static void resetTestingOverrides() {
    resolveOperatorIdForTesting = null;
    confirmFromSmsForTesting = null;
  }

  static Future<void> retryPending({bool force = false}) async {
    final pending = await SmsLocalQueue.getAll();
    if (pending.isEmpty) {
      dev.log('[Retry] Aucune confirmation en attente');
      return;
    }

    dev.log('[Retry] ${pending.length} confirmation(s) à retenter');
    await AppLogger.info(
      'retry start count=${pending.length} force=$force',
      tag: 'RETRY',
    );

    for (int i = pending.length - 1; i >= 0; i--) {
      final item = pending[i];
      final currentattempts = _readAttempts(item['attempts']);

      if (currentattempts >= maxRetryAttempts) {
        await _removeAfterMaxAttempts(item, i);
        continue;
      }
      try {
        if (!force && !_shouldRetryNow(item)) {
          dev.log('[Retry] Item $i ignoré temporairement (backoff actif)');
          await AppLogger.info(
            'retry skipped index=$i reason=backoff',
            tag: 'RETRY',
          );
          continue;
        }

        final attemptNumber = currentattempts + 1;

        item['attempts'] = attemptNumber;
        item['last_attempt_at'] = DateTime.now().toIso8601String();

        await SmsLocalQueue.updateAt(i, item);

        // Résoudre l'operatorId si on a stocké le nom
        int? operatorId = item['operator_id'] as int?;
        if (operatorId == null && item['operator_name'] != null) {
          operatorId =
              await (resolveOperatorIdForTesting ??
                  SmsConfirmationService.resolveOperatorId)(
                item['operator_name'] as String,
              );
        }
        if (operatorId == null) {
          dev.log('[Retry] Impossible de résoudre l\'opérateur pour item $i');
          item['last_error'] = 'operator_not_resolved';
          await _keepOrRemoveAfterFailure(
            item: item,
            index: i,
            reason: 'operator_not_resolved',
          );

          continue;
        }

        final success =
            await (confirmFromSmsForTesting ??
                SmsConfirmationService.confirmFromSms)(
              amount: item['amount'] as String?,
              number: item['number'] as String?,
              operatorId: operatorId,
              smsDate: item['sms_date'] as String,
              transactionId: item['transaction_id'] as String?,
              message: item['message'] as String?,
              operationType: item['operation_type'] as String?,
            );

        if (success) {
          await SmsLocalQueue.removeAt(i);
          dev.log('[Retry]  Item $i confirmé et retiré');
          await AppLogger.info(
            'retry success index=$i tx=${item['transaction_id']}',
            tag: 'RETRY',
          );
        } else {
          item['last_error'] = 'confirmation_failed';
          await _keepOrRemoveAfterFailure(
            item: item,
            index: i,
            reason: 'confirmation_failed',
          );
        }
      } catch (e) {
        item['last_error'] = e.toString();

        await _keepOrRemoveAfterFailure(
          item: item,
          index: i,
          reason: e.toString(),
        );

        dev.log('[Retry] Erreur item $i : $e');
        await AppLogger.error(
          'retry exception index=$i',
          tag: 'RETRY',
          error: e,
        );
      }
    }
  }

  static int _readAttempts(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _shouldRetryNow(Map<String, dynamic> item) {
    final attempts = _readAttempts(item['attempts']);
    if (attempts == 0) return true;

    final lastAttempt = DateTime.tryParse(
      (item['last_attempt_at'] ?? '').toString(),
    );
    if (lastAttempt == null) return true;

    return DateTime.now().difference(lastAttempt) >= _delayFor(attempts);
  }

  static Duration _delayFor(int attempts) {
    if (attempts <= 1) return const Duration(minutes: 1);
    if (attempts == 2) return const Duration(minutes: 5);
    if (attempts == 3) return const Duration(minutes: 15);
    return const Duration(hours: 1);
  }

  static Future<void> _keepOrRemoveAfterFailure({
    required Map<String, dynamic> item,
    required int index,
    required String reason,
  }) async {
    final attempts = _readAttempts(item['attempts']);

    if (attempts >= maxRetryAttempts) {
      await _removeAfterMaxAttempts(item, index, reason: reason);
      return;
    }

    await SmsLocalQueue.updateAt(index, item);

    dev.log(
      '[Retry] Échec conservé '
      'attempt=$attempts/$maxRetryAttempts '
      'reason=$reason',
    );

    await AppLogger.warning(
      'retry failed and kept index=$index '
      'attempts=$attempts/$maxRetryAttempts '
      'reason=$reason',
      tag: 'RETRY',
    );
  }

  static Future<void> _removeAfterMaxAttempts(
    Map<String, dynamic> item,
    int index, {
    String reason = 'max_attempts_reached',
  }) async {
    final attempts = _readAttempts(item['attempts']);

    await SmsLocalQueue.removeAt(index);

    dev.log(
      '[Retry] Élément supprimé après '
      '$attempts/$maxRetryAttempts tentatives',
    );

    await AppLogger.warning(
      'queue item removed after max attempts '
      'index=$index '
      'tx=${item['transaction_id']} '
      'attempts=$attempts '
      'reason=$reason',
      tag: 'RETRY',
    );
  }
}
