import 'package:dio/dio.dart';

String userFriendlyDioMessage(DioException error, {required String fallback}) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'La connexion prend trop de temps. Vérifiez votre internet puis réessayez.';
    case DioExceptionType.connectionError:
      return 'Impossible de joindre le serveur. Vérifiez votre connexion internet.';
    case DioExceptionType.cancel:
      return 'La demande a été annulée.';
    case DioExceptionType.badCertificate:
      return 'La connexion sécurisée a échoué. Réessayez plus tard.';
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      break;
  }

  final statusCode = error.response?.statusCode;
  if (statusCode == 401) {
    return 'Votre session a expiré. Reconnectez-vous pour continuer.';
  }
  if (statusCode == 403) {
    return 'Vous n’avez pas l’autorisation d’effectuer cette action.';
  }
  if (statusCode == 404) {
    return 'Les informations demandées sont introuvables pour le moment.';
  }
  if (statusCode == 422) {
    return _validationMessage(error.response?.data) ??
        'Certaines informations sont invalides. Corrigez-les puis réessayez.';
  }
  if (statusCode != null && statusCode >= 500) {
    return 'Le service rencontre un problème temporaire. Réessayez dans un instant.';
  }

  final apiMessage = _apiMessage(error.response?.data);
  if (apiMessage != null && !_looksTechnical(apiMessage)) {
    return apiMessage;
  }

  return fallback;
}

String userFriendlyUnexpectedMessage({required String fallback}) {
  return fallback;
}

String? _validationMessage(dynamic data) {
  if (data is! Map<String, dynamic>) return null;

  final errors = data['errors'];
  if (errors is Map) {
    final messages = <String>[];
    for (final value in errors.values) {
      if (value is List) {
        messages.addAll(value.map((item) => item.toString()));
      } else if (value != null) {
        messages.add(value.toString());
      }
    }
    final cleanMessages = messages
        .where((message) => message.trim().isNotEmpty)
        .where((message) => !_looksTechnical(message))
        .toList();
    if (cleanMessages.isNotEmpty) {
      return cleanMessages.join('\n');
    }
  }

  final message = _apiMessage(data);
  if (message != null && !_looksTechnical(message)) {
    return message;
  }

  return null;
}

String? _apiMessage(dynamic data) {
  if (data is! Map<String, dynamic>) return null;

  final raw = data['message'] ?? data['error'];
  if (raw is! String) return null;

  final message = raw.trim();
  return message.isEmpty ? null : message;
}

bool _looksTechnical(String message) {
  final value = message.toLowerCase();
  const markers = [
    'sqlstate',
    'queryexception',
    'dioexception',
    'exception',
    'stack trace',
    'trace:',
    'vendor/',
    'connection.php',
    'syntax error',
    'undefined',
    'nullpointer',
    'htmlspecialchars',
    'postgres',
    'mysql',
    'line ',
  ];

  return markers.any(value.contains);
}
