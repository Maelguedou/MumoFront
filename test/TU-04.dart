import 'package:flutter_test/flutter_test.dart';
import 'package:mumo_mobile/features/Operations/data/services/sms_parser.dart';

void main() {
  group('TU-04 — Traitement des SMS anormaux, dupliqués ou non corrélés', () {
    test('SMS inconnu: un message promotionnel ne doit pas être reconnu', () {
      final result = SmsParser.parse(
        'MTN Promo',
        'Promo MTN: achetez un forfait internet et gagnez 100% de bonus aujourd’hui.',
      );

      expect(result, isNull);
    });

    test('SMS malformé: aucune valeur indispensable ne doit être inventée', () {
      final result = SmsParser.parse(
        'MTN MoMo',
        'Depot effectue avec succes. Merci pour votre fidelite.',
      );

      expect(result, isNull);
    });

    test(
      'Transfert réel sans numéro: le SMS reste exploitable sans inventer de numéro',
      () {
        final result = SmsParser.parse(
          'MTN MoMo',
          'Paiement 100F a SELL 2026-07-05 15:12:54 Frais:0F Solde:75425F ID:12403038428 Ref:ConfigurableMsg',
        );

        expect(result, isNotNull);
        expect(result!.operationType, 'transfert');
        expect(result.amount, '100');
        expect(result.number, isNull);
        expect(result.operator, 'MTN');
        expect(result.transactionId, '12403038428');
      },
    );

    test('SMS d’échec opérateur: il ne doit pas être traité comme un succès', () {
      final result = SmsParser.parse(
        'Moov Money',
        'Votre opération de transfert de 1000F a échoué. Solde insuffisant. Ref:778899.',
      );

      expect(result, isNull);
    });

    test('SMS d’échec avec identifiant: il reste rejeté malgré la référence', () {
      final result = SmsParser.parse(
        'MTN MoMo',
        'Echec retrait 2000F a SOFIYATOU MOUMOUNI (2290167325058). Solde insuffisant. ID:12447811658',
      );

      expect(result, isNull);
    });

    test('Rejeu du même SMS: le parsing reste déterministe', () {
      const sender = 'MTN MoMo';
      const body =
          'Paiement 100F a SELL 2026-07-05 15:12:54 Frais:0F Solde:75425F ID:12403038428 Ref:ConfigurableMsg';

      final first = SmsParser.parse(sender, body);
      final second = SmsParser.parse(sender, body);

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(second!.operationType, first!.operationType);
      expect(second.amount, first.amount);
      expect(second.number, first.number);
      expect(second.operator, first.operator);
      expect(second.transactionId, first.transactionId);
    });
  });
}
