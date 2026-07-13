import 'package:flutter_test/flutter_test.dart';
import 'package:mumo_mobile/features/Operations/data/services/sms_parser.dart';
 
void main() {
  group('SmsParser Tests', () {
    test('MTN Deposit SMS should be parsed correctly', () {
      const sender = 'MTN_Money';
      const body = 'Dépôt 5000 F a JANE DOE (22997000000) réussi. ID: 67890';
      
      final result = SmsParser.parse(sender, body);
      
      expect(result, isNotNull);
      expect(result!.amount, '5000');
      expect(result.number, '22997000000');
      expect(result.transactionId, '67890');
      expect(result.operator, 'MTN');
      expect(result.operationType, 'depot');
    });
 
    test('Moov Deposit SMS should be parsed correctly', () {
      const sender = 'MoovMoney';
      const body = 'Vous avez envoyé 10 000 FCFA a l\'abonne JOHN SMITH 22966000000 le 08/06/2026';
      
      final result = SmsParser.parse(sender, body);
      
      expect(result, isNotNull);
      expect(result!.amount, '10000');
      expect(result.fullname, 'JOHN SMITH');
      expect(result.number, '22966000000');
      expect(result.operator, 'Moov');
      expect(result.operationType, 'transfert');
    });
 
    test('Celtiis Send SMS should be parsed correctly', () {
      const sender = 'Celtiis Cash';
      const body = 'Vous avez envoyé 2.500 F a 55000000 - ALICE DOE le 08/06/2026. REF: TXN123';
      
      final result = SmsParser.parse(sender, body);
      
      expect(result, isNotNull);
      expect(result!.amount, '2500');
      expect(result.number, '55000000');
      expect(result.transactionId, 'TXN123');
      expect(result.operator, 'Celtiis');
      expect(result.operationType, 'transfert');
    });
 
    test('Celtiis Withdraw SMS should be parsed correctly', () {
      const sender = 'Celtiis Cash';
      const body = 'Client a retiré un montant de 15,000 F chez AGENT MUMO 22944000000. REF: REF456';
      
      final result = SmsParser.parse(sender, body);
      
      expect(result, isNotNull);
      expect(result!.amount, '15000');
      expect(result.transactionId, 'REF456');
      expect(result.operator, 'Celtiis');
      expect(result.operationType, 'retrait');
    });

    test('Generic MTN transfer SMS without transaction id should be captured', () {
      const sender = 'MTN_Money';
      const body =
          'Forfait internet active pour 0166410148. Solde disponible: 102875 FCFA. OK';

      final result = SmsParser.parse(sender, body);

      expect(result, isNotNull);
      expect(result!.operationType, 'transfert');
      expect(result.number, '0166410148');
      expect(result.transactionId, isNull);
    });

    test('Generic Moov transfer SMS with amount and no id should be captured', () {
      const sender = 'MoovMoney';
      const body = 'Recharge envoyee de 500 FCFA vers 0166410148 avec succes.';

      final result = SmsParser.parse(sender, body);

      expect(result, isNotNull);
      expect(result!.operationType, 'transfert');
      expect(result.amount, '500');
      expect(result.number, '0166410148');
      expect(result.transactionId, isNull);
    });
  });
}
