class OperatorMatcher {
  static int? findOperatorIdFromMaps(
    List<dynamic> operators,
    String parsedOperatorName,
  ) {
    for (final operator in operators) {
      if (operator is! Map) continue;

      final id = operator['id'];
      final name = operator['name'];
      final operatorId = _readId(id);
      if (operatorId != null &&
          name is String &&
          matches(name, parsedOperatorName)) {
        return operatorId;
      }
    }

    return null;
  }

  static bool matches(String apiName, String parsedOperatorName) {
    final apiKey = _canonical(apiName);
    final parsedKey = _canonical(parsedOperatorName);
    final aliases = _aliasesFor(parsedKey);

    return aliases.contains(apiKey) || aliases.any(apiKey.contains);
  }

  static int? _readId(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static Set<String> _aliasesFor(String parsedKey) {
    if (parsedKey.contains('mtn') || parsedKey == 'momo') {
      return {'mtn', 'mtnmobilemoney', 'mtnmomo', 'momo'};
    }

    if (parsedKey.contains('moov')) {
      return {'moov', 'moovmoney', 'moovafrica', 'moovafricamoney'};
    }

    if (parsedKey.contains('celtiis')) {
      return {'celtiis', 'celtiiscash', 'celtiismoney'};
    }

    return {parsedKey};
  }

  static String _canonical(String value) {
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
        .replaceAll('ù', 'u')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
