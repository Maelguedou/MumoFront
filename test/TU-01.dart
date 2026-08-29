import 'package:flutter_test/flutter_test.dart';
import 'package:mumo_mobile/features/Operations/data/services/sms_parser.dart';

void main(){
  group('TU-01 - Analyse SMS depot/retrait avec identifiant',(){
      final cases = [
      {
        'name': 'MTN depot avec ID',
        'sender': 'MTN MoMo',
        'body':
            'Depot 1500F a SOSSOU HERVE (2290166434746) 2026-07-05 15:32:13. Ref:1 Solde:73425F ID:12403143013',
        'type': 'depot',
        'amount': '1500',
        'number': '2290166434746',
        'operator': 'MTN',
        'txId': '12403143013',
      },
      {
        'name': 'MTN retrait avec ID',
        'sender': 'MTN MoMo',
        'body':
            'Retrait 2000F a BYLL CATARIA Marie (2290167325058) 2026-07-12 15:12:15 Solde:141550F ID:12447811658',
        'type': 'retrait',
        'amount': '2000',
        'number': '2290167325058',
        'operator': 'MTN',
        'txId': '12447811658',
      },
      {
        'name':'Moov depot avec ID',
        'sender':'Moov Money',
        'body':'Vous avez envoyé 10 000 FCFA a l\'abonne JOHN HARRY 2290168369874.Votre nouveau solde Moov Money est de 20 000 FCFA. Ref:123456478541.Apelle gratuitement',
        'type':'depot',
        'amount':'10000',
        'number':'2290168369874',
        'operator':'Moov',
        'txId':'123456478541',
      },
      {
        'name':'Moov retrait avec ID',
        'sender':'Moov Money',
        'body':'2 500 FCFA recu de SANYA CALEB 2290199120132 le 22/06/2026 09:30:04. TAX AIB:2. Commission: 0 FCFA HT. Nouveau solde 24 654 FCFA. Ref : 01321458896541.',
        'type':'retrait',
        'amount':'2500',
        'number':'2290199120132',
        'operator':'Moov',
        'txId':'01321458896541',
      },
      {
        'name':'Celtiis depot avec ID',
        'sender':'CeltiisCash',
        'body':'Vous avez envoyé 2.500,00 F a 2290141020102 - ALICE DOE le 6/4/26 at 10:39 PM. REF:DD848NS152',
        'type':'depot',
        'amount':'2500',
        'number':'2290141020102',
        'operator':'Celtiis',
        'txId':'DD848NS152',
      },
      {
        'name':'Celtiis retrait avec ID',
        'sender':'CeltiisCash',
        'body':'Vous avez retire un montant de 15.000,00F chez AHMED SOLO 2290141020102 ce 9/4/26 a 1:28 PM.Commission perçue: 76,50F.REF:DD848NS152.Balance: 50.026,00F.',
        'type':'retrait',
        'amount':'15000',
        'number':'2290141020102',
        'operator':'Celtiis',
        'txId':'DD848NS152',
      }

    ];
    for (final item in cases) {
      test(item['name']!, () {
        final result = SmsParser.parse(
          item['sender']!,
          item['body']!,
        );

        expect(result, isNotNull);
        expect(result!.operationType, item['type']);
        expect(result.amount, item['amount']);
        expect(result.number, item['number']);
        expect(result.operator, item['operator']);
        expect(result.transactionId, item['txId']);

        final replay = SmsParser.parse(
          item['sender']!,
          item['body']!,
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