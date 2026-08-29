class SmsParsedData {
  final String? amount;
  final String? fullname;
  final String? number;
  final String? transactionId;
  final String operator;
  final String operationType;

  SmsParsedData({
    this.amount,
    this.fullname,
    this.number,
    this.transactionId,
    required this.operator,
    required this.operationType,
  });

  @override
  String toString() {
    return 'SmsParsedData(amount: $amount, number: $number, txId: $transactionId, op: $operator, type: $operationType)';
  }
}

class SmsParser {
  /// Analyse le corps d'un SMS et retourne les données si elles correspondent à un pattern connu.
  static SmsParsedData? parse(String sender, String body) {
    final senderUpper = sender.toUpperCase();
    final normalizedBody = _normalize(body);

    if (_containsFailureMarker(normalizedBody)) {
      return null;
    }

    if (senderUpper.contains('MTN')) {
      return _parseMtn(body);
    } else if (senderUpper.contains('MOOV')) {
      return _parseMoov(body);
    } else if (senderUpper.contains('CELTIIS')) {
      return _parseCeltiis(body);
    }

    return null;
  }

  static SmsParsedData? _parseMtn(String body) {
    final cleanBody = body.replaceAll(RegExp(r'\s+'), ' ');

    // Exemple:
    // "Depot 1500F a NOM (2290166627695) ... Ref:1 Solde:73425F ID:12403143013"
    final cashInOutRegEx = RegExp(
      r'\b(d[eé]p[oô]t|depot|retrait)\s+([\d\s.,]+)\s*F\s+a\s+(.+?)\s*\((229\d{8,13})\).*?\bID\s*:\s*([A-Z0-9._\/-]+)',
      caseSensitive: false,
    );
    final match = cashInOutRegEx.firstMatch(cleanBody);

    if (match != null) {
      return SmsParsedData(
        amount: _cleanAmount(match.group(2)!),
        fullname: match.group(3)!.trim(),
        number: match.group(4)!.trim(),
        transactionId: match.group(5),
        operator: 'MTN',
        operationType: _operationTypeFromLabel(match.group(1)!),
      );
    }

    // Exemple reel transfert/service:
    // "Paiement 100F a SELL ... Frais:0F Solde:75425F ID:12403038428 Ref:ConfigurableMsg"
    final paymentRegEx = RegExp(
      r'\bpaiement\s+([\d\s.,]+)\s*F\s+a\s+(.+?)\s+\d{4}-\d{2}-\d{2}.*?\bID\s*:\s*([A-Z0-9._\/-]+)',
      caseSensitive: false,
    );
    final paymentMatch = paymentRegEx.firstMatch(cleanBody);

    if (paymentMatch != null) {
      return SmsParsedData(
        amount: _cleanAmount(paymentMatch.group(1)!),
        fullname: paymentMatch.group(2)!.trim(),
        transactionId: paymentMatch.group(3),
        operator: 'MTN',
        operationType: 'transfert',
      );
    }

    return _parseGenericTransfer('MTN', cleanBody);
  }

  static SmsParsedData? _parseMoov(String body) {
    final cleanBody = body.replaceAll(RegExp(r'\s+'), ' ');

    //  PATTERN DÉPÔT
    final depRegEx = RegExp(
      r"envoy[eé]\s+([\d\s]+)\s*FCFA\s+a\s+l[''`]abonne\s+(.+?)\s+(\d{8,13})"
      r".*?Ref\s*:\s*(\d+)",
      caseSensitive: false,
    );
    var match = depRegEx.firstMatch(cleanBody);
    if (match != null) {
      return SmsParsedData(
        amount: _cleanMoovAmount(match.group(1)!),
        fullname: match.group(2)!.trim(),
        number: match.group(3)!,
        transactionId: match.group(4),
        operator: 'Moov',
        operationType: 'depot',
      );
    }

    // PATTERN RETRAIT
    final retRegEx = RegExp(
      r'([\d\s]+)\s*FCFA\s+re[cç]u\s+de\s+(.+?)\s+(\d{8,13})'
      r'.*?Ref\s*:\s*(\d+)',
      caseSensitive: false,
    );
    match = retRegEx.firstMatch(cleanBody);
    if (match != null) {
      return SmsParsedData(
        amount: _cleanMoovAmount(match.group(1)!),
        fullname: match.group(2)!.trim(),
        number: match.group(3)!,
        transactionId: match.group(4),
        operator: 'Moov',
        operationType: 'retrait',
      );
    }

    return _parseGenericTransfer('Moov', body);
  }

  static SmsParsedData? _parseCeltiis(String body) {
    // Nettoyage préalable du texte (enlever les doubles espaces fréquents chez Celtiis)
    final cleanBody = body.replaceAll(RegExp(r'\s+'), ' ');

    // ESSAI PATTERN DÉPÔT
    final depRegEx = RegExp(
      r'envoyé\s+([\d.,]+)\s*F\s+a\s+(\d+)\s*-\s*(.+?)\s+le\s+.+?REF:\s*(\w+)',
      caseSensitive: false,
    );
    var match = depRegEx.firstMatch(cleanBody);

    if (match != null) {
      return SmsParsedData(
        amount: _cleanCeltiisAmount(match.group(1)!),
        number: match.group(2)!,
        fullname: match.group(3)!.trim(),
        transactionId: match.group(4),
        operator: 'Celtiis',
        operationType: 'depot',
      );
    }

    // ESSAI PATTERN RETRAIT (si le dépôt n'a rien donné)
    final retRegEx = RegExp(
      r'retir[eé]\s+un\s+montant\s+de\s+([\d.,]+)\s*F\s+chez\s+(.+?)\s+(\d{8,13}).+?REF:\s*(\w+)',
      caseSensitive: false,
    );
    match = retRegEx.firstMatch(cleanBody);

    if (match != null) {
      return SmsParsedData(
        amount: _cleanCeltiisAmount(match.group(1)!),
        fullname: match.group(2)!.trim(),
        number: match.group(3)!,
        transactionId: match.group(4),
        operator: 'Celtiis',
        operationType: 'retrait',
      );
    }

    return _parseGenericTransfer('Celtiis', body);
  }

  static SmsParsedData? _parseGenericTransfer(String operator, String body) {
    final cleanBody = body.replaceAll(RegExp(r'\s+'), ' ');
    final normalized = _normalize(cleanBody);
    final amount = _extractAmount(cleanBody);

    if (!_looksLikeSuccessfulTransfer(normalized) || amount == null) {
      return null;
    }

    return SmsParsedData(
      amount: amount,
      number: _extractPhoneNumber(cleanBody),
      transactionId: _extractTransactionId(cleanBody),
      operator: operator,
      operationType: 'transfert',
    );
  }

  static bool _looksLikeSuccessfulTransfer(String normalized) {
    final hasSuccess = [
      'envoye',
      'envoyee',
      'transfert',
      'paiement',
      'paiement recu',
      'recharge',
      'forfait',
      'pass',
      'active',
      'activation',
      'souscription',
      'achat',
      'reussi',
      'succes',
      'effectue',
      'valide',
    ].any(normalized.contains);

    final hasFailure = _containsFailureMarker(normalized);

    return hasSuccess && !hasFailure;
  }

  static bool _containsFailureMarker(String normalized) {
    return [
      'insuffisant',
      'echoue',
      'echec',
      'erreur',
      'annule',
      'invalide',
      'incorrect',
      'impossible',
    ].any(normalized.contains);
  }

  static String? _extractPhoneNumber(String body) {
    final patterns = [
      RegExp(r'\b(?:\+?229)?01\d{8,15}\b'),
      RegExp(r'\b229\d{8,13}\b'),
      RegExp(r'\b\d{8,13}\b'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) return match.group(0)!.replaceAll('+', '');
    }

    return null;
  }

  static String? _extractAmount(String body) {
    final patterns = [
      RegExp(
        r'\bmontant\s*[:=]?\s*([\d\s.,]+)\s*F(?:CFA)?\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(?:forfait|pass|airtime|internet|appel)(?:\s+\w+){0,4}\s+([\d\s.,]+)\s*F(?:CFA)?\b',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:montant|pour|de|envoy[eé]|re[cç]u|transfert)\s+([\d\s.,]+)\s*F(?:CFA)?',
        caseSensitive: false,
      ),
      RegExp(r'\b([\d\s.,]+)\s*F(?:CFA)?\b', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final amount = _cleanAmount(match.group(1)!);
        if (amount.isNotEmpty) return amount;
      }
    }

    return null;
  }

  static String? _extractTransactionId(String body) {
    final patterns = [
      RegExp(
        r'\bREF\s+ID\s*[:#\-]?\s*([A-Z0-9][A-Z0-9._\/-]*)',
        caseSensitive: false,
      ),
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
      final match = pattern.firstMatch(body);
      final value = match?.group(1)?.trim().replaceAll(RegExp(r'[.,;:]+$'), '');
      if (value != null && value.isNotEmpty) return value;
    }

    return null;
  }

  static String _cleanCeltiisAmount(String rawAmount) {
    return _cleanAmount(rawAmount);
  }

  static String _cleanMoovAmount(String rawAmount) {
    return _cleanAmount(rawAmount);
  }

  static String _cleanAmount(String rawAmount) {
    var value = rawAmount.trim().replaceAll(RegExp(r'\s+'), '');

    final hasComma = value.contains(',');
    final hasDot = value.contains('.');

    if (hasComma && hasDot) {
      final lastComma = value.lastIndexOf(',');
      final lastDot = value.lastIndexOf('.');
      final decimalSeparator = lastComma > lastDot ? ',' : '.';
      final decimalIndex = decimalSeparator == ',' ? lastComma : lastDot;
      final fraction = value.substring(decimalIndex + 1);

      if (fraction.length <= 2) {
        value = value.substring(0, decimalIndex);
      }

      return value.replaceAll(RegExp(r'[.,]'), '');
    }

    if (hasComma) {
      final lastComma = value.lastIndexOf(',');
      final fraction = value.substring(lastComma + 1);
      if (fraction.length <= 2) {
        value = value.substring(0, lastComma);
      }
      return value.replaceAll(',', '');
    }

    if (hasDot) {
      final lastDot = value.lastIndexOf('.');
      final fraction = value.substring(lastDot + 1);
      if (fraction.length <= 2) {
        value = value.substring(0, lastDot);
      }
      return value.replaceAll('.', '');
    }

    return value.replaceAll(RegExp(r'\D'), '');
  }

  static String _operationTypeFromLabel(String label) {
    final normalized = label
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ô', 'o');

    if (normalized.contains('depot')) return 'depot';
    if (normalized.contains('retrait')) return 'retrait';
    if (normalized.contains('transfert') || normalized.contains('envoye')) {
      return 'transfert';
    }
    return 'transfert';
  }

  static String _normalize(String value) {
    return value
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
