import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumo_mobile/core/api/api_client.dart';
import 'package:mumo_mobile/features/Operations/data/datasources/operation_remote_datasource.dart';
import 'package:mumo_mobile/features/Operations/data/models/operator_model.dart';
import 'package:mumo_mobile/features/Operations/data/services/sms/incoming_sms_message.dart';
import 'package:mumo_mobile/features/Operations/data/services/sms/sms_listener.dart';
import 'package:mumo_mobile/features/Operations/data/services/sms_local_queue.dart';
import 'package:mumo_mobile/features/Operations/di/operation_providers.dart';
import 'package:mumo_mobile/features/Operations/di/sms_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TI-03 — Panne de l’API pendant une confirmation SMS', () {
    setUp(() {
      //On notifie à flutter que SharedPreferences ne doit pas utiliser le vrai stockage du téléphone,il utilisera un faux stockage vide
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'un SMS valide est conservé une seule fois dans la queue quand l’API échoue',
      () async {
        final dataSource = _FailingConfirmationDataSource();
        final container = ProviderContainer(
          overrides: [
            operationRemoteDataSourceProvider.overrideWithValue(dataSource),
            smsListenerProvider.overrideWithValue(_NoopSmsListener()),
          ],
        );
        addTearDown(container.dispose);

        const body =
            'Retrait 2000F a SOFIYATOU MOUMOUNI (2290167325058) 2026-07-12 15:12:15 Solde:141550F ID:12447811658';
        final message = IncomingSmsMessage(
          sender: 'MTN MoMo',
          body: body,
          receivedAt: DateTime(2026, 7, 12, 15, 13, 57),
        );

        final service = container.read(smsServiceProvider);

        await service.processIncomingMessageForTest(message);
        await service.processIncomingMessageForTest(message);

        expect(dataSource.confirmCalls, 2);

        final pending = await SmsLocalQueue.getAll();
        expect(pending, hasLength(1));

        final item = pending.single;
        expect(item['amount'], '2000');
        expect(item['number'], '2290167325058');
        expect(item['operator_id'], 3);
        expect(item['operation_type'], 'retrait');
        expect(item['transaction_id'], '12447811658');
        expect(item['sms_date'], '2026-07-12 15:13:57');
        expect(item['message'], body);
        expect(item['dedupe_key'], 'tx:3:12447811658');

        final pendingAfterRestartSimulation = await SmsLocalQueue.getAll();
        expect(pendingAfterRestartSimulation, hasLength(1));
        expect(
          pendingAfterRestartSimulation.single['transaction_id'],
          '12447811658',
        );
      },
    );
  });
}

class _FailingConfirmationDataSource extends OperationRemoteDataSource {
  _FailingConfirmationDataSource() : super(ApiClient(Dio()));

  int confirmCalls = 0;

  @override
  Future<List<OperatorModel>> getOperators() async {
    return [OperatorModel(id: 3, name: 'MTN', ussds: const [])];
  }

  @override
  Future<void> confirmOperationFromSms({
    String? amount,
    String? number,
    required int operatorId,
    String? transactionId,
    required String smsDate,
    String? message,
    String? operationType,
  }) async {
    confirmCalls++;
    final requestOptions = RequestOptions(
      path: '/operations/confirm-from-sms',
      data: {
        'amount': amount,
        'number': number,
        'operator_id': operatorId,
        'transaction_id': transactionId,
        'operation_type': operationType,
        'sms_date': smsDate,
        'message': message,
      },
    );

    throw DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 503,
        data: {'message': 'Service temporarily unavailable'},
      ),
    );
  }
}

class _NoopSmsListener implements SmsListener {
  @override
  Future<bool> requestPermissions() async => true;

  @override
  void listenIncomingSms({
    required IncomingSmsCallback onNewMessage,
    bool listenInBackground = true,
  }) {}
}
