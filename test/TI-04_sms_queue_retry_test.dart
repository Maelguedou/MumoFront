import 'package:flutter_test/flutter_test.dart';
import 'package:mumo_mobile/features/Operations/data/services/background_retry_service.dart';
import 'package:mumo_mobile/features/Operations/data/services/sms_local_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TI-04 — Reprise automatique d’une confirmation en attente', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      BackgroundRetryService.resetTestingOverrides();
    });

    tearDown(() {
      BackgroundRetryService.resetTestingOverrides();
    });

    test(
      'la confirmation en queue est envoyée puis supprimée après succès API',
      () async {
        final calls = <Map<String, dynamic>>[];

        BackgroundRetryService.confirmFromSmsForTesting =
            ({
              String? amount,
              String? number,
              required int operatorId,
              required String smsDate,
              String? transactionId,
              String? message,
              String? operationType,
            }) async {
              calls.add({
                'amount': amount,
                'number': number,
                'operator_id': operatorId,
                'sms_date': smsDate,
                'transaction_id': transactionId,
                'message': message,
                'operation_type': operationType,
              });
              return true;
            };

        const body =
            'Retrait 2000F a SOFIYATOU MOUMOUNI (2290167325058) 2026-07-12 15:12:15 Solde:141550F ID:12447811658';

        await SmsLocalQueue.add({
          'amount': '2000',
          'number': '2290167325058',
          'operator_id': 3,
          'operation_type': 'retrait',
          'sms_date': '2026-07-12 15:13:57',
          'transaction_id': '12447811658',
          'message': body,
        });

        expect(await SmsLocalQueue.getAll(), hasLength(1));

        await BackgroundRetryService.retryPending(force: true);

        expect(calls, hasLength(1));
        expect(calls.single['amount'], '2000');
        expect(calls.single['number'], '2290167325058');
        expect(calls.single['operator_id'], 3);
        expect(calls.single['operation_type'], 'retrait');
        expect(calls.single['transaction_id'], '12447811658');
        expect(calls.single['sms_date'], '2026-07-12 15:13:57');
        expect(calls.single['message'], body);
        expect(await SmsLocalQueue.getAll(), isEmpty);

        await BackgroundRetryService.retryPending(force: true);

        expect(calls, hasLength(1));
        expect(await SmsLocalQueue.getAll(), isEmpty);
      },
    );
  });
}
