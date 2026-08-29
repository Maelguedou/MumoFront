import 'package:flutter_test/flutter_test.dart';
import 'package:mumo_mobile/features/Operations/data/services/sms_parser.dart';

void main(){
  group("TU-02 — Analyse d'un SMS de transfert avec ou sans identifiant",(){
      final cases = [
      {
        'name': 'Transfert MTN 1',
        'sender': 'MTN',
        'body':
            'Paiement 100F a SELL 2026-07-05 15:12:54 Frais:0F Solde:75425F ID:12403038428 Ref:-',
        'amount': '100',
        'number': null,
        'operator': 'MTN',
        'txId': '12403038428',
      },
      {
        'name': 'Transfert MTN 2',
        'sender': 'MTN',
        'body':
            "Vos avez vendu un forfait 100F (606/244H) au 2290143410125. Desormais,faites vos operations via l'application MTN MoMo.",
        'amount': '100',
        'number': '2290143410125',
        'operator': 'MTN',
        'txId': null,
      },
      {
        'name': 'Transfert MTN 3',
        'sender': 'MTN',
        'body':
            "Vos avez vendu  un forfait maxi 150F (357/48H) au 2290143410125. Desormais,faites vos operations via l'application MTN MoMo.",
        'amount': '150',
        'number': '2290143410125',
        'operator': 'MTN',
        'txId': null,
      },
      {
        'name': "Transfert Moov 1",
        'sender': 'Moov',
        'body':
            'Cher partenaire vous avez active au 2290168369874 Moov Pass Appel 100F (605 F) pour Appel Valable au 10/04/2026 19:14:52. Vous beneficiez de 4F Comme bonus sur votre compte forfait Moov money.',
        'amount': '100',
        'number': '2290168369874',
        'operator': 'Moov',
        'txId': null,
      },
      {
        'name': "Transfert Moov 2",
        'sender': 'Moov',
        'body':
            "Vous avez active au 0163451201 le forfait internet de 500F (illimite 11.6GoPlus) valide jusqu'au  09-05-2026 19:05:01.Votre commission est de 200F. Ref:03124587965412.",
        'amount': '500',
        'number': '0163451201',
        'operator': 'Moov',
        'txId': '03124587965412',
      },
      {
        'name': "Transfert Celtiis 1",
        'sender': 'Celtiis',
        'body':
            "Votre vente de Airtime 2290143121412 du 09/04/26 13:02 a ete faite avec succes. Montant:500.00F. Solde:32.875,00F. Ref ID: DD9888WFOPT",
        'amount': '500',
        'number': '2290143121412',
        'operator': 'Celtiis',
        'txId': 'DD9888WFOPT',
      },
      {
        'name': "Transfert Celtiis 2",
        'sender': 'Celtiis',
        'body':
            "Votre vente de Airtime 2290143121412 du 09/04/26 13:02 a ete faite avec succes. Montant:100.00F. Solde:32.875,00F. Ref ID: DD9888WFOPT",
        'amount': '100',
        'number': '2290143121412',
        'operator': 'Celtiis',
        'txId': 'DD9888WFOPT',
      },
      {
        'name': "Transfert Celtiis 3",
        'sender': 'Celtiis',
        'body':
            "Votre vente de forfait 2290143121412 du 09/04/26 13:02 a ete faite avec succes. Montant:100.00F. Solde:32.875,00F. Ref ID: DD9888WFOPT",
        'amount': '100',
        'number': '2290143121412',
        'operator': 'Celtiis',
        'txId': 'DD9888WFOPT',
      },
    ];
    for (final item in cases) {
      test(item['name']!, () {
        final result = SmsParser.parse(
          item['sender'] as String,
          item['body'] as String,
        );

        expect(result, isNotNull);
        expect(result!.operationType, 'transfert');
        expect(result.amount, item['amount']);
        expect(result.number, item['number']);
        expect(result.operator, item['operator']);
        expect(result.transactionId, item['txId']);

        final replay = SmsParser.parse(
          item['sender'] as String,
          item['body'] as String,
        );

        expect(replay, isNotNull);
        expect(replay!.operationType, result.operationType);
        expect(replay.amount, result.amount);
        expect(replay.number, result.number);
        expect(replay.operator, result.operator);
        expect(replay.transactionId, result.transactionId);
      });
    }

  });
}
