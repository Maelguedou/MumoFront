import 'package:flutter_test/flutter_test.dart';
import 'package:mumo_mobile/features/Operations/data/services/ussd_response_parser.dart';

void main() {
  group('UssdResponseParser', () {
    test('balance/payment message without transaction id stays pending', () {
      const response =
          'Paiement recu pour 5000 FCFA. sur votre compte ,Solde disponible:  102875 FCFA. OK';

      expect(UssdResponseParser.parse(response), UssdResponseStatus.pending);
      expect(UssdResponseParser.extractTransactionId(response), isNull);
      expect(UssdResponseParser.shouldConfirmDirect(response), isFalse);
    });

    test('transfer-like success message can be confirmed without transaction id', () {
      const response =
          'Paiement recu pour 5000 FCFA. sur votre compte ,Solde disponible: 102875 FCFA. OK';

      expect(
        UssdResponseParser.parse(response, requireTransactionId: false),
        UssdResponseStatus.confirmed,
      );
      expect(
        UssdResponseParser.shouldConfirmDirect(
          response,
          requireTransactionId: false,
        ),
        isTrue,
      );
    });

    test('message with ID is confirmed and transaction id is extracted', () {
      const response =
          'Paiement recu pour 5000 FCFA. ID: ABC12345. Solde disponible: 102875 FCFA.';

      expect(UssdResponseParser.parse(response), UssdResponseStatus.confirmed);
      expect(UssdResponseParser.extractTransactionId(response), 'ABC12345');
      expect(UssdResponseParser.shouldConfirmDirect(response), isTrue);
    });

    test('message with REF is confirmed and reference is extracted', () {
      const response = 'Operation effectuee. Ref: TXN-98765. Merci';

      expect(UssdResponseParser.parse(response), UssdResponseStatus.confirmed);
      expect(UssdResponseParser.extractTransactionId(response), 'TXN-98765');
    });

    test('failure still wins even if message contains solde', () {
      const response = 'Solde insuffisant pour effectuer cette operation.';

      expect(UssdResponseParser.parse(response), UssdResponseStatus.failed);
      expect(UssdResponseParser.shouldConfirmDirect(response), isFalse);
    });
  });
}
