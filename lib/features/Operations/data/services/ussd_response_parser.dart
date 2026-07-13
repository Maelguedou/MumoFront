enum UssdResponseStatus { confirmed, pending, failed, unknown }

class UssdResponseParser {
  static const _failureKeywords = [
    'insuffisant',
    'echoue',
    'echec',
    'erreur',
    'annule',
    'incorrect',
    'invalide',
    'indisponible',
    'impossible',
    'failed',
    'failure',
    'error',
  ];

  static const _pendingKeywords = [
    'traitement',
    'en cours',
    'patientez',
    'patienter',
    'paiement recu',
    'paiement reçu',
    'montant',
    'forfait',
    'solde',
    'vous recevrez',
    'sms',
    'pending',
    'processing',
  ];

  static const _confirmationWithoutReferenceKeywords = [
    'paiement recu',
    'paiement reçu',
    'envoye',
    'envoyé',
    'effectue',
    'effectué',
    'reussi',
    'réussi',
    'succes',
    'succès',
    'valide',
    'validé',
    'active',
    'activé',
    'forfait',
    'souscription',
    'achat',
    'transfert',
    'recharge',
  ];

  static UssdResponseStatus parse(
    String? response, {
    bool requireTransactionId = true,
  }) {
    final normalized = _normalize(response);
    if (normalized.isEmpty) return UssdResponseStatus.unknown;

    if (_containsAny(normalized, _failureKeywords)) {
      return UssdResponseStatus.failed;
    }

    if (extractTransactionId(response) != null) {
      return UssdResponseStatus.confirmed;
    }

    if (!requireTransactionId &&
        _containsAny(normalized, _confirmationWithoutReferenceKeywords)) {
      return UssdResponseStatus.confirmed;
    }

    if (_containsAny(normalized, _pendingKeywords)) {
      return UssdResponseStatus.pending;
    }

    return UssdResponseStatus.unknown;
  }

  static String? extractTransactionId(String? response) {
    final value = response?.trim();
    if (value == null || value.isEmpty) return null;

    final patterns = [
      RegExp(
        r'(?:\bID\b|\bREF\b|Réf)\s*(?:transaction|trans|txn)?\s*[:#\-]?\s*([A-Z0-9][A-Z0-9._\/-]*)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:transaction|trans|txn)\s*(?:id|ref|réf)?\s*[:#\-]?\s*([A-Z0-9][A-Z0-9._\/-]*)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(value);
      final transactionId = _cleanTransactionId(match?.group(1));
      if (transactionId != null && transactionId.isNotEmpty) {
        return transactionId;
      }
    }

    return null;
  }

  static bool shouldConfirmDirect(
    String? response, {
    bool requireTransactionId = true,
  }) {
    return parse(
          response,
          requireTransactionId: requireTransactionId,
        ) ==
        UssdResponseStatus.confirmed;
  }

  static String? _cleanTransactionId(String? value) {
    return value?.trim().replaceAll(RegExp(r'[.,;:]+$'), '');
  }

  static bool _containsAny(String value, List<String> keywords) {
    return keywords.any(value.contains);
  }

  static String _normalize(String? value) {
    return (value ?? '')
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('û', 'u')
        .replaceAll('ù', 'u');
  }
}
